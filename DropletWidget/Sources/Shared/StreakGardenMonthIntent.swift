import AppIntents
import OSLog

private let streakGardenIntentLogger = Logger(
    subsystem: "com.droplet.timer",
    category: "StreakGardenWidgetIntent"
)

struct PreviousStreakGardenMonthIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Streak Garden Month"
    static var description = IntentDescription("Shows the previous month in the Droplet Streak Garden widget.")

    func perform() async throws -> some IntentResult {
        streakGardenIntentLogger.info("Previous month intent started")
        DropletWidgetStore.shared.shiftStreakGardenMonth(by: -1)
        streakGardenIntentLogger.info("Previous month intent finished")
        return .result()
    }
}

struct NextStreakGardenMonthIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Streak Garden Month"
    static var description = IntentDescription("Shows the next month in the Droplet Streak Garden widget.")

    func perform() async throws -> some IntentResult {
        streakGardenIntentLogger.info("Next month intent started")
        DropletWidgetStore.shared.shiftStreakGardenMonth(by: 1)
        streakGardenIntentLogger.info("Next month intent finished")
        return .result()
    }
}

struct ResetStreakGardenMonthIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Current Streak Garden Month"
    static var description = IntentDescription("Returns the Droplet Streak Garden widget to the current month.")

    func perform() async throws -> some IntentResult {
        streakGardenIntentLogger.info("Reset month intent started")
        DropletWidgetStore.shared.resetStreakGardenMonth()
        streakGardenIntentLogger.info("Reset month intent finished")
        return .result()
    }
}
