import Foundation

public struct DailyGoalTrackerState: Codable, Equatable, Sendable {
    public static let milestones = GoalProgress.defaultMilestones

    public var dailyGoalMinutes: Int
    public var workHistory: [String: Int]
    public var notifiedMilestones: [String: Set<Int>]

    public init(
        dailyGoalMinutes: Int = 0,
        workHistory: [String: Int] = [:],
        notifiedMilestones: [String: Set<Int>] = [:]
    ) {
        self.dailyGoalMinutes = max(0, dailyGoalMinutes)
        self.workHistory = workHistory.mapValues { max(0, $0) }
        self.notifiedMilestones = notifiedMilestones
    }

    public var hasGoalSet: Bool {
        dailyGoalMinutes > 0
    }

    public mutating func setDailyGoal(hours: Double) {
        dailyGoalMinutes = max(0, Int(hours * 60))
    }

    @discardableResult
    public mutating func recordWorkSession(
        minutes: Int,
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> Int? {
        let dayKey = FocusHistory.dayKey(for: date, calendar: calendar)
        let previousMinutes = workHistory[dayKey] ?? 0
        var history = FocusHistory(minutesByDay: workHistory)
        let newMinutes = history.record(minutes: minutes, on: date, calendar: calendar)
        workHistory = history.minutesByDay

        return checkForNewMilestone(
            dateKey: dayKey,
            previousMinutes: previousMinutes,
            newMinutes: newMinutes
        )
    }

    public func getWeekData(
        weekOffset: Int = 0,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> [DailyFocusRecord] {
        let targetDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: date) ?? date
        return getWeekData(containing: targetDate, calendar: calendar)
    }

    public func getWeekData(
        containing date: Date = Date(),
        calendar: Calendar = .current
    ) -> [DailyFocusRecord] {
        FocusHistory(minutesByDay: workHistory)
            .weekRecords(containing: date, weekStartWeekday: 2, calendar: calendar)
    }

    public func getWeekRangeString(
        weekOffset: Int = 0,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let weekData = getWeekData(weekOffset: weekOffset, from: date, calendar: calendar)
        guard let first = weekData.first?.date, let last = weekData.last?.date else {
            return "This Week"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
    }

    public func getTodayProgress(
        date: Date = Date(),
        calendar: Calendar = .current
    ) -> Double {
        GoalProgress(
            dailyGoalMinutes: dailyGoalMinutes,
            minutesWorked: getTodayMinutes(date: date, calendar: calendar)
        )
        .ratio
    }

    public func getTodayMinutes(
        date: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        FocusHistory(minutesByDay: workHistory).minutes(on: date, calendar: calendar)
    }

    public static func formatMinutes(_ minutes: Int) -> String {
        let safeMinutes = max(0, minutes)
        let hours = safeMinutes / 60
        let mins = safeMinutes % 60

        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        }
        return "\(mins)m"
    }

    private mutating func checkForNewMilestone(
        dateKey: String,
        previousMinutes: Int,
        newMinutes: Int
    ) -> Int? {
        guard dailyGoalMinutes > 0 else { return nil }

        let progress = GoalProgress(dailyGoalMinutes: dailyGoalMinutes, minutesWorked: newMinutes)
        var todayMilestones = notifiedMilestones[dateKey] ?? []
        let highestNewMilestone = progress.highestCrossedMilestone(
            previousMinutes: previousMinutes,
            milestones: Self.milestones,
            alreadyNotified: todayMilestones
        )

        if let highestNewMilestone {
            let previousPercent = GoalProgress(dailyGoalMinutes: dailyGoalMinutes, minutesWorked: previousMinutes).percent
            let newPercent = progress.percent
            for milestone in Self.milestones where previousPercent < milestone && newPercent >= milestone {
                todayMilestones.insert(milestone)
            }
            notifiedMilestones[dateKey] = todayMilestones
            return highestNewMilestone
        }

        return nil
    }
}
