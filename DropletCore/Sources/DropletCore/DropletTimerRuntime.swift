import Foundation

public struct DropletTimerRuntime: Codable, Equatable, Sendable {
    public var mode: TimerMode
    public var status: TimerStatus
    public var remainingSeconds: Int
    public var elapsedSeconds: Int
    public var completedWorkflows: Int
    public var sessionTotalSeconds: Int

    public init(configuration: TimerConfiguration, startsInInfinityMode: Bool = false) {
        mode = startsInInfinityMode ? .infinity : .work
        status = .idle
        elapsedSeconds = 0
        completedWorkflows = 0
        sessionTotalSeconds = configuration.totalSeconds(for: mode)
        remainingSeconds = sessionTotalSeconds
    }

    public var formattedTime: String {
        if mode == .infinity {
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

    public var progressRatio: Double {
        guard mode != .infinity, sessionTotalSeconds > 0 else { return 0 }
        guard remainingSeconds <= sessionTotalSeconds else { return 0 }
        let ratio = Double(sessionTotalSeconds - remainingSeconds) / Double(sessionTotalSeconds)
        return min(max(ratio, 0), 1)
    }

    public mutating func start() {
        status = .running
    }

    public mutating func pause() {
        if status == .running {
            status = .paused
        }
    }

    public mutating func reset(configuration: TimerConfiguration) {
        status = .idle
        if mode == .infinity {
            elapsedSeconds = 0
            remainingSeconds = 0
            sessionTotalSeconds = 0
            return
        }

        sessionTotalSeconds = configuration.totalSeconds(for: mode)
        remainingSeconds = sessionTotalSeconds
    }

    public mutating func tick(configuration: TimerConfiguration, autoStartNextSession: Bool) {
        guard status == .running else { return }

        if mode == .infinity {
            elapsedSeconds += 1
            return
        }

        guard remainingSeconds > 0 else { return }
        remainingSeconds -= 1

        if remainingSeconds == 0 {
            if autoStartNextSession {
                advanceToNextPhase(configuration: configuration)
                start()
            } else {
                status = .pulsing
            }
        }
    }

    public mutating func advanceToNextPhase(configuration: TimerConfiguration) {
        let phase = configuration.nextPhase(after: mode, completedWorkflows: completedWorkflows)
        mode = phase.mode
        completedWorkflows = phase.completedWorkflows
        elapsedSeconds = 0
        sessionTotalSeconds = configuration.totalSeconds(for: mode)
        remainingSeconds = sessionTotalSeconds
        status = .idle
    }

    public mutating func enterInfinityMode() {
        mode = .infinity
        status = .idle
        elapsedSeconds = 0
        remainingSeconds = 0
        completedWorkflows = 0
        sessionTotalSeconds = 0
    }

    public mutating func exitInfinityMode(configuration: TimerConfiguration) {
        mode = .work
        status = .idle
        elapsedSeconds = 0
        completedWorkflows = 0
        sessionTotalSeconds = configuration.totalSeconds(for: .work)
        remainingSeconds = sessionTotalSeconds
    }
}
