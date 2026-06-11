import Foundation

/// Manages work tasks with persistence
class TaskManager: ObservableObject {
    static let shared = TaskManager()

    @Published var tasks: [WorkTask] = []
    @Published var activeTaskId: UUID? = nil

    private let tasksKey = "workTasks"
    private let activeTaskKey = "activeTaskId"

    private init() {
        loadData()
    }

    // MARK: - Computed Properties

    /// Non-archived tasks
    var activeTasks: [WorkTask] {
        tasks.filter { !$0.isArchived }
    }

    /// Archived tasks
    var archivedTasks: [WorkTask] {
        tasks.filter { $0.isArchived }
    }

    /// Currently active task (if any)
    var activeTask: WorkTask? {
        guard let id = activeTaskId else { return nil }
        return tasks.first { $0.id == id }
    }

    // MARK: - CRUD Operations

    @discardableResult
    func addTask(name: String, targetMinutes: Int? = nil) -> WorkTask {
        let task = WorkTask(name: name, targetMinutes: targetMinutes)
        tasks.append(task)
        saveData()
        return task
    }

    func archiveTask(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].isArchived = true
            // If this was the active task, clear it
            if activeTaskId == id {
                activeTaskId = nil
            }
            saveData()
        }
    }

    func unarchiveTask(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].isArchived = false
            saveData()
        }
    }

    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        if activeTaskId == id {
            activeTaskId = nil
        }
        saveData()
    }

    func setActiveTask(id: UUID?) {
        activeTaskId = id
        saveData()
    }

    /// Record one minute of work for a task
    func recordMinute(for taskId: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].minutesWorked += 1
            saveData()
        }
    }

    /// Record minutes for the currently active task (if any)
    func recordMinuteForActiveTask() {
        guard let taskId = activeTaskId else { return }
        recordMinute(for: taskId)
    }

    // MARK: - Persistence

    private func loadData() {
        // Load tasks
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([WorkTask].self, from: data) {
            tasks = decoded
        }

        // Load active task ID
        if let idString = UserDefaults.standard.string(forKey: activeTaskKey) {
            activeTaskId = UUID(uuidString: idString)
        }
    }

    private func saveData() {
        // Save tasks
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: tasksKey)
        }

        // Save active task ID
        if let id = activeTaskId {
            UserDefaults.standard.set(id.uuidString, forKey: activeTaskKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeTaskKey)
        }
    }
}
