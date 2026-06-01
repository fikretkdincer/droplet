public struct TimerWorkflowIndicator: Equatable, Sendable {
    public let totalDots: Int
    public let filledDots: Int

    public init(
        mode: TimerMode,
        completedWorkflows: Int,
        workflowsBeforeLongBreak: Int
    ) {
        guard mode != .infinity else {
            totalDots = 0
            filledDots = 0
            return
        }

        let total = max(1, workflowsBeforeLongBreak)
        totalDots = total

        switch mode {
        case .work:
            filledDots = min(max(0, completedWorkflows) + 1, total)
        case .shortBreak:
            filledDots = min(max(0, completedWorkflows), total)
        case .longBreak:
            filledDots = total
        case .infinity:
            filledDots = 0
        }
    }
}
