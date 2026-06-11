extension PomodoroViewModel {
    func toggleStartPause() {
        switch status {
        case .idle, .paused, .pulsing:
            startTimer()
        case .running:
            pauseTimer()
        }
    }

    func startFromWidget() {
        switch status {
        case .idle, .paused:
            startTimer()
        case .pulsing:
            continueToNextPhase()
        case .running:
            break
        }
    }

    func toggleFromWidget() {
        switch status {
        case .idle, .paused:
            startTimer()
        case .pulsing:
            continueToNextPhase()
        case .running:
            pauseTimer()
        }
    }

    func resetCurrentMode() {
        stopTimer()
        if currentMode == .infinity {
            elapsedSeconds = 0
        }
        resetToCurrentMode()
        status = .idle
        secondsWorkedThisSession = 0
        syncWidgetTimerState(reload: true)
        stopSoundsOnResetIfNeeded()
    }

    func skipBreak() {
        guard isOnBreak else { return }
        stopTimer()
        currentMode = .work
        resetToCurrentMode()
        status = .idle
        syncWidgetTimerState(reload: true)

        notifications.sendCustomNotification(
            title: "Break Skipped 💪",
            body: "Let's get back to work! Stay focused."
        )
    }
}
