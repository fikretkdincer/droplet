import XCTest
@testable import DropletCore

final class DropletTimerRuntimeTests: XCTestCase {
    private let configuration = TimerConfiguration(
        workDurationMinutes: 25,
        shortBreakDurationMinutes: 5,
        longBreakDurationMinutes: 15,
        workflowsBeforeLongBreak: 4
    )

    func testStartPauseAndResetKeepExpectedCountdownState() {
        var runtime = DropletTimerRuntime(configuration: configuration)

        XCTAssertEqual(runtime.mode, .work)
        XCTAssertEqual(runtime.status, .idle)
        XCTAssertEqual(runtime.remainingSeconds, 1_500)
        XCTAssertEqual(runtime.formattedTime, "25:00")

        runtime.start()
        XCTAssertEqual(runtime.status, .running)

        runtime.tick(configuration: configuration, autoStartNextSession: false)
        XCTAssertEqual(runtime.remainingSeconds, 1_499)
        XCTAssertEqual(runtime.formattedTime, "24:59")

        runtime.pause()
        XCTAssertEqual(runtime.status, .paused)

        runtime.reset(configuration: configuration)
        XCTAssertEqual(runtime.status, .idle)
        XCTAssertEqual(runtime.remainingSeconds, 1_500)
        XCTAssertEqual(runtime.progressRatio, 0)
    }

    func testWorkCompletionWithoutAutoStartWaitsAtIdleBreak() {
        let shortConfiguration = TimerConfiguration(
            workDurationMinutes: 1,
            shortBreakDurationMinutes: 5,
            longBreakDurationMinutes: 15,
            workflowsBeforeLongBreak: 4
        )
        var runtime = DropletTimerRuntime(configuration: shortConfiguration)

        runtime.start()
        for _ in 0..<60 {
            runtime.tick(configuration: shortConfiguration, autoStartNextSession: false)
        }

        XCTAssertEqual(runtime.mode, .shortBreak)
        XCTAssertEqual(runtime.status, .idle)
        XCTAssertEqual(runtime.completedWorkflows, 1)
        XCTAssertEqual(runtime.remainingSeconds, 300)
    }

    func testFourthWorkSessionAdvancesToLongBreak() {
        var runtime = DropletTimerRuntime(configuration: configuration)
        runtime.completedWorkflows = 3
        runtime.mode = .work
        runtime.remainingSeconds = 0

        runtime.advanceToNextPhase(configuration: configuration)

        XCTAssertEqual(runtime.mode, .longBreak)
        XCTAssertEqual(runtime.completedWorkflows, 0)
        XCTAssertEqual(runtime.remainingSeconds, 900)
    }

    func testInfinityModeCountsUpAndFormatsHours() {
        var runtime = DropletTimerRuntime(configuration: configuration, startsInInfinityMode: true)

        runtime.start()
        for _ in 0..<3_661 {
            runtime.tick(configuration: configuration, autoStartNextSession: false)
        }

        XCTAssertEqual(runtime.mode, .infinity)
        XCTAssertEqual(runtime.elapsedSeconds, 3_661)
        XCTAssertEqual(runtime.formattedTime, "1:01:01")
        XCTAssertEqual(runtime.progressRatio, 0)
    }

    func testBulkAdvanceMatchesForegroundWorkTicksAndReportsFocusedSeconds() {
        var runtime = DropletTimerRuntime(configuration: configuration)
        runtime.start()

        let result = runtime.advance(by: 75)

        XCTAssertEqual(result, TimerAdvanceResult(elapsedSeconds: 75, focusedSeconds: 75))
        XCTAssertEqual(runtime.remainingSeconds, 1_425)
        XCTAssertEqual(runtime.status, .running)
    }

    func testBulkAdvanceStopsAtCompletedPhaseAndPulses() {
        let shortConfiguration = TimerConfiguration(
            workDurationMinutes: 1,
            shortBreakDurationMinutes: 5,
            longBreakDurationMinutes: 15,
            workflowsBeforeLongBreak: 4
        )
        var runtime = DropletTimerRuntime(configuration: shortConfiguration)
        runtime.start()

        let result = runtime.advance(by: 125)

        XCTAssertEqual(result, TimerAdvanceResult(elapsedSeconds: 60, focusedSeconds: 60, completedModes: [.work]))
        XCTAssertEqual(runtime.mode, .work)
        XCTAssertEqual(runtime.status, .pulsing)
        XCTAssertEqual(runtime.remainingSeconds, 0)
    }

    func testConfiguredBulkAdvanceWithoutAutoStartWaitsAtIdleBreak() {
        let shortConfiguration = TimerConfiguration(
            workDurationMinutes: 1,
            shortBreakDurationMinutes: 5,
            longBreakDurationMinutes: 15,
            workflowsBeforeLongBreak: 4
        )
        var runtime = DropletTimerRuntime(configuration: shortConfiguration)
        runtime.start()

        let result = runtime.advance(
            by: 125,
            configuration: shortConfiguration,
            autoStartNextSession: false
        )

        XCTAssertEqual(result, TimerAdvanceResult(elapsedSeconds: 60, focusedSeconds: 60, completedModes: [.work]))
        XCTAssertEqual(runtime.mode, .shortBreak)
        XCTAssertEqual(runtime.status, .idle)
        XCTAssertEqual(runtime.remainingSeconds, 300)
    }

    func testBulkAdvanceCountsInfinityTimeWithoutLimit() {
        var runtime = DropletTimerRuntime(configuration: configuration, startsInInfinityMode: true)
        runtime.start()

        let result = runtime.advance(by: 3_661)

        XCTAssertEqual(result, TimerAdvanceResult(elapsedSeconds: 3_661, focusedSeconds: 3_661))
        XCTAssertEqual(runtime.status, .running)
        XCTAssertEqual(runtime.elapsedSeconds, 3_661)
        XCTAssertEqual(runtime.formattedTime, "1:01:01")
    }

    func testBulkAdvanceAutoStartsBreakAfterCompletedWork() {
        let shortConfiguration = TimerConfiguration(
            workDurationMinutes: 1,
            shortBreakDurationMinutes: 5,
            longBreakDurationMinutes: 15,
            workflowsBeforeLongBreak: 4
        )
        var runtime = DropletTimerRuntime(configuration: shortConfiguration)
        runtime.start()

        let result = runtime.advance(
            by: 75,
            configuration: shortConfiguration,
            autoStartNextSession: true
        )

        XCTAssertEqual(result.elapsedSeconds, 75)
        XCTAssertEqual(result.focusedSeconds, 60)
        XCTAssertEqual(result.completedModes, [.work])
        XCTAssertEqual(runtime.mode, .shortBreak)
        XCTAssertEqual(runtime.status, .running)
        XCTAssertEqual(runtime.remainingSeconds, 285)
        XCTAssertEqual(runtime.completedWorkflows, 1)
    }

    func testBulkAdvanceAutoStartCanCrossSeveralPhases() {
        let shortConfiguration = TimerConfiguration(
            workDurationMinutes: 1,
            shortBreakDurationMinutes: 1,
            longBreakDurationMinutes: 2,
            workflowsBeforeLongBreak: 2
        )
        var runtime = DropletTimerRuntime(configuration: shortConfiguration)
        runtime.start()

        let result = runtime.advance(
            by: 210,
            configuration: shortConfiguration,
            autoStartNextSession: true
        )

        XCTAssertEqual(result.elapsedSeconds, 210)
        XCTAssertEqual(result.focusedSeconds, 120)
        XCTAssertEqual(result.completedModes, [.work, .shortBreak, .work])
        XCTAssertEqual(runtime.mode, .longBreak)
        XCTAssertEqual(runtime.status, .running)
        XCTAssertEqual(runtime.remainingSeconds, 90)
        XCTAssertEqual(runtime.completedWorkflows, 0)
    }
}
