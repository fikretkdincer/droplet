import Foundation
import Combine
import SwiftUI

/// Main view model handling all Pomodoro timer logic
class PomodoroViewModel: ObservableObject {
    @Published var currentMode: TimerMode = .work
    @Published var status: TimerStatus = .idle
    @Published var remainingSeconds: Int = 25 * 60
    @Published var completedWorkflows: Int = 0
    
    private var timer: AnyCancellable?
    private var settings = SettingsManager.shared
    private var notifications = NotificationManager.shared
    
    /// Tracks seconds worked in current session for minute-by-minute goal tracking
    private var secondsWorkedThisSession: Int = 0
    
    init() {
        resetToCurrentMode()
    }
    
    // MARK: - Computed Properties
    
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var currentAccentColor: Color {
        switch currentMode {
        case .work:
            return settings.selectedTheme.workAccent
        case .shortBreak, .longBreak:
            return settings.selectedTheme.breakAccent
        }
    }
    
    var progressRatio: Double {
        let total = totalSecondsForCurrentMode
        guard total > 0 else { return 0 }
        return Double(totalSecondsForCurrentMode - remainingSeconds) / Double(total)
    }
    
    private var totalSecondsForCurrentMode: Int {
        switch currentMode {
        case .work:
            return settings.workDuration * 60
        case .shortBreak:
            return settings.shortBreakDuration * 60
        case .longBreak:
            return settings.longBreakDuration * 60
        }
    }
    
    // MARK: - Public Actions
    
    /// Single click: Start/Pause
    func toggleStartPause() {
        switch status {
        case .idle, .paused, .pulsing:
            startTimer()
        case .running:
            pauseTimer()
        }
    }
    
    /// Double click: Reset current mode
    func resetCurrentMode() {
        stopTimer()
        resetToCurrentMode()
        status = .idle
        secondsWorkedThisSession = 0
        
        // Stop ambient sounds on reset (like pausing)
        if settings.pauseSoundsOnTimerPause {
            SoundManager.shared.stop()
        }
    }
    
    // MARK: - Timer Control
    
    private func startTimer() {
        status = .running
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
        
        // Resume sounds if they were paused
        if settings.pauseSoundsOnTimerPause && currentMode == .work {
            if SoundManager.shared.currentSound != .none || SoundManager.shared.currentCustomSound != nil {
                if !SoundManager.shared.isPlaying {
                    SoundManager.shared.toggle()
                }
            }
        }
    }
    
    private func pauseTimer() {
        status = .paused
        timer?.cancel()
        timer = nil
        
        // Pause sounds when timer is paused
        if settings.pauseSoundsOnTimerPause && SoundManager.shared.isPlaying {
            SoundManager.shared.stop()
        }
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func tick() {
        guard remainingSeconds > 0 else { return }
        
        remainingSeconds -= 1
        
        // Track goal progress every minute during work sessions
        if currentMode == .work {
            secondsWorkedThisSession += 1
            if secondsWorkedThisSession >= 60 {
                secondsWorkedThisSession = 0
                // Record 1 minute of work and check for milestones
                if let milestone = GoalTracker.shared.recordWorkSession(minutes: 1) {
                    sendMilestoneNotification(milestone: milestone)
                }
            }
        }
        
        if remainingSeconds == 0 {
            handleSessionComplete()
        }
    }
    
    private func handleSessionComplete() {
        stopTimer()
        status = .idle
        sendNotification()
        
        // Record any remaining seconds worked (less than a minute)
        if currentMode == .work && secondsWorkedThisSession > 0 {
            // Don't record partial minutes - they'll count next session
            secondsWorkedThisSession = 0
        }
        
        if settings.autoStartNextSession {
            // Switch to next mode and auto-start
            switchToNextMode()
            // Small delay to let notification register, then start
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.startTimer()
            }
        } else {
            // Wait for user to click
            status = .pulsing
        }
    }
    
    private func sendMilestoneNotification(milestone: Int) {
        guard let message = GoalTracker.milestoneMessages[milestone] else { return }
        notifications.sendCustomNotification(title: message.title, body: message.body)
    }
    
    private func sendNotification() {
        switch currentMode {
        case .work:
            notifications.sendWorkEndNotification()
        case .shortBreak:
            notifications.sendBreakEndNotification()
        case .longBreak:
            notifications.sendLongBreakEndNotification()
        }
    }
    
    private func switchToNextMode() {
        switch currentMode {
        case .work:
            completedWorkflows += 1
            if completedWorkflows >= settings.workflowCount {
                currentMode = .longBreak
                completedWorkflows = 0
            } else {
                currentMode = .shortBreak
            }
            // Pause ambient sounds during break
            if SoundManager.shared.isPlaying {
                SoundManager.shared.stop()
            }
        case .shortBreak, .longBreak:
            currentMode = .work
            // Resume ambient sounds for work session
            if SoundManager.shared.currentSound != .none || SoundManager.shared.currentCustomSound != nil {
                SoundManager.shared.toggle()
            }
        }
        resetToCurrentMode()
    }
    
    private func resetToCurrentMode() {
        remainingSeconds = totalSecondsForCurrentMode
    }
    
    /// Called when user clicks during pulsing state to continue
    func continueToNextPhase() {
        if status == .pulsing {
            switchToNextMode()
            startTimer()
        }
    }
    
    /// End current session and move to next phase (increment workflow if work ended)
    func endCurrentSession() {
        stopTimer()
        sendNotification()  // Notify user about session end
        switchToNextMode()
        status = .idle
    }
}
