import DropletCore
import SwiftUI
import WidgetKit

struct TodayWidgetView: View {
    let entry: TodayWidgetEntry

    @Environment(\.widgetFamily) private var family

    private var theme: Theme {
        Theme(rawValue: entry.themeRawValue) ?? .dark
    }

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumLayout
            default:
                smallLayout
            }
        }
        .padding(.horizontal, family == .systemMedium ? 14 : 12)
        .padding(.vertical, 12)
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            TodayWidgetHeader(theme: theme, streak: entry.currentStreak, compact: true)

            HStack(spacing: 10) {
                TimerBucketDroplet(
                    fill: entry.progress.visualRatio,
                    fillColor: entry.progress.isComplete ? theme.breakAccent : theme.workAccent,
                    rimColor: theme.textColor,
                    isRunning: entry.progress.isComplete,
                    pausedOpacity: entry.dailyGoalMinutes > 0 ? 1 : 0.58
                )
                .frame(width: 54, height: 68)

                VStack(alignment: .leading, spacing: 2) {
                    Text(formatMinutes(entry.todayMinutes))
                        .font(dropletFont(size: 20, weight: .medium))
                        .foregroundStyle(theme.textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(shortStatusText)
                        .font(dropletFont(size: 8, weight: .light))
                        .tracking(0.9)
                        .foregroundStyle(theme.workAccent.opacity(0.92))
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                }
            }

            TodayProgressBar(progress: entry.progress.visualRatio, theme: theme)
                .frame(height: 5)
        }
    }

    private var mediumLayout: some View {
        HStack(spacing: 14) {
            TimerBucketDroplet(
                fill: entry.progress.visualRatio,
                fillColor: entry.progress.isComplete ? theme.breakAccent : theme.workAccent,
                rimColor: theme.textColor,
                isRunning: entry.progress.isComplete,
                pausedOpacity: entry.dailyGoalMinutes > 0 ? 1 : 0.58
            )
            .frame(width: 72, height: 90)

            VStack(alignment: .leading, spacing: 7) {
                TodayWidgetHeader(theme: theme, streak: entry.currentStreak, compact: false)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(formatMinutes(entry.todayMinutes))
                        .font(dropletFont(size: 30, weight: .medium))
                        .foregroundStyle(theme.textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("today")
                        .font(dropletFont(size: 10, weight: .light))
                        .foregroundStyle(theme.textColor.opacity(0.6))
                }

                TodayProgressBar(progress: entry.progress.visualRatio, theme: theme)
                    .frame(height: 6)

                Text(longStatusText)
                    .font(dropletFont(size: 9, weight: .light))
                    .tracking(0.8)
                    .foregroundStyle(theme.workAccent.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                TodayWeekStrip(records: entry.weekRecords, goalMinutes: entry.dailyGoalMinutes, theme: theme)
            }
        }
    }

    private var shortStatusText: String {
        if entry.dailyGoalMinutes <= 0 {
            return "SET A GOAL"
        }

        if entry.progress.isComplete {
            return "GOAL COMPLETE"
        }

        return "\(formatMinutes(entry.progress.remainingMinutes)) LEFT"
    }

    private var longStatusText: String {
        if entry.dailyGoalMinutes <= 0 {
            return "Set a daily goal to fill the droplet"
        }

        if entry.progress.isComplete {
            return "\(entry.progress.percent)% of \(formatMinutes(entry.dailyGoalMinutes)) goal"
        }

        return "\(formatMinutes(entry.progress.remainingMinutes)) left of \(formatMinutes(entry.dailyGoalMinutes))"
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let safeMinutes = max(0, minutes)
        let hours = safeMinutes / 60
        let mins = safeMinutes % 60

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

private struct TodayWidgetHeader: View {
    let theme: Theme
    let streak: Int
    let compact: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY")
                    .font(dropletFont(size: compact ? 12 : 13, weight: .light))
                    .foregroundStyle(theme.textColor)
                    .lineLimit(1)

                Text("FOCUS PROGRESS")
                    .font(dropletFont(size: 7, weight: .light))
                    .tracking(1.1)
                    .foregroundStyle(theme.workAccent.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(streak)")
                    .font(dropletFont(size: compact ? 15 : 17, weight: .light))
                    .foregroundStyle(streak > 0 ? theme.workAccent : theme.textColor.opacity(0.45))

                Text("STREAK")
                    .font(dropletFont(size: 7, weight: .light))
                    .tracking(0.8)
                    .foregroundStyle(theme.textColor.opacity(0.55))
            }
        }
    }

    private func dropletFont(size: CGFloat, weight: Font.Weight) -> Font {
        .custom("Avenir Next", size: size).weight(weight)
    }
}

private struct TodayProgressBar: View {
    let progress: Double
    let theme: Theme

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.textColor.opacity(0.12))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.workAccent.opacity(0.88),
                                theme.breakAccent.opacity(0.92)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * min(max(progress, 0), 1))
            }
        }
        .clipShape(Capsule())
    }
}

private struct TodayWeekStrip: View {
    let records: [DailyFocusRecord]
    let goalMinutes: Int
    let theme: Theme

    var body: some View {
        HStack(spacing: 5) {
            ForEach(records, id: \.key) { record in
                VStack(spacing: 3) {
                    Text(weekday(for: record.date))
                        .font(dropletFont(size: 7, weight: .light))
                        .foregroundStyle(theme.textColor.opacity(0.56))
                        .lineLimit(1)

                    Image(systemName: "drop.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(color(for: record.minutes))
                        .frame(width: 10, height: 12)
                        .shadow(
                            color: theme.workAccent.opacity(record.minutes > 0 ? 0.25 : 0),
                            radius: 2,
                            x: 0,
                            y: 0
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func color(for minutes: Int) -> Color {
        guard minutes > 0 else {
            return theme.textColor.opacity(0.16)
        }

        let progress = GoalProgress(dailyGoalMinutes: goalMinutes, minutesWorked: minutes)
        if progress.percent >= 125 {
            return Color(red: 1.0, green: 0.78, blue: 0.30)
        }
        if progress.isComplete {
            return theme.breakAccent
        }
        if progress.percent >= 50 {
            return theme.workAccent
        }
        return theme.workAccent.opacity(0.58)
    }

    private func weekday(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }

    private func dropletFont(size: CGFloat, weight: Font.Weight) -> Font {
        .custom("Avenir Next", size: size).weight(weight)
    }
}
