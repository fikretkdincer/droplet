import Combine
import Foundation
import SwiftUI

final class PomodoroViewModel: ObservableObject {
    @Published var currentMode: TimerMode = .work
    @Published var status: TimerStatus = .idle
    @Published var remainingSeconds = 25 * 60
    @Published var completedWorkflows = 0
    @Published var elapsedSeconds = 0

    var sessionTotalSeconds = 25 * 60
    var timer: AnyCancellable?
    let settings = SettingsManager.shared
    let notifications = NotificationManager.shared
    var settingsObserver: AnyCancellable?
    var secondsWorkedThisSession = 0
    var continuousWorkSecondsForEyeRest = 0

    init() {
        if settings.infinityMode {
            currentMode = .infinity
        }
        resetToCurrentMode()
        syncWidgetTimerState(reload: true)

        settingsObserver = settings.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if self.settings.infinityMode && self.currentMode != .infinity {
                    self.enterInfinityMode()
                } else if !self.settings.infinityMode && self.currentMode == .infinity {
                    self.exitInfinityMode()
                }
            }
        }
    }

    var formattedTime: String {
        if currentMode == .infinity {
            let hours = elapsedSeconds / 3_600
            let minutes = (elapsedSeconds % 3_600) / 60
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

    var isOnBreak: Bool {
        currentMode.isBreak
    }

    var progressRatio: Double {
        let total = totalSecondsForCurrentMode
        guard total > 0, remainingSeconds <= total else { return 0 }
        let ratio = Double(total - remainingSeconds) / Double(total)
        return min(max(ratio, 0), 1)
    }

    var totalSecondsForCurrentMode: Int {
        timerConfiguration.totalSeconds(for: currentMode)
    }

    var timerConfiguration: TimerConfiguration {
        TimerConfiguration(
            workDurationMinutes: settings.workDuration,
            shortBreakDurationMinutes: settings.shortBreakDuration,
            longBreakDurationMinutes: settings.longBreakDuration,
            workflowsBeforeLongBreak: settings.workflowCount
        )
    }
}
