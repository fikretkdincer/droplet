import Foundation

enum StreakGardenMonthNavigation {
    static func month(from baseDate: Date, offset: Int, calendar: Calendar = .current) -> Date {
        let shifted = calendar.date(byAdding: .month, value: offset, to: baseDate) ?? baseDate
        let components = calendar.dateComponents([.year, .month], from: shifted)
        return calendar.date(from: components) ?? shifted
    }
}
