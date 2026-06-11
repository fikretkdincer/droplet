import Foundation

/// Date-keyed focus history that can be synced across platforms.
public struct FocusHistory: Codable, Equatable, Sendable {
    public private(set) var minutesByDay: [String: Int]

    public init(minutesByDay: [String: Int] = [:]) {
        self.minutesByDay = minutesByDay.mapValues { max(0, $0) }
    }

    @discardableResult
    public mutating func record(
        minutes: Int,
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard minutes > 0 else {
            return self.minutes(on: date, calendar: calendar)
        }

        let key = Self.dayKey(for: date, calendar: calendar)
        let updatedMinutes = (minutesByDay[key] ?? 0) + minutes
        minutesByDay[key] = updatedMinutes
        return updatedMinutes
    }

    public func minutes(on date: Date = Date(), calendar: Calendar = .current) -> Int {
        minutesByDay[Self.dayKey(for: date, calendar: calendar)] ?? 0
    }

    public static func dayKey(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    public func weekRecords(
        containing date: Date = Date(),
        weekStartWeekday: Int = 2,
        calendar: Calendar = .current
    ) -> [DailyFocusRecord] {
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = weekStartWeekday
        guard let weekStart = calendar.date(from: components) else { return [] }

        return (0..<7).compactMap { dayOffset in
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                return nil
            }
            let key = Self.dayKey(for: day, calendar: calendar)
            return DailyFocusRecord(date: day, key: key, minutes: minutesByDay[key] ?? 0)
        }
    }
}

public struct DailyFocusRecord: Codable, Equatable, Sendable {
    public let date: Date
    public let key: String
    public let minutes: Int

    public init(date: Date, key: String, minutes: Int) {
        self.date = date
        self.key = key
        self.minutes = max(0, minutes)
    }
}
