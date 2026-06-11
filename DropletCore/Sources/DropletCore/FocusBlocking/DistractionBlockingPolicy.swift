public enum DistractionBlockingShieldContext: String, Codable, Equatable, Sendable {
    case focus
    case pausedFocus
    case breakComplete
}

public enum DistractionBlockingPolicy {
    public static func shieldContext(
        isEnabled: Bool,
        flowIsActive: Bool,
        mode: TimerMode,
        status: TimerStatus
    ) -> DistractionBlockingShieldContext? {
        guard isEnabled, flowIsActive else { return nil }

        switch mode {
        case .shortBreak, .longBreak:
            return nil
        case .work, .infinity:
            switch status {
            case .running:
                return .focus
            case .paused:
                return .pausedFocus
            case .idle, .pulsing:
                return .breakComplete
            }
        }
    }
}
