import AppKit
import SwiftUI

struct TaskRowView: View {
    let task: WorkTask
    let isActive: Bool

    @ObservedObject var taskManager = TaskManager.shared
    @ObservedObject var settings = SettingsManager.shared

    var body: some View {
        HStack(spacing: 8) {
            Button(action: toggleActive) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(isActive ? settings.selectedTheme.workAccent : settings.selectedTheme.textColor.opacity(0.4))
            }
            .buttonStyle(.plain)
            .disabled(task.isArchived)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                    .foregroundColor(settings.selectedTheme.textColor)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(GoalTracker.formatMinutes(task.minutesWorked))
                        .font(.system(size: 9))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))

                    if let target = task.targetMinutes {
                        Text("/ \(GoalTracker.formatMinutes(target))")
                            .font(.system(size: 9))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.4))
                    }
                }
            }

            Spacer()

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

            Button(action: toggleArchive) {
                Image(systemName: task.isArchived ? "arrow.uturn.backward" : "archivebox")
                    .font(.system(size: 14))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.5))
                    .padding(4)
            }
            .buttonStyle(.plain)
            .help(task.isArchived ? "Unarchive" : "Archive")

            Button(action: confirmDelete) {
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
        taskManager.setActiveTask(id: isActive ? nil : task.id)
    }

    private func toggleArchive() {
        if task.isArchived {
            taskManager.unarchiveTask(id: task.id)
        } else {
            taskManager.archiveTask(id: task.id)
        }
    }
}
