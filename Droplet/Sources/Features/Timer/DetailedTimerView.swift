import AppKit
import SwiftUI

struct DetailedTimerView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var taskManager = TaskManager.shared
    @ObservedObject var goalTracker = GoalTracker.shared
    @State private var pulseAnimation = false
    @State private var showingAddTask = false
    @State private var newTaskName = ""
    @State private var newTaskDuration: Int?

    private let durationOptions: [(String, Int?)] = [
        ("∞", nil), ("30m", 30), ("1h", 60), ("2h", 120), ("3h", 180), ("4h", 240)
    ]

    var body: some View {
        HStack(spacing: 0) {
            timerPane

            Rectangle()
                .fill(settings.selectedTheme.textColor.opacity(0.1))
                .frame(width: 1)
                .padding(.vertical, 16)

            detailPane
        }
        .onChange(of: viewModel.status) { newStatus in
            if newStatus == .pulsing {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            } else {
                pulseAnimation = false
            }
        }
    }

    private var timerPane: some View {
        VStack(spacing: 12) {
            Spacer()

            Text(viewModel.currentMode.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(viewModel.currentAccentColor.opacity(0.8))
                .textCase(.uppercase)

            Text(viewModel.formattedTime)
                .font(.custom("Avenir Next", size: 64))
                .fontWeight(MacTimerFontWeight.weight(for: settings.timerFontWeightRaw))
                .foregroundColor(settings.selectedTheme.textColor)
                .monospacedDigit()
                .opacity(viewModel.status == .pulsing ? (pulseAnimation ? 0.5 : 1.0) : 1.0)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .shadow(
                    color: settings.enableGlow ? viewModel.currentAccentColor.opacity(0.6) : .clear,
                    radius: settings.enableGlow ? 10 : 0
                )

            if viewModel.currentMode != .infinity {
                TimerProgressBar(
                    totalSeconds: viewModel.totalSecondsForCurrentMode,
                    remainingSeconds: viewModel.remainingSeconds,
                    color: viewModel.currentAccentColor,
                    backgroundColor: settings.selectedTheme.textColor.opacity(0.2)
                )
                .padding(.horizontal, 30)

                TimerWorkflowDots(
                    count: settings.workflowCount,
                    mode: viewModel.currentMode,
                    completedWorkflows: viewModel.completedWorkflows,
                    color: viewModel.currentAccentColor,
                    inactiveColor: settings.selectedTheme.textColor.opacity(0.3),
                    scale: 7.0 / 6.0
                )
            } else {
                TimerPillButton(
                    title: "End ∞",
                    color: viewModel.currentAccentColor,
                    scale: 1.1,
                    action: { settings.infinityMode = false }
                )
            }

            controls
            Spacer()

            if settings.showMusicControls {
                MusicControlsView()
                    .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    private var controls: some View {
        HStack(spacing: 20) {
            Button(action: { viewModel.resetCurrentMode() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.5))
            }
            .buttonStyle(.plain)

            Button(action: primaryTimerAction) {
                Image(systemName: viewModel.status == .running ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(viewModel.currentAccentColor)
            }
            .buttonStyle(.plain)

            if viewModel.isOnBreak {
                Button(action: { viewModel.skipBreak() }) {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 14))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.5))
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 14, height: 14)
            }
        }
    }

    private var detailPane: some View {
        VStack(spacing: 0) {
            taskSection

            Rectangle()
                .fill(settings.selectedTheme.textColor.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 12)

            dailyGoalSection
        }
        .frame(maxWidth: .infinity)
    }

    private var taskSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("Tasks")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.5))
                    .textCase(.uppercase)

                Button(action: toggleAddTask) {
                    Image(systemName: showingAddTask ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(showingAddTask ? settings.selectedTheme.textColor.opacity(0.5) : settings.selectedTheme.workAccent)
                }
                .buttonStyle(.plain)
                .help(showingAddTask ? "Cancel" : "Add Task")

                Spacer()
            }

            if showingAddTask {
                inlineAddTaskForm
            }

            ScrollView {
                LazyVStack(spacing: 4) {
                    if taskManager.activeTasks.isEmpty && !showingAddTask {
                        Text("No tasks")
                            .font(.system(size: 10))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.4))
                            .padding(.top, 8)
                    } else {
                        ForEach(taskManager.activeTasks) { task in
                            DetailedTaskRow(task: task, isActive: task.id == taskManager.activeTaskId)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }

    private var inlineAddTaskForm: some View {
        VStack(spacing: 8) {
            TextField("Task name", text: $newTaskName)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(settings.selectedTheme.textColor)
                .padding(6)
                .background(settings.selectedTheme.textColor.opacity(0.1))
                .cornerRadius(6)

            HStack(spacing: 4) {
                ForEach(durationOptions, id: \.1) { option in
                    Button(action: { newTaskDuration = option.1 }) {
                        Text(option.0)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(newTaskDuration == option.1 ? settings.selectedTheme.backgroundColor : settings.selectedTheme.textColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(newTaskDuration == option.1 ? settings.selectedTheme.workAccent : settings.selectedTheme.textColor.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Button(action: createTask) {
                Text("Create")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(trimmedTaskName.isEmpty ? settings.selectedTheme.textColor.opacity(0.4) : settings.selectedTheme.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(trimmedTaskName.isEmpty ? settings.selectedTheme.textColor.opacity(0.1) : settings.selectedTheme.workAccent)
                    )
            }
            .buttonStyle(.plain)
            .disabled(trimmedTaskName.isEmpty)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(settings.selectedTheme.textColor.opacity(0.05)))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var dailyGoalSection: some View {
        VStack(spacing: 6) {
            if goalTracker.hasGoalSet {
                let todayMinutes = goalTracker.getTodayMinutes()
                let goalMinutes = goalTracker.dailyGoalMinutes
                let progress = min(Double(todayMinutes) / Double(goalMinutes), 1)

                HStack {
                    Text("Daily Goal")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.5))
                        .textCase(.uppercase)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(progress >= 1 ? Color(hex: "4CAF50") : viewModel.currentAccentColor)
                }

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(settings.selectedTheme.textColor.opacity(0.15))
                        .frame(height: 6)
                    GeometryReader { barGeo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progress >= 1 ? Color(hex: "4CAF50") : viewModel.currentAccentColor)
                            .frame(width: barGeo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)

                Text("\(GoalTracker.formatMinutes(todayMinutes)) / \(GoalTracker.formatMinutes(goalMinutes))")
                    .font(.system(size: 10))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
            } else {
                Text("No goal set")
                    .font(.system(size: 10))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.4))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var trimmedTaskName: String {
        newTaskName.trimmingCharacters(in: .whitespaces)
    }

    private func primaryTimerAction() {
        if viewModel.status == .pulsing {
            viewModel.continueToNextPhase()
        } else {
            viewModel.toggleStartPause()
        }
    }

    private func toggleAddTask() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showingAddTask.toggle()
            if !showingAddTask {
                newTaskName = ""
                newTaskDuration = nil
            }
        }
    }

    private func createTask() {
        guard !trimmedTaskName.isEmpty else { return }
        taskManager.addTask(name: trimmedTaskName, targetMinutes: newTaskDuration)
        newTaskName = ""
        newTaskDuration = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            showingAddTask = false
        }
    }
}

struct DetailedTaskRow: View {
    let task: WorkTask
    let isActive: Bool

    @ObservedObject var taskManager = TaskManager.shared
    @ObservedObject var settings = SettingsManager.shared

    var body: some View {
        HStack(spacing: 6) {
            Button(action: { taskManager.setActiveTask(id: isActive ? nil : task.id) }) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundColor(isActive ? settings.selectedTheme.workAccent : settings.selectedTheme.textColor.opacity(0.4))
            }
            .buttonStyle(.plain)

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

            Button(action: { taskManager.archiveTask(id: task.id) }) {
                Image(systemName: "archivebox")
                    .font(.system(size: 10))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help("Archive")

            Button(action: { confirmDelete() }) {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundColor(.red.opacity(0.5))
            }
            .buttonStyle(.plain)
            .help("Delete")
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
        alert.informativeText = "Are you sure you want to delete \"\(task.name)\"?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            taskManager.deleteTask(id: task.id)
        }
    }
}
