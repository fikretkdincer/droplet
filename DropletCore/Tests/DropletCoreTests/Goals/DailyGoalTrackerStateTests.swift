import XCTest
@testable import DropletCore

final class DailyGoalTrackerStateTests: XCTestCase {
    func testDailyGoalSetupMatchesMacHourLogic() {
        var state = DailyGoalTrackerState()

        XCTAssertFalse(state.hasGoalSet)

        state.setDailyGoal(hours: 1.5)

        XCTAssertTrue(state.hasGoalSet)
        XCTAssertEqual(state.dailyGoalMinutes, 90)
    }

    func testRecordingWorkSessionAccumulatesByDayAndTracksMilestones() throws {
        let calendar = Calendar.gregorianUTC
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 30)))
        var state = DailyGoalTrackerState(dailyGoalMinutes: 100)

        XCTAssertEqual(state.recordWorkSession(minutes: 24, on: date, calendar: calendar), nil)
        XCTAssertEqual(state.recordWorkSession(minutes: 1, on: date, calendar: calendar), 25)
        XCTAssertEqual(state.recordWorkSession(minutes: 75, on: date, calendar: calendar), 100)
        XCTAssertEqual(state.recordWorkSession(minutes: 25, on: date, calendar: calendar), 125)
        XCTAssertEqual(state.recordWorkSession(minutes: 1, on: date, calendar: calendar), nil)

        XCTAssertEqual(state.getTodayMinutes(date: date, calendar: calendar), 126)
        XCTAssertEqual(state.getTodayProgress(date: date, calendar: calendar), 1.26)
        XCTAssertEqual(state.workHistory["2026-05-30"], 126)
    }

    func testWeekDataStartsOnMondayAndKeepsSevenFixedRecords() throws {
        let calendar = Calendar.gregorianUTC
        let monday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 25)))
        let saturday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 30)))
        let state = DailyGoalTrackerState(
            dailyGoalMinutes: 60,
            workHistory: [
                "2026-05-25": 30,
                "2026-05-30": 90
            ]
        )

        let records = state.getWeekData(containing: saturday, calendar: calendar)

        XCTAssertEqual(records.count, 7)
        XCTAssertEqual(records.first?.key, FocusHistory.dayKey(for: monday, calendar: calendar))
        XCTAssertEqual(records.map(\.minutes), [30, 0, 0, 0, 0, 90, 0])
    }

    func testFormatsMinutesLikeMacGoalTracker() {
        XCTAssertEqual(DailyGoalTrackerState.formatMinutes(25), "25m")
        XCTAssertEqual(DailyGoalTrackerState.formatMinutes(60), "1h")
        XCTAssertEqual(DailyGoalTrackerState.formatMinutes(95), "1h 35m")
    }
}

private extension Calendar {
    static var gregorianUTC: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
