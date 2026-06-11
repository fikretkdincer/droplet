import XCTest
@testable import DropletCore

final class GoalProgressTests: XCTestCase {
    func testDisplayProgressCapsRatioAndRemainingMinutes() {
        let inProgress = GoalProgress(dailyGoalMinutes: 90, minutesWorked: 25)
        let complete = GoalProgress(dailyGoalMinutes: 90, minutesWorked: 125)
        let noGoal = GoalProgress(dailyGoalMinutes: 0, minutesWorked: 25)

        XCTAssertEqual(inProgress.visualRatio, 25.0 / 90.0, accuracy: 0.001)
        XCTAssertEqual(inProgress.remainingMinutes, 65)
        XCTAssertFalse(inProgress.isComplete)

        XCTAssertEqual(complete.visualRatio, 1, accuracy: 0.001)
        XCTAssertEqual(complete.remainingMinutes, 0)
        XCTAssertTrue(complete.isComplete)

        XCTAssertEqual(noGoal.visualRatio, 0, accuracy: 0.001)
        XCTAssertEqual(noGoal.remainingMinutes, 0)
        XCTAssertFalse(noGoal.isComplete)
    }
}
