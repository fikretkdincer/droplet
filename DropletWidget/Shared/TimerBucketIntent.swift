import AppIntents
import OSLog

private let timerBucketIntentLogger = Logger(
    subsystem: "com.droplet.timer",
    category: "TimerBucketWidgetIntent"
)

struct StartTimerBucketIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Droplet Timer"
    static var description = IntentDescription("Starts, resumes, or pauses the Droplet timer from the timer bucket widget.")
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        timerBucketIntentLogger.info("Timer bucket start intent started")
        DropletWidgetStore.shared.requestTimerStart()
        timerBucketIntentLogger.info("Timer bucket start intent finished")
        return .result()
    }
}
