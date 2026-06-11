import XCTest
@testable import DropletCore

final class DistractionBlockingPolicyTests: XCTestCase {
    func testDisabledBlockingNeverShields() {
        XCTAssertNil(
            DistractionBlockingPolicy.shieldContext(
                isEnabled: false,
                flowIsActive: true,
                mode: .work,
                status: .running
            )
        )
    }

    func testInitialIdleFocusStaysOpenUntilFlowStarts() {
        XCTAssertNil(
            DistractionBlockingPolicy.shieldContext(
                isEnabled: true,
                flowIsActive: false,
                mode: .work,
                status: .idle
            )
        )
    }

    func testRunningFocusIsShielded() {
        XCTAssertEqual(
            DistractionBlockingPolicy.shieldContext(
                isEnabled: true,
                flowIsActive: true,
                mode: .work,
                status: .running
            ),
            .focus
        )
    }

    func testPausedFocusUsesTerminationPrompt() {
        XCTAssertEqual(
            DistractionBlockingPolicy.shieldContext(
                isEnabled: true,
                flowIsActive: true,
                mode: .work,
                status: .paused
            ),
            .pausedFocus
        )
    }

    func testBreakStaysOpenWhileFlowIsActive() {
        XCTAssertNil(
            DistractionBlockingPolicy.shieldContext(
                isEnabled: true,
                flowIsActive: true,
                mode: .shortBreak,
                status: .running
            )
        )
    }

    func testWaitingFocusAfterBreakUsesReturnPrompt() {
        XCTAssertEqual(
            DistractionBlockingPolicy.shieldContext(
                isEnabled: true,
                flowIsActive: true,
                mode: .work,
                status: .idle
            ),
            .breakComplete
        )
    }

    func testInfinityFlowMatchesFiniteFocusBehavior() {
        XCTAssertEqual(
            DistractionBlockingPolicy.shieldContext(
                isEnabled: true,
                flowIsActive: true,
                mode: .infinity,
                status: .paused
            ),
            .pausedFocus
        )
    }
}
