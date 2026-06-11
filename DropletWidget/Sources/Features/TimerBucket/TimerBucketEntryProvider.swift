import Foundation
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
    let gradientEnabled: Bool
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
            themeRawValue: "Dark",
            gradientEnabled: true
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
            themeRawValue: store.selectedThemeRaw,
            gradientEnabled: store.gradientEnabled
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

extension TimerBucketEntry {
    static var preview: TimerBucketEntry {
        TimerBucketEntry(
            date: Date(),
            modeRaw: "Work",
            statusRaw: "running",
            remainingSeconds: 16 * 60,
            totalSeconds: 25 * 60,
            progress: 0.36,
            lastUpdated: Date().timeIntervalSince1970,
            themeRawValue: "Dark",
            gradientEnabled: true
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
