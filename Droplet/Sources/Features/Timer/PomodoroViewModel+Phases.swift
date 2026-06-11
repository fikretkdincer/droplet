import Foundation

extension PomodoroViewModel {
    func handleSessionComplete() {
        stopTimer()
        status = .idle
        sendSessionCompletionNotification()

        if currentMode == .work && secondsWorkedThisSession > 0 {
            secondsWorkedThisSession = 0
        }

        if settings.autoStartNextSession {
            switchToNextMode()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.startTimer()
            }
        } else {
            status = .pulsing
            syncWidgetTimerState(reload: true)
        }
    }

    func switchToNextMode() {
        let previousMode = currentMode
        let nextPhase = timerConfiguration.nextPhase(after: previousMode, completedWorkflows: completedWorkflows)
        currentMode = nextPhase.mode
        completedWorkflows = nextPhase.completedWorkflows
        handleSoundsForPhaseTransition(from: previousMode)
        resetToCurrentMode()
        syncWidgetTimerState(reload: true)
    }

    func resetToCurrentMode() {
        sessionTotalSeconds = totalSecondsForCurrentMode
        if currentMode.isBreak {
            continuousWorkSecondsForEyeRest = 0
        }
        remainingSeconds = sessionTotalSeconds
    }

    func continueToNextPhase() {
        guard status == .pulsing else { return }
        switchToNextMode()
        startTimer()
    }

    func endCurrentSession() {
        if currentMode == .infinity {
            stopTimer()
            elapsedSeconds = 0
            secondsWorkedThisSession = 0
            status = .idle
            return
        }

        stopTimer()
        sendSessionCompletionNotification()
        switchToNextMode()
        status = .idle
        syncWidgetTimerState(reload: true)
    }
}
