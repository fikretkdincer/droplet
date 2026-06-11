extension PomodoroViewModel {
    func enterInfinityMode() {
        stopTimer()
        currentMode = .infinity
        elapsedSeconds = 0
        remainingSeconds = 0
        completedWorkflows = 0
        secondsWorkedThisSession = 0
        status = .idle
        syncWidgetTimerState(reload: true)
    }

    func exitInfinityMode() {
        stopTimer()
        currentMode = .work
        elapsedSeconds = 0
        secondsWorkedThisSession = 0
        status = .idle
        resetToCurrentMode()
        syncWidgetTimerState(reload: true)
    }
}
