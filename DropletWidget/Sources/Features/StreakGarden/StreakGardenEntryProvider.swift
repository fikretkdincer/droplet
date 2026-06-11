import Foundation
import WidgetKit

struct StreakGardenEntry: TimelineEntry {
    let date: Date
    let month: Date
    let monthOffset: Int
    let dailyGoalMinutes: Int
    let workHistory: [String: Int]
    let themeRawValue: String
    let gradientEnabled: Bool
}

struct StreakGardenProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakGardenEntry {
        StreakGardenEntry(
            date: Date(),
            month: Date(),
            monthOffset: 0,
            dailyGoalMinutes: 60,
            workHistory: Self.sampleHistory(),
            themeRawValue: "Dark",
            gradientEnabled: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakGardenEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakGardenEntry>) -> Void) {
        let entry = entry()
        let nextRefresh = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func entry() -> StreakGardenEntry {
        let store = DropletWidgetStore.shared
        let monthOffset = store.streakGardenMonthOffset
        return StreakGardenEntry(
            date: Date(),
            month: StreakGardenMonthNavigation.month(from: Date(), offset: monthOffset),
            monthOffset: monthOffset,
            dailyGoalMinutes: store.dailyGoalMinutes,
            workHistory: store.workHistory,
            themeRawValue: store.selectedThemeRaw,
            gradientEnabled: store.gradientEnabled
        )
    }

    fileprivate static func sampleHistory() -> [String: Int] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return (0..<26).reduce(into: [:]) { result, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return }
            let pattern = [0, 12, 34, 49, 65, 83]
            result[formatter.string(from: date)] = pattern[offset % pattern.count]
        }
    }
}

extension StreakGardenEntry {
    static var preview: StreakGardenEntry {
        StreakGardenEntry(
            date: Date(),
            month: Date(),
            monthOffset: 0,
            dailyGoalMinutes: 60,
            workHistory: StreakGardenProvider.sampleHistory(),
            themeRawValue: "Dark",
            gradientEnabled: true
        )
    }
}
