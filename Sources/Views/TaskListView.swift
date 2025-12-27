import SwiftUI

/// View for managing work tasks
struct TaskListView: View {
    @ObservedObject var taskManager = TaskManager.shared
    @ObservedObject var settings = SettingsManager.shared
    
    @State private var newTaskName: String = ""
    @State private var newTaskDuration: Int? = nil
    @State private var showingDurationPicker = false
    @State private var showingArchived = false
    
    let durationOptions: [(String, Int?)] = [
        ("Unlimited", nil),
        ("30 min", 30),
        ("1 hour", 60),
        ("2 hours", 120),
        ("3 hours", 180),
        ("4 hours", 240)
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Button(action: { settings.navigateTo(.timer) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Tasks")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(settings.selectedTheme.textColor)
                
                Spacer()
                
                // Archive toggle
                Button(action: { showingArchived.toggle() }) {
                    Image(systemName: showingArchived ? "archivebox.fill" : "archivebox")
                        .font(.system(size: 12))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(showingArchived ? "Show Active" : "Show Archived")
            }
            .padding(.horizontal, 8)
            
            // Add task button (only when showing active)
            if !showingArchived {
                Button(action: { settings.navigateTo(.addTask) }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add Task")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(settings.selectedTheme.workAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(settings.selectedTheme.workAccent.opacity(0.15))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
            }
            
            // Task list
            ScrollView {
                LazyVStack(spacing: 6) {
                    let tasksToShow = showingArchived ? taskManager.archivedTasks : taskManager.activeTasks
                    
                    if tasksToShow.isEmpty {
                        Text(showingArchived ? "No archived tasks" : "No tasks yet")
                            .font(.system(size: 11))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.5))
                            .padding(.top, 20)
                    } else {
                        ForEach(tasksToShow) { task in
                            TaskRowView(task: task, isActive: task.id == taskManager.activeTaskId)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(12)
    }
    
    private func durationLabel(_ minutes: Int?) -> String {
        guard let mins = minutes else { return "∞" }
        if mins >= 60 {
            return "\(mins / 60)h"
        }
        return "\(mins)m"
    }
    
    private func addTask() {
        let name = newTaskName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        taskManager.addTask(name: name, targetMinutes: newTaskDuration)
        newTaskName = ""
        newTaskDuration = nil
    }
    
    private func showAddTaskDialog() {
        let alert = NSAlert()
        alert.messageText = "Add New Task"
        alert.informativeText = "Enter a name for your task:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        
        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 250, height: 24))
        inputField.placeholderString = "e.g. Study for Math Exam"
        alert.accessoryView = inputField
        
        // Make the input field first responder
        alert.window.initialFirstResponder = inputField
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let taskName = inputField.stringValue.trimmingCharacters(in: .whitespaces)
            if !taskName.isEmpty {
                taskManager.addTask(name: taskName, targetMinutes: nil)
            }
        }
    }
}

/// Individual task row
struct TaskRowView: View {
    let task: WorkTask
    let isActive: Bool
    
    @ObservedObject var taskManager = TaskManager.shared
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            // Selection indicator / radio button
            Button(action: { toggleActive() }) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(isActive ? settings.selectedTheme.workAccent : settings.selectedTheme.textColor.opacity(0.4))
            }
            .buttonStyle(.plain)
            .disabled(task.isArchived)
            
            // Task info
            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                    .foregroundColor(settings.selectedTheme.textColor)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(formatMinutes(task.minutesWorked))
                        .font(.system(size: 9))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
                    
                    if let target = task.targetMinutes {
                        Text("/ \(formatMinutes(target))")
                            .font(.system(size: 9))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.4))
                    }
                }
            }
            
            Spacer()
            
            // Progress bar (for timed tasks)
            if let progress = task.progress {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(settings.selectedTheme.textColor.opacity(0.1))
                        .frame(width: 40, height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(task.isComplete ? Color.green : settings.selectedTheme.workAccent)
                        .frame(width: min(40, 40 * progress), height: 4)
                }
            }
            
            // Archive/Unarchive button
            Button(action: { toggleArchive() }) {
                Image(systemName: task.isArchived ? "arrow.uturn.backward" : "archivebox")
                    .font(.system(size: 14))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.5))
                    .padding(4)
            }
            .buttonStyle(.plain)
            .help(task.isArchived ? "Unarchive" : "Archive")
            
            // Delete button
            Button(action: { confirmDelete() }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.6))
                    .padding(4)
            }
            .buttonStyle(.plain)
            .help("Delete Task")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? settings.selectedTheme.workAccent.opacity(0.15) : settings.selectedTheme.textColor.opacity(0.05))
        )
    }
    
    private func confirmDelete() {
        let alert = NSAlert()
        alert.messageText = "Delete Task"
        alert.informativeText = "Are you sure you want to delete \"\(task.name)\"? This cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            taskManager.deleteTask(id: task.id)
        }
    }
    
    private func toggleActive() {
        if isActive {
            taskManager.setActiveTask(id: nil)
        } else {
            taskManager.setActiveTask(id: task.id)
        }
    }
    
    private func toggleArchive() {
        if task.isArchived {
            taskManager.unarchiveTask(id: task.id)
        } else {
            taskManager.archiveTask(id: task.id)
        }
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}

/// Dedicated view for adding a new task
struct AddTaskView: View {
    @ObservedObject var taskManager = TaskManager.shared
    @ObservedObject var settings = SettingsManager.shared
    
    @State private var taskName: String = ""
    @State private var selectedDuration: Int? = nil
    
    let durationOptions: [(String, Int?)] = [
        ("∞", nil),
        ("30m", 30),
        ("1h", 60),
        ("2h", 120),
        ("3h", 180),
        ("4h", 240),
        ("6h", 360),
        ("8h", 480)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Button(action: { settings.navigateTo(.taskList) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Add Task")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(settings.selectedTheme.textColor)
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear
                    .frame(width: 14, height: 14)
            }
            .padding(.horizontal,8)
            
            VStack(spacing: 12) {
                // Task name input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Task Name")
                        .font(.system(size: 10))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
                    
                    TextField("e.g. Study for Math Exam", text: $taskName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(settings.selectedTheme.textColor)
                        .padding(8)
                        .background(settings.selectedTheme.textColor.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // Duration picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Duration")
                        .font(.system(size: 10))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
                    
                    // First row: ∞, 30m, 1h, 2h
                    HStack(spacing: 6) {
                        ForEach(durationOptions.prefix(4), id: \.1) { option in
                            durationButton(option: option)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    // Second row: 3h, 4h, 6h, 8h
                    HStack(spacing: 6) {
                        ForEach(durationOptions.suffix(4), id: \.1) { option in
                            durationButton(option: option)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            
            
            
            // Create button
            Button(action: createTask) {
                Text("Create Task")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(taskName.trimmingCharacters(in: .whitespaces).isEmpty 
                        ? settings.selectedTheme.textColor.opacity(0.3)
                        : settings.selectedTheme.workAccent)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(taskName.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 8)
        }
        .padding(12)
    }
    
    @ViewBuilder
    private func durationButton(option: (String, Int?)) -> some View {
        Button(action: { selectedDuration = option.1 }) {
            Text(option.0)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(selectedDuration == option.1 ? Color.black : settings.selectedTheme.textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedDuration == option.1 ? settings.selectedTheme.workAccent : settings.selectedTheme.textColor.opacity(0.1))
                .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func createTask() {
        let name = taskName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        taskManager.addTask(name: name, targetMinutes: selectedDuration)
        settings.navigateTo(.taskList)
    }
}
