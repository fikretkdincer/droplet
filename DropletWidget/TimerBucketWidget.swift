import AppIntents
import SwiftUI
import WidgetKit

struct TimerBucketEntry: TimelineEntry {
    let date: Date
    let modeRaw: String
    let statusRaw: String
    let remainingSeconds: Int
    let totalSeconds: Int
    let progress: Double
    let lastUpdated: TimeInterval
    let themeRawValue: String
}

struct TimerBucketProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerBucketEntry {
        TimerBucketEntry(
            date: Date(),
            modeRaw: "Work",
            statusRaw: "idle",
            remainingSeconds: 25 * 60,
            totalSeconds: 25 * 60,
            progress: 0,
            lastUpdated: Date().timeIntervalSince1970,
            themeRawValue: "Dark"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerBucketEntry) -> Void) {
        completion(entry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerBucketEntry>) -> Void) {
        let now = Date()
        let first = entry(date: now)
        let dates = timelineDates(from: now, for: first)
        let entries = dates.map { entry(date: $0) }
        let refreshDate = dates.last?.addingTimeInterval(first.isPaused ? 1 : 60) ?? now.addingTimeInterval(60)
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }

    private func entry(date: Date) -> TimerBucketEntry {
        let store = DropletWidgetStore.shared
        return TimerBucketEntry(
            date: date,
            modeRaw: store.timerModeRaw,
            statusRaw: store.timerStatusRaw,
            remainingSeconds: store.timerRemainingSeconds,
            totalSeconds: store.timerTotalSeconds,
            progress: store.timerProgress,
            lastUpdated: store.timerLastUpdated,
            themeRawValue: store.selectedThemeRaw
        )
    }

    private func timelineDates(from start: Date, for entry: TimerBucketEntry) -> [Date] {
        if entry.isPaused {
            return (0..<24).map { start.addingTimeInterval(Double($0)) }
        }

        guard entry.statusRaw == "running", entry.totalSeconds > 0 else {
            return [start]
        }

        let secondsUntilEnd = max(60, entry.liveRemainingSeconds(at: start))
        let count = min(60, max(2, Int(ceil(Double(secondsUntilEnd) / 30.0)) + 1))
        return (0..<count).map { start.addingTimeInterval(Double($0 * 30)) }
    }
}

private extension TimerBucketEntry {
    static var preview: TimerBucketEntry {
        TimerBucketEntry(
            date: Date(),
            modeRaw: "Work",
            statusRaw: "running",
            remainingSeconds: 16 * 60,
            totalSeconds: 25 * 60,
            progress: 0.36,
            lastUpdated: Date().timeIntervalSince1970,
            themeRawValue: "Dark"
        )
    }

    var isRunning: Bool {
        statusRaw == "running"
    }

    var isBreak: Bool {
        modeRaw == "Break" || modeRaw == "Long Break"
    }

    var isPaused: Bool {
        statusRaw == "paused" || statusRaw == "pulsing"
    }

    func liveRemainingSeconds(at date: Date) -> Int {
        guard isRunning, totalSeconds > 0 else {
            return remainingSeconds
        }

        let elapsedSinceUpdate = max(0, Int(date.timeIntervalSince1970 - lastUpdated))
        return max(0, remainingSeconds - elapsedSinceUpdate)
    }

    func liveFill(at date: Date) -> Double {
        guard totalSeconds > 0 else {
            return modeRaw == "Infinity" ? 0.62 : 0
        }

        let remaining = liveRemainingSeconds(at: date)
        let elapsedProgress = Double(totalSeconds - remaining) / Double(totalSeconds)
        let clampedProgress = min(max(elapsedProgress, 0), 1)
        return isBreak ? 1 - clampedProgress : clampedProgress
    }

    func pausedBlinkOpacity(at date: Date) -> Double {
        guard isPaused else { return 1 }
        let phase = Int(date.timeIntervalSince1970) % 2
        return phase == 0 ? 0.54 : 1
    }
}

struct TimerBucketWidgetView: View {
    let entry: TimerBucketEntry

    private var theme: Theme {
        Theme(rawValue: entry.themeRawValue) ?? .dark
    }

    var body: some View {
        ZStack {
            TimerBucketWidgetBackground(theme: theme)

            Button(intent: StartTimerBucketIntent()) {
                TimerBucketDroplet(
                    fill: entry.liveFill(at: entry.date),
                    fillColor: fillColor,
                    rimColor: theme.textColor,
                    isRunning: entry.isRunning,
                    pausedOpacity: entry.pausedBlinkOpacity(at: entry.date)
                )
                .frame(width: 116, height: 132)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var fillColor: Color {
        entry.isBreak ? theme.breakAccent : theme.workAccent
    }

    private var themeIsDark: Bool {
        switch theme {
        case .light, .beige, .linen, .poppy, .blossom, .frog:
            return false
        default:
            return true
        }
    }
}

struct TimerBucketDroplet: View {
    let fill: Double
    let fillColor: Color
    let rimColor: Color
    let isRunning: Bool
    let pausedOpacity: Double

    var body: some View {
        ZStack {
            Image(systemName: "drop.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(rimColor.opacity(0.12))

            GeometryReader { proxy in
                let height = proxy.size.height
                let fillHeight = height * min(max(fill, 0), 1)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ZStack(alignment: .top) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        fillColor.opacity(0.74),
                                        fillColor,
                                        Color.white.opacity(0.28)
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )

                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: proxy.size.width * 0.74, height: 5)
                            .offset(y: -2)
                    }
                    .frame(height: fillHeight)
                }
            }
            .mask(
                Image(systemName: "drop.fill")
                    .resizable()
                    .scaledToFit()
            )

            Image(systemName: "drop.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.clear)
                .overlay(
                    Image(systemName: "drop")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(rimColor.opacity(0.32))
                )
                .shadow(color: fillColor.opacity(isRunning ? 0.42 : 0.16), radius: isRunning ? 8 : 3, x: 0, y: 0)
                .opacity(pausedOpacity)
        }
    }
}

struct TimerBucketWidgetBackground: View {
    let theme: Theme

    var body: some View {
        ZStack {
            theme.backgroundColor

            LinearGradient(
                colors: [
                    theme.textColor.opacity(themeIsDark ? 0.10 : 0.16),
                    .clear,
                    theme.workAccent.opacity(themeIsDark ? 0.18 : 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var themeIsDark: Bool {
        switch theme {
        case .light, .beige, .linen, .poppy, .blossom, .frog:
            return false
        default:
            return true
        }
    }
}

struct DropletTimerBucketWidget: Widget {
    let kind = "DropletTimerBucketWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerBucketProvider()) { entry in
            TimerBucketWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    TimerBucketWidgetBackground(theme: Theme(rawValue: entry.themeRawValue) ?? .dark)
                }
        }
        .configurationDisplayName("Droplet Timer Bucket")
        .description("A small droplet timer that fills through focus and drains through breaks.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    DropletTimerBucketWidget()
} timeline: {
    TimerBucketEntry.preview
}
#endif
