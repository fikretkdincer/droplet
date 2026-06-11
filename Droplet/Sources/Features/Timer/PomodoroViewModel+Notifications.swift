extension PomodoroViewModel {
    func sendMilestoneNotification(milestone: Int) {
        guard let message = GoalTracker.milestoneMessages[milestone] else { return }
        notifications.sendCustomNotification(title: message.title, body: message.body)
    }

    func sendSessionCompletionNotification() {
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
}
