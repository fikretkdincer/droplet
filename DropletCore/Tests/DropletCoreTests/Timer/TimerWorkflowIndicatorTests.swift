import XCTest
@testable import DropletCore

final class TimerWorkflowIndicatorTests: XCTestCase {
    func testWorkModeHighlightsCurrentWorkflowDot() {
        let indicator = TimerWorkflowIndicator(
            mode: .work,
            completedWorkflows: 1,
            workflowsBeforeLongBreak: 4
        )

        XCTAssertEqual(indicator.totalDots, 4)
        XCTAssertEqual(indicator.filledDots, 2)
    }

    func testBreakModesShowCompletedOrFullWorkflowDots() {
        XCTAssertEqual(
            TimerWorkflowIndicator(
                mode: .shortBreak,
                completedWorkflows: 2,
                workflowsBeforeLongBreak: 4
            ).filledDots,
            2
        )

        XCTAssertEqual(
            TimerWorkflowIndicator(
                mode: .longBreak,
                completedWorkflows: 0,
                workflowsBeforeLongBreak: 4
            ).filledDots,
            4
        )
    }

    func testInfinityModeDoesNotShowWorkflowDots() {
        let indicator = TimerWorkflowIndicator(
            mode: .infinity,
            completedWorkflows: 3,
            workflowsBeforeLongBreak: 4
        )

        XCTAssertEqual(indicator.totalDots, 0)
        XCTAssertEqual(indicator.filledDots, 0)
    }
}
