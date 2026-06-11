import DropletCore
import Foundation
import WidgetKit

struct TodayWidgetEntry: TimelineEntry {
    let date: Date
    let dailyGoalMinutes: Int
    let todayMinutes: Int
    let currentStreak: Int
    let weekRecords: [DailyFocusRecord]
    let themeRawValue: String
    let gradientEnabled: Bool
}

struct TodayWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayWidgetEntry {
        Self.sampleEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayWidgetEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayWidgetEntry>) -> Void) {
        let currentEntry = entry()
        let nextQuarterHour = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(minute: nextQuarterMinute),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(15 * 60)

        completion(Timeline(entries: [currentEntry], policy: .after(nextQuarterHour)))
    }

    private var nextQuarterMinute: Int {
        let minute = Calendar.current.component(.minute, from: Date())
        return ((minute / 15) + 1) * 15 % 60
    }

    private func entry() -> TodayWidgetEntry {
        let store = DropletWidgetStore.shared
        let history = FocusHistory(minutesByDay: store.workHistory)
        let now = Date()
        return TodayWidgetEntry(
            date: now,
            dailyGoalMinutes: store.dailyGoalMinutes,
            todayMinutes: history.minutes(on: now),
            currentStreak: Self.currentStreak(in: history, from: now),
            weekRecords: history.weekRecords(containing: now),
            themeRawValue: store.selectedThemeRaw,
            gradientEnabled: store.gradientEnabled
        )
    }

    private static func currentStreak(
        in history: FocusHistory,
        from date: Date,
        calendar: Calendar = .current
    ) -> Int {
        var streak = 0
        var cursor = date

        while history.minutes(on: cursor, calendar: calendar) > 0 {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }

        return streak
    }

    fileprivate static func sampleEntry() -> TodayWidgetEntry {
        let dailyGoalMinutes = 90
        let history = FocusHistory(minutesByDay: sampleHistory(todayMinutes: 65))
        let now = Date()
        return TodayWidgetEntry(
            date: now,
            dailyGoalMinutes: dailyGoalMinutes,
            todayMinutes: history.minutes(on: now),
            currentStreak: currentStreak(in: history, from: now),
            weekRecords: history.weekRecords(containing: now),
            themeRawValue: "Dark",
            gradientEnabled: true
        )
    }

    private static func sampleHistory(todayMinutes: Int) -> [String: Int] {
        let calendar = Calendar.current
        let pattern = [todayMinutes, 55, 80, 0, 42, 95, 25]

        return pattern.enumerated().reduce(into: [:]) { result, item in
            guard let date = calendar.date(byAdding: .day, value: -item.offset, to: Date()) else {
                return
            }
            result[FocusHistory.dayKey(for: date, calendar: calendar)] = item.element
        }
    }
}

extension TodayWidgetEntry {
    static var preview: TodayWidgetEntry {
        TodayWidgetProvider.sampleEntry()
    }

    var progress: GoalProgress {
        GoalProgress(dailyGoalMinutes: dailyGoalMinutes, minutesWorked: todayMinutes)
    }
}
