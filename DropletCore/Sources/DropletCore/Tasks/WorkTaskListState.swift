import Foundation

public struct WorkTaskListState: Codable, Equatable, Sendable {
    public var tasks: [WorkTask]
    public var activeTaskID: UUID?

    public init(tasks: [WorkTask] = [], activeTaskID: UUID? = nil) {
        self.tasks = tasks
        self.activeTaskID = activeTaskID
    }

    public var activeTasks: [WorkTask] {
        tasks.filter { !$0.isArchived }
    }

    public var archivedTasks: [WorkTask] {
        tasks.filter(\.isArchived)
    }

    public var activeTask: WorkTask? {
        guard let activeTaskID else { return nil }
        return tasks.first { $0.id == activeTaskID && !$0.isArchived }
    }

    @discardableResult
    public mutating func addTask(name: String, targetMinutes: Int? = nil) -> WorkTask? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        let task = WorkTask(name: trimmedName, targetMinutes: targetMinutes)
        tasks.append(task)
        return task
    }

    public mutating func archiveTask(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isArchived = true
        if activeTaskID == id {
            activeTaskID = nil
        }
    }

    public mutating func unarchiveTask(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isArchived = false
    }

    public mutating func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        if activeTaskID == id {
            activeTaskID = nil
        }
    }

    public mutating func setActiveTask(id: UUID?) {
        guard let id else {
            activeTaskID = nil
            return
        }
        guard tasks.contains(where: { $0.id == id && !$0.isArchived }) else { return }
        activeTaskID = id
    }

    public mutating func recordMinute(for taskID: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[index].minutesWorked += 1
    }

    public mutating func recordMinuteForActiveTask() {
        recordMinutesForActiveTask(1)
    }

    public mutating func recordMinutesForActiveTask(_ minutes: Int) {
        guard minutes > 0 else { return }
        guard let activeTaskID else { return }
        guard let index = tasks.firstIndex(where: { $0.id == activeTaskID }) else { return }
        tasks[index].minutesWorked += minutes
    }
}
