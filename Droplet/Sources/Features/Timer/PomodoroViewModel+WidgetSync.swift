extension PomodoroViewModel {
    func syncWidgetTimerState(reload: Bool) {
        DropletWidgetStore.shared.syncTimer(
            modeRaw: currentMode.rawValue,
            statusRaw: widgetStatusRaw,
            remainingSeconds: currentMode == .infinity ? elapsedSeconds : remainingSeconds,
            totalSeconds: sessionTotalSeconds,
            progress: progressRatio,
            reload: reload
        )
    }

    var widgetStatusRaw: String {
        status.rawValue
    }
}
