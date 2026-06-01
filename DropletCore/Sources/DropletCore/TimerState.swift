import Foundation

/// Timer mode representing the current phase.
public enum TimerMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case work = "Work"
    case shortBreak = "Break"
    case longBreak = "Long Break"
    case infinity = "Infinity"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .work:
            return "💧"
        case .shortBreak:
            return "🌿"
        case .longBreak:
            return "🌊"
        case .infinity:
            return "∞"
        }
    }

    public var tracksFocusTime: Bool {
        self == .work || self == .infinity
    }

    public var isBreak: Bool {
        self == .shortBreak || self == .longBreak
    }
}

/// Timer running status.
public enum TimerStatus: String, CaseIterable, Codable, Sendable {
    case idle
    case running
    case paused
    case pulsing
}

/// The next mode plus workflow counter after a timer phase changes.
public struct TimerPhase: Codable, Equatable, Sendable {
    public let mode: TimerMode
    public let completedWorkflows: Int

    public init(mode: TimerMode, completedWorkflows: Int) {
        self.mode = mode
        self.completedWorkflows = max(0, completedWorkflows)
    }
}

/// Pure timer configuration shared by every Droplet platform.
public struct TimerConfiguration: Codable, Equatable, Sendable {
    public var workDurationMinutes: Int
    public var shortBreakDurationMinutes: Int
    public var longBreakDurationMinutes: Int
    public var workflowsBeforeLongBreak: Int

    public init(
        workDurationMinutes: Int,
        shortBreakDurationMinutes: Int,
        longBreakDurationMinutes: Int,
        workflowsBeforeLongBreak: Int
    ) {
        self.workDurationMinutes = max(0, workDurationMinutes)
        self.shortBreakDurationMinutes = max(0, shortBreakDurationMinutes)
        self.longBreakDurationMinutes = max(0, longBreakDurationMinutes)
        self.workflowsBeforeLongBreak = max(1, workflowsBeforeLongBreak)
    }

    public func totalSeconds(for mode: TimerMode) -> Int {
        switch mode {
        case .work:
            return workDurationMinutes * 60
        case .shortBreak:
            return shortBreakDurationMinutes * 60
        case .longBreak:
            return longBreakDurationMinutes * 60
        case .infinity:
            return 0
        }
    }

    public func nextPhase(after mode: TimerMode, completedWorkflows: Int) -> TimerPhase {
        switch mode {
        case .work:
            let nextCompletedWorkflows = completedWorkflows + 1
            if nextCompletedWorkflows >= workflowsBeforeLongBreak {
                return TimerPhase(mode: .longBreak, completedWorkflows: 0)
            }
            return TimerPhase(mode: .shortBreak, completedWorkflows: nextCompletedWorkflows)
        case .shortBreak, .longBreak:
            return TimerPhase(mode: .work, completedWorkflows: completedWorkflows)
        case .infinity:
            return TimerPhase(mode: .infinity, completedWorkflows: completedWorkflows)
        }
    }
}
