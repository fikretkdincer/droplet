import Foundation
import Combine
import SwiftUI

/// Main view model handling all Pomodoro timer logic
class PomodoroViewModel: ObservableObject {
    @Published var currentMode: TimerMode = .work
    @Published var status: TimerStatus = .idle
    @Published var remainingSeconds: Int = 25 * 60
    @Published var completedWorkflows: Int = 0
    @Published var elapsedSeconds: Int = 0

    /// Total seconds for the current session (set when timer starts, doesn't change mid-session)
    private var sessionTotalSeconds: Int = 25 * 60

    private var timer: AnyCancellable?
    private var settings = SettingsManager.shared
    private var notifications = NotificationManager.shared
    private var settingsObserver: AnyCancellable?

    /// Tracks seconds worked in current session for minute-by-minute goal tracking
    private var secondsWorkedThisSession: Int = 0
    
    /// Tracks continuous active work time for the 20-20-20 rule
    private var continuousWorkSecondsForEyeRest: Int = 0

    init() {
        if settings.infinityMode {
            currentMode = .infinity
        }
        resetToCurrentMode()

        // Observe infinity mode toggle
        settingsObserver = settings.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if self.settings.infinityMode && self.currentMode != .infinity {
                    self.enterInfinityMode()
                } else if !self.settings.infinityMode && self.currentMode == .infinity {
                    self.exitInfinityMode()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var formattedTime: String {
        if currentMode == .infinity {
            let hours = elapsedSeconds / 3600
            let minutes = (elapsedSeconds % 3600) / 60
            let seconds = elapsedSeconds % 60
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            }
            return String(format: "%02d:%02d", minutes, seconds)
        }
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var currentAccentColor: Color {
        switch currentMode {
        case .work, .infinity:
            return settings.selectedTheme.workAccent
        case .shortBreak, .longBreak:
            return settings.selectedTheme.breakAccent
        }
    }

    /// Check if currently on a break (short or long)
    var isOnBreak: Bool {
        currentMode == .shortBreak || currentMode == .longBreak
    }
    
    /// Skip the current break and immediately return to work mode
    func skipBreak() {
        guard isOnBreak else { return }
        stopTimer()
        currentMode = .work
        resetToCurrentMode()
        status = .idle
        
        // Send motivational notification
        notifications.sendCustomNotification(
            title: "Break Skipped 💪",
            body: "Let's get back to work! Stay focused."
        )
    }
    
    var progressRatio: Double {
        let total = totalSecondsForCurrentMode
        guard total > 0 else { return 0 }
        
        // If remaining is greater than total (e.g. settings reduced mid-session),
        // show empty bar instead of negative/overflow
        if remainingSeconds > total {
            return 0
        }
        
        let ratio = Double(total - remainingSeconds) / Double(total)
        return min(max(ratio, 0), 1.0)
    }
    

    
    var totalSecondsForCurrentMode: Int {
        switch currentMode {
        case .work:
            return settings.workDuration * 60
        case .shortBreak:
            return settings.shortBreakDuration * 60
        case .longBreak:
            return settings.longBreakDuration * 60
        case .infinity:
            return 0
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
        if currentMode == .infinity {
            elapsedSeconds = 0
        }
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
        if settings.pauseSoundsOnTimerPause && (currentMode == .work || currentMode == .infinity) {
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
        // Infinity mode: count up
        if currentMode == .infinity {
            elapsedSeconds += 1
            secondsWorkedThisSession += 1
            if secondsWorkedThisSession >= 60 {
                secondsWorkedThisSession = 0
                if let milestone = GoalTracker.shared.recordWorkSession(minutes: 1) {
                    sendMilestoneNotification(milestone: milestone)
                }
                TaskManager.shared.recordMinuteForActiveTask()
            }
            
            if settings.enable202020Rule {
                continuousWorkSecondsForEyeRest += 1
                if continuousWorkSecondsForEyeRest >= 1200 {
                    continuousWorkSecondsForEyeRest = 0
                    NotificationCenter.default.post(name: Notification.Name("TriggerEyeRestOverlay"), object: nil)
                }
            }
            return
        }

        guard remainingSeconds > 0 else { return }

        remainingSeconds -= 1

        // Track goal progress every minute during work sessions
        if currentMode == .work {
            secondsWorkedThisSession += 1
            if secondsWorkedThisSession >= 60 {
                secondsWorkedThisSession = 0
                if let milestone = GoalTracker.shared.recordWorkSession(minutes: 1) {
                    sendMilestoneNotification(milestone: milestone)
                }
                TaskManager.shared.recordMinuteForActiveTask()
            }
            
            if settings.enable202020Rule {
                continuousWorkSecondsForEyeRest += 1
                if continuousWorkSecondsForEyeRest >= 1200 {
                    continuousWorkSecondsForEyeRest = 0
                    NotificationCenter.default.post(name: Notification.Name("TriggerEyeRestOverlay"), object: nil)
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
        case .infinity:
            break
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
        case .infinity:
            break
        }
        resetToCurrentMode()
    }
    
    private func resetToCurrentMode() {
        sessionTotalSeconds = totalSecondsForCurrentMode
        
        // Reset eye rest counter on break start
        if currentMode == .shortBreak || currentMode == .longBreak {
            continuousWorkSecondsForEyeRest = 0
        }
        
        remainingSeconds = sessionTotalSeconds
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
        if currentMode == .infinity {
            stopTimer()
            elapsedSeconds = 0
            secondsWorkedThisSession = 0
            status = .idle
            return
        }
        stopTimer()
        sendNotification()
        switchToNextMode()
        status = .idle
    }

    // MARK: - Infinity Mode

    func enterInfinityMode() {
        stopTimer()
        currentMode = .infinity
        elapsedSeconds = 0
        remainingSeconds = 0
        completedWorkflows = 0
        secondsWorkedThisSession = 0
        status = .idle
    }

    func exitInfinityMode() {
        stopTimer()
        currentMode = .work
        elapsedSeconds = 0
        secondsWorkedThisSession = 0
        status = .idle
        resetToCurrentMode()
    }
}
