import Foundation

/// Daily goal progress math shared by the app, widgets, and future platforms.
public struct GoalProgress: Codable, Equatable, Sendable {
    public static let defaultMilestones = [25, 50, 75, 100, 125]

    public let dailyGoalMinutes: Int
    public let minutesWorked: Int

    public init(dailyGoalMinutes: Int, minutesWorked: Int) {
        self.dailyGoalMinutes = max(0, dailyGoalMinutes)
        self.minutesWorked = max(0, minutesWorked)
    }

    public var ratio: Double {
        guard dailyGoalMinutes > 0 else { return 0 }
        return Double(minutesWorked) / Double(dailyGoalMinutes)
    }

    public var visualRatio: Double {
        min(max(ratio, 0), 1)
    }

    public var percent: Int {
        guard dailyGoalMinutes > 0 else { return 0 }
        return (minutesWorked * 100) / dailyGoalMinutes
    }

    public var remainingMinutes: Int {
        guard dailyGoalMinutes > 0 else { return 0 }
        return max(0, dailyGoalMinutes - minutesWorked)
    }

    public var isComplete: Bool {
        dailyGoalMinutes > 0 && minutesWorked >= dailyGoalMinutes
    }

    public func highestCrossedMilestone(
        previousMinutes: Int,
        milestones: [Int] = Self.defaultMilestones,
        alreadyNotified: Set<Int> = []
    ) -> Int? {
        guard dailyGoalMinutes > 0 else { return nil }

        let previousPercent = (max(0, previousMinutes) * 100) / dailyGoalMinutes
        return milestones
            .filter { previousPercent < $0 && percent >= $0 && !alreadyNotified.contains($0) }
            .max()
    }
}
