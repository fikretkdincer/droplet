import Foundation
#if canImport(OSLog)
import OSLog
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

final class DropletWidgetStore {
    static let shared = DropletWidgetStore()
    static let appGroupIdentifier = "group.com.droplet.timer"

    private enum Key {
        static let dailyGoalMinutes = "dailyGoalMinutes"
        static let workHistory = "workHistory"
        static let selectedTheme = "selectedTheme"
        static let streakGardenMonthOffset = "streakGardenMonthOffset"
        static let lastStreakGardenIntentRun = "lastStreakGardenIntentRun"
        static let timerMode = "timerMode"
        static let timerStatus = "timerStatus"
        static let timerRemainingSeconds = "timerRemainingSeconds"
        static let timerTotalSeconds = "timerTotalSeconds"
        static let timerProgress = "timerProgress"
        static let timerLastUpdated = "timerLastUpdated"
        static let timerActionRequestId = "timerActionRequestId"
        static let consumedTimerActionRequestId = "consumedTimerActionRequestId"
    }

    private let defaults: UserDefaults
    #if canImport(OSLog)
    private let logger = Logger(subsystem: "com.droplet.timer", category: "DropletWidgetStore")
    #endif

    init(defaults: UserDefaults? = UserDefaults(suiteName: appGroupIdentifier)) {
        self.defaults = defaults ?? .standard
    }

    var dailyGoalMinutes: Int {
        get { defaults.integer(forKey: Key.dailyGoalMinutes) }
        set { defaults.set(newValue, forKey: Key.dailyGoalMinutes) }
    }

    var selectedThemeRaw: String {
        get { defaults.string(forKey: Key.selectedTheme) ?? "Dark" }
        set { defaults.set(newValue, forKey: Key.selectedTheme) }
    }

    var workHistory: [String: Int] {
        get {
            guard let data = defaults.data(forKey: Key.workHistory),
                  let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
                return [:]
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Key.workHistory)
            }
        }
    }

    var streakGardenMonthOffset: Int {
        get { defaults.integer(forKey: Key.streakGardenMonthOffset) }
        set { defaults.set(newValue, forKey: Key.streakGardenMonthOffset) }
    }

    var timerModeRaw: String {
        defaults.string(forKey: Key.timerMode) ?? "Work"
    }

    var timerStatusRaw: String {
        defaults.string(forKey: Key.timerStatus) ?? "idle"
    }

    var timerRemainingSeconds: Int {
        defaults.integer(forKey: Key.timerRemainingSeconds)
    }

    var timerTotalSeconds: Int {
        defaults.integer(forKey: Key.timerTotalSeconds)
    }

    var timerProgress: Double {
        defaults.double(forKey: Key.timerProgress)
    }

    var timerLastUpdated: TimeInterval {
        defaults.double(forKey: Key.timerLastUpdated)
    }

    var timerActionRequestId: TimeInterval {
        defaults.double(forKey: Key.timerActionRequestId)
    }

    var consumedTimerActionRequestId: TimeInterval {
        get { defaults.double(forKey: Key.consumedTimerActionRequestId) }
        set { defaults.set(newValue, forKey: Key.consumedTimerActionRequestId) }
    }

    func sync(dailyGoalMinutes: Int, workHistory: [String: Int], selectedThemeRaw: String) {
        self.dailyGoalMinutes = dailyGoalMinutes
        self.workHistory = workHistory
        self.selectedThemeRaw = selectedThemeRaw
        persist()
        reloadWidgets()
    }

    func syncGoalProgress(dailyGoalMinutes: Int, workHistory: [String: Int]) {
        self.dailyGoalMinutes = dailyGoalMinutes
        self.workHistory = workHistory
        persist()
        reloadWidgets()
    }

    func syncTheme(rawValue: String) {
        selectedThemeRaw = rawValue
        persist()
        reloadWidgets()
    }

    func shiftStreakGardenMonth(by delta: Int) {
        streakGardenMonthOffset += delta
        defaults.set(Date().timeIntervalSince1970, forKey: Key.lastStreakGardenIntentRun)
        #if canImport(OSLog)
        logger.info("Shifted streak garden month by \(delta, privacy: .public); new offset \(self.streakGardenMonthOffset, privacy: .public)")
        #endif
        persist()
        reloadWidgets()
    }

    func resetStreakGardenMonth() {
        streakGardenMonthOffset = 0
        defaults.set(Date().timeIntervalSince1970, forKey: Key.lastStreakGardenIntentRun)
        #if canImport(OSLog)
        logger.info("Reset streak garden month offset")
        #endif
        persist()
        reloadWidgets()
    }

    func syncTimer(modeRaw: String, statusRaw: String, remainingSeconds: Int, totalSeconds: Int, progress: Double, reload: Bool) {
        defaults.set(modeRaw, forKey: Key.timerMode)
        defaults.set(statusRaw, forKey: Key.timerStatus)
        defaults.set(max(0, remainingSeconds), forKey: Key.timerRemainingSeconds)
        defaults.set(max(0, totalSeconds), forKey: Key.timerTotalSeconds)
        defaults.set(min(max(progress, 0), 1), forKey: Key.timerProgress)
        defaults.set(Date().timeIntervalSince1970, forKey: Key.timerLastUpdated)
        persist()
        if reload {
            reloadWidgets()
        }
    }

    func requestTimerStart() {
        defaults.set(Date().timeIntervalSince1970, forKey: Key.timerActionRequestId)
        persist()
    }

    func markTimerStartRequestConsumed(_ requestId: TimeInterval) {
        consumedTimerActionRequestId = requestId
        persist()
    }

    private func persist() {
        defaults.synchronize()
    }

    private func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "DropletStreakGardenWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "DropletTimerBucketWidget")
        #endif
    }
}
