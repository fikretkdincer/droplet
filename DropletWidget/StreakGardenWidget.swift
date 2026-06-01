import AppIntents
import SwiftUI
import WidgetKit

struct StreakGardenEntry: TimelineEntry {
    let date: Date
    let month: Date
    let monthOffset: Int
    let dailyGoalMinutes: Int
    let workHistory: [String: Int]
    let themeRawValue: String
}

struct StreakGardenProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakGardenEntry {
        StreakGardenEntry(
            date: Date(),
            month: Date(),
            monthOffset: 0,
            dailyGoalMinutes: 60,
            workHistory: Self.sampleHistory(),
            themeRawValue: "Dark"
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
            themeRawValue: store.selectedThemeRaw
        )
    }

    private static func sampleHistory() -> [String: Int] {
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

private extension StreakGardenEntry {
    static var preview: StreakGardenEntry {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let history = (0..<26).reduce(into: [String: Int]()) { result, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return }
            let pattern = [0, 12, 34, 49, 65, 83]
            result[formatter.string(from: date)] = pattern[offset % pattern.count]
        }

        return StreakGardenEntry(
            date: Date(),
            month: Date(),
            monthOffset: 0,
            dailyGoalMinutes: 60,
            workHistory: history,
            themeRawValue: "Dark"
        )
    }
}

struct StreakGardenWidgetView: View {
    let entry: StreakGardenEntry

    private var theme: Theme {
        Theme(rawValue: entry.themeRawValue) ?? .dark
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            dropletCalendar
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    monthButton(systemName: "chevron.left", direction: .previous)

                    Text(monthTitle)
                        .font(dropletFont(size: 14, weight: .light))
                        .foregroundStyle(theme.textColor)
                        .lineLimit(1)

                    monthButton(systemName: "chevron.right", direction: .next)
                }

                Text("STREAK GARDEN")
                    .font(dropletFont(size: 8, weight: .light))
                    .tracking(1.4)
                    .foregroundStyle(theme.workAccent.opacity(0.92))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(currentStreak)")
                    .font(dropletFont(size: 17, weight: .light))
                    .foregroundStyle(currentStreak > 0 ? theme.workAccent : theme.textColor.opacity(0.45))
                if entry.monthOffset == 0 {
                    Text("DAY STREAK")
                        .font(dropletFont(size: 7, weight: .light))
                        .tracking(0.8)
                        .foregroundStyle(theme.textColor.opacity(0.55))
                } else {
                    Button(intent: ResetStreakGardenMonthIntent()) {
                        Text("TODAY")
                            .font(dropletFont(size: 7, weight: .light))
                            .tracking(0.8)
                            .foregroundStyle(theme.workAccent.opacity(0.92))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func monthButton(systemName: String, direction: MonthButtonDirection) -> some View {
        switch direction {
        case .previous:
            Button(intent: PreviousStreakGardenMonthIntent()) {
                monthButtonLabel(systemName: systemName)
            }
            .buttonStyle(.plain)
        case .next:
            Button(intent: NextStreakGardenMonthIntent()) {
                monthButtonLabel(systemName: systemName)
            }
            .buttonStyle(.plain)
        }
    }

    private func monthButtonLabel(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 8, weight: .medium))
            .foregroundStyle(theme.textColor.opacity(0.62))
            .frame(width: 18, height: 18)
            .contentShape(Rectangle())
    }

    private var dropletCalendar: some View {
        let columns = Array(repeating: GridItem(.flexible(minimum: 14), spacing: 2), count: 7)

        return LazyVGrid(columns: columns, alignment: .center, spacing: 2) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(dropletFont(size: 8, weight: .light))
                    .foregroundStyle(theme.textColor.opacity(0.58))
                    .frame(minWidth: 14, maxWidth: .infinity, minHeight: 9)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            ForEach(calendarDaySlots) { slot in
                if let date = slot.date {
                    let minutes = minutesForDate(date)
                    let level = StreakGardenScale.level(minutes: minutes, goalMinutes: entry.dailyGoalMinutes)
                    DropletDayMark(level: level, theme: theme, isToday: Calendar.current.isDateInToday(date))
                        .frame(width: 11, height: 11)
                        .help("\(dayNumber(date)): \(formatMinutes(minutes))")
                } else {
                    Color.clear.frame(width: 11, height: 11)
                }
            }
        }
        .id(monthIdentity)
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private var calendarDaySlots: [StreakGardenDaySlot] {
        let leading = leadingBlankDays
        let usedSlots = leading + daysInMonth.count
        let trailing = max(0, 42 - usedSlots)
        let rawSlots = Array(repeating: Optional<Date>.none, count: leading)
            + daysInMonth.map(Optional.some)
            + Array(repeating: Optional<Date>.none, count: trailing)

        return rawSlots.enumerated().map { index, date in
            let datePart = date.map(dateKey) ?? "empty"
            return StreakGardenDaySlot(id: "\(monthIdentity)-\(index)-\(datePart)", date: date)
        }
    }

    private var monthIdentity: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: entry.month)
    }

    private var daysInMonth: [Date] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: entry.month) else { return [] }
        let components = calendar.dateComponents([.year, .month], from: entry.month)
        return range.compactMap { day in
            var dayComponents = components
            dayComponents.day = day
            return calendar.date(from: dayComponents)
        }
    }

    private var leadingBlankDays: Int {
        let calendar = Calendar.current
        guard let first = daysInMonth.first else { return 0 }
        return (calendar.component(.weekday, from: first) + 5) % 7
    }

    private var weekdaySymbols: [String] {
        ["M", "T", "W", "T", "F", "S", "S"]
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: entry.month)
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var cursor = Date()

        while true {
            if minutesForDate(cursor) <= 0 { break }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return streak
    }

    private var themeIsDark: Bool {
        switch theme {
        case .light, .beige, .linen, .poppy, .blossom, .frog:
            return false
        default:
            return true
        }
    }

    private func minutesForDate(_ date: Date) -> Int {
        entry.workHistory[dateKey(date)] ?? 0
    }

    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }

    private func dropletFont(size: CGFloat, weight: Font.Weight) -> Font {
        .custom("Avenir Next", size: size).weight(weight)
    }
}

private enum MonthButtonDirection {
    case previous
    case next
}

private struct StreakGardenDaySlot: Identifiable {
    let id: String
    let date: Date?
}

struct StreakGardenWidgetBackground: View {
    let theme: Theme

    private var themeIsDark: Bool {
        switch theme {
        case .light, .beige, .linen, .poppy, .blossom, .frog:
            return false
        default:
            return true
        }
    }

    var body: some View {
        ZStack {
            theme.backgroundColor

            LinearGradient(
                colors: [
                    theme.textColor.opacity(themeIsDark ? 0.08 : 0.12),
                    .clear,
                    theme.workAccent.opacity(themeIsDark ? 0.16 : 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct DropletDayMark: View {
    let level: StreakGardenLevel
    let theme: Theme
    let isToday: Bool

    var body: some View {
        Image(systemName: "drop.fill")
            .resizable()
            .scaledToFit()
            .symbolRenderingMode(.palette)
            .foregroundStyle(primaryColor, highlightColor)
            .opacity(level == .empty ? 0.28 : 1)
            .shadow(color: glowColor, radius: glowRadius, x: 0, y: 0)
            .overlay(todayRing)
            .accessibilityHidden(true)
    }

    private var primaryColor: Color {
        switch level {
        case .empty:
            return theme.textColor.opacity(0.18)
        case .low:
            return theme.workAccent.opacity(0.34)
        case .medium:
            return theme.workAccent.opacity(0.58)
        case .high:
            return theme.workAccent.opacity(0.82)
        case .complete:
            return theme.workAccent
        case .gold:
            return Color(red: 1.0, green: 0.76, blue: 0.24)
        }
    }

    private var highlightColor: Color {
        switch level {
        case .gold:
            return Color.white.opacity(0.95)
        case .empty:
            return theme.textColor.opacity(0.10)
        default:
            return Color.white.opacity(0.65)
        }
    }

    private var glowColor: Color {
        switch level {
        case .empty:
            return .clear
        case .gold:
            return Color(red: 1.0, green: 0.71, blue: 0.15).opacity(0.85)
        default:
            return theme.workAccent.opacity(0.34)
        }
    }

    private var glowRadius: CGFloat {
        switch level {
        case .empty, .low: return 0
        case .medium: return 1.5
        case .high: return 2.5
        case .complete: return 4
        case .gold: return 5.5
        }
    }

    @ViewBuilder
    private var todayRing: some View {
        if isToday {
            Circle()
                .stroke(theme.textColor.opacity(0.42), lineWidth: 1)
                .frame(width: 14, height: 14)
        }
    }
}

struct DropletStreakGardenWidget: Widget {
    let kind = "DropletStreakGardenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakGardenProvider()) { entry in
            StreakGardenWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    StreakGardenWidgetBackground(theme: Theme(rawValue: entry.themeRawValue) ?? .dark)
                }
        }
        .configurationDisplayName("Droplet Streak Garden")
        .description("A monthly droplet heatmap that shines with your selected theme and turns gold after 125% of your goal.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

@main
struct DropletWidgetBundle: WidgetBundle {
    var body: some Widget {
        DropletStreakGardenWidget()
        DropletTimerBucketWidget()
    }
}

#if DEBUG
#Preview(as: .systemMedium) {
    DropletStreakGardenWidget()
} timeline: {
    StreakGardenEntry.preview
}
#endif
