import XCTest
@testable import DropletCore

final class DropletCoreTests: XCTestCase {
    func testTimerConfigurationCalculatesDurationsAndTransitions() {
        let configuration = TimerConfiguration(
            workDurationMinutes: 25,
            shortBreakDurationMinutes: 5,
            longBreakDurationMinutes: 15,
            workflowsBeforeLongBreak: 4
        )

        XCTAssertEqual(configuration.totalSeconds(for: .work), 1_500)
        XCTAssertEqual(configuration.totalSeconds(for: .shortBreak), 300)
        XCTAssertEqual(configuration.totalSeconds(for: .longBreak), 900)
        XCTAssertEqual(configuration.totalSeconds(for: .infinity), 0)

        XCTAssertEqual(
            configuration.nextPhase(after: .work, completedWorkflows: 0),
            TimerPhase(mode: .shortBreak, completedWorkflows: 1)
        )
        XCTAssertEqual(
            configuration.nextPhase(after: .work, completedWorkflows: 3),
            TimerPhase(mode: .longBreak, completedWorkflows: 0)
        )
        XCTAssertEqual(
            configuration.nextPhase(after: .shortBreak, completedWorkflows: 2),
            TimerPhase(mode: .work, completedWorkflows: 2)
        )
        XCTAssertEqual(
            configuration.nextPhase(after: .infinity, completedWorkflows: 2),
            TimerPhase(mode: .infinity, completedWorkflows: 2)
        )
    }

    func testFocusHistoryRecordsMinutesByCalendarDay() throws {
        let calendar = Calendar.gregorianUTC
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29, hour: 23)))
        var history = FocusHistory()

        XCTAssertEqual(FocusHistory.dayKey(for: date, calendar: calendar), "2026-05-29")
        history.record(minutes: 25, on: date, calendar: calendar)
        history.record(minutes: 10, on: date, calendar: calendar)

        XCTAssertEqual(history.minutes(on: date, calendar: calendar), 35)
        XCTAssertEqual(history.minutesByDay, ["2026-05-29": 35])
    }

    func testGoalProgressReportsHighestNewMilestone() {
        let progress = GoalProgress(dailyGoalMinutes: 100, minutesWorked: 130)

        XCTAssertEqual(progress.percent, 130)
        XCTAssertEqual(progress.ratio, 1.3)
        XCTAssertEqual(
            progress.highestCrossedMilestone(
                previousMinutes: 95,
                milestones: [25, 50, 75, 100, 125]
            ),
            125
        )
        XCTAssertNil(
            GoalProgress(dailyGoalMinutes: 0, minutesWorked: 130)
                .highestCrossedMilestone(previousMinutes: 95)
        )
    }

    func testWorkTaskProgressAndCompletion() {
        let task = WorkTask(
            id: UUID(uuidString: "0F8B37F0-B235-40F9-8FD3-E5CE7B2F3A10")!,
            name: "Core extraction",
            targetMinutes: 40,
            minutesWorked: 45,
            isArchived: false,
            createdAt: Date(timeIntervalSince1970: 1_779_984_000)
        )

        XCTAssertEqual(task.progress, 1.125)
        XCTAssertTrue(task.isComplete)
    }

    func testFocusSessionCalculatesDurationForSyncRecords() {
        let startDate = Date(timeIntervalSince1970: 1_779_984_000)
        let endDate = startDate.addingTimeInterval(1_510)
        let session = FocusSession(
            id: UUID(uuidString: "F38712B4-E805-4A62-8259-5656F34F56D8")!,
            mode: .work,
            source: .mac,
            startDate: startDate,
            endDate: endDate,
            taskID: UUID(uuidString: "7ACFB9DC-756C-4970-9758-9078A914DA4B"),
            note: "Extracted core"
        )

        XCTAssertEqual(session.durationSeconds, 1_510)
        XCTAssertEqual(session.wholeMinutes, 25)
        XCTAssertEqual(session.mode, .work)
        XCTAssertEqual(session.source, .mac)
    }

    func testGeneratedNoisePresetsKeepExistingLabelsAndRelativeGains() {
        XCTAssertEqual(GeneratedNoise.allCases.map(\.rawValue), [
            "White Noise",
            "Pink Noise",
            "Brown Noise",
            "Green Noise",
            "Blue Noise",
            "Violet Noise"
        ])

        XCTAssertGreaterThan(GeneratedNoise.brown.outputGain, GeneratedNoise.white.outputGain)
        XCTAssertLessThan(GeneratedNoise.violet.outputGain, GeneratedNoise.blue.outputGain)
    }
}

private extension Calendar {
    static var gregorianUTC: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
