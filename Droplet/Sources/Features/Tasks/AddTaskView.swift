import SwiftUI

struct AddTaskView: View {
    @ObservedObject var taskManager = TaskManager.shared
    @ObservedObject var settings = SettingsManager.shared

    @State private var taskName = ""
    @State private var selectedDuration: Int?

    private let durationOptions: [(String, Int?)] = [
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
            MacNavigationHeader(
                title: "Add Task",
                theme: settings.selectedTheme,
                backAction: { settings.navigateTo(.taskList) }
            )
            .padding(.horizontal, -4)

            VStack(spacing: 12) {
                taskNameField
                durationPicker
            }
            .padding(.horizontal, 8)

            Button(action: createTask) {
                Text("Create Task")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(trimmedTaskName.isEmpty ? settings.selectedTheme.textColor.opacity(0.3) : settings.selectedTheme.workAccent)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(trimmedTaskName.isEmpty)
            .padding(.horizontal, 8)
        }
        .padding(12)
    }

    private var taskNameField: some View {
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
    }

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Duration")
                .font(.system(size: 10))
                .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))

            HStack(spacing: 6) {
                ForEach(durationOptions.prefix(4), id: \.1) { option in
                    durationButton(option: option)
                        .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 6) {
                ForEach(durationOptions.suffix(4), id: \.1) { option in
                    durationButton(option: option)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

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
        .buttonStyle(.plain)
    }

    private var trimmedTaskName: String {
        taskName.trimmingCharacters(in: .whitespaces)
    }

    private func createTask() {
        guard !trimmedTaskName.isEmpty else { return }
        taskManager.addTask(name: trimmedTaskName, targetMinutes: selectedDuration)
        settings.navigateTo(.taskList)
    }
}
