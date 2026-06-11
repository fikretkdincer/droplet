import SwiftUI

struct TaskListView: View {
    @ObservedObject var taskManager = TaskManager.shared
    @ObservedObject var settings = SettingsManager.shared
    @State private var showingArchived = false

    var body: some View {
        VStack(spacing: 12) {
            MacNavigationHeader(
                title: "Tasks",
                theme: settings.selectedTheme,
                backAction: { settings.navigateTo(.timer) },
                trailingSystemImage: showingArchived ? "archivebox.fill" : "archivebox",
                trailingAction: { showingArchived.toggle() }
            )
            .padding(.horizontal, -4)
            .help(showingArchived ? "Show Active" : "Show Archived")

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

            ScrollView {
                LazyVStack(spacing: 6) {
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

    private var tasksToShow: [WorkTask] {
        showingArchived ? taskManager.archivedTasks : taskManager.activeTasks
    }
}
