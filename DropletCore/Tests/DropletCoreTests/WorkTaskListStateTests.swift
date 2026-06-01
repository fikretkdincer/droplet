import XCTest
@testable import DropletCore

final class WorkTaskListStateTests: XCTestCase {
    func testTaskLifecycleSupportsActiveArchiveUnarchiveAndDelete() throws {
        var state = WorkTaskListState()
        let task = try XCTUnwrap(state.addTask(name: "Write release notes", targetMinutes: 60))

        state.setActiveTask(id: task.id)
        XCTAssertEqual(state.activeTask?.id, task.id)

        state.archiveTask(id: task.id)
        XCTAssertNil(state.activeTask)
        XCTAssertEqual(state.activeTasks.count, 0)
        XCTAssertEqual(state.archivedTasks.map(\.id), [task.id])

        state.unarchiveTask(id: task.id)
        XCTAssertEqual(state.activeTasks.map(\.id), [task.id])

        state.deleteTask(id: task.id)
        XCTAssertTrue(state.tasks.isEmpty)
    }

    func testRecordingMinuteOnlyUpdatesSelectedTask() throws {
        var state = WorkTaskListState()
        let selectedTask = try XCTUnwrap(state.addTask(name: "Deep work"))
        let otherTask = try XCTUnwrap(state.addTask(name: "Admin"))
        state.setActiveTask(id: selectedTask.id)

        state.recordMinuteForActiveTask()

        XCTAssertEqual(state.tasks.first(where: { $0.id == selectedTask.id })?.minutesWorked, 1)
        XCTAssertEqual(state.tasks.first(where: { $0.id == otherTask.id })?.minutesWorked, 0)
    }

    func testBlankTaskNamesAreNotAdded() {
        var state = WorkTaskListState()

        let task = state.addTask(name: "   ")

        XCTAssertNil(task)
        XCTAssertTrue(state.tasks.isEmpty)
    }
}
