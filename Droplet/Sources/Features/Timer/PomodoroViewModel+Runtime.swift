import Combine
import Foundation

extension PomodoroViewModel {
    func startTimer() {
        status = .running
        syncWidgetTimerState(reload: true)
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }

        resumeSoundsForFocusIfNeeded()
    }

    func pauseTimer() {
        status = .paused
        timer?.cancel()
        timer = nil
        syncWidgetTimerState(reload: true)
        pauseSoundsForTimerPauseIfNeeded()
    }

    func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    func tick() {
        if currentMode == .infinity {
            elapsedSeconds += 1
            recordFocusedSecond()
            syncWidgetTimerState(reload: false)
            return
        }

        guard remainingSeconds > 0 else { return }

        remainingSeconds -= 1

        if currentMode == .work {
            recordFocusedSecond()
        }

        if remainingSeconds == 0 {
            handleSessionComplete()
        }

        syncWidgetTimerState(reload: false)
    }

    private func recordFocusedSecond() {
        secondsWorkedThisSession += 1
        if secondsWorkedThisSession >= 60 {
            secondsWorkedThisSession = 0
            if let milestone = GoalTracker.shared.recordWorkSession(minutes: 1) {
                sendMilestoneNotification(milestone: milestone)
            }
            TaskManager.shared.recordMinuteForActiveTask()
        }

        guard settings.enable202020Rule else { return }
        continuousWorkSecondsForEyeRest += 1
        if continuousWorkSecondsForEyeRest >= 1_200 {
            continuousWorkSecondsForEyeRest = 0
            NotificationCenter.default.post(name: Notification.Name("TriggerEyeRestOverlay"), object: nil)
        }
    }
}
