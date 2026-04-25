import SwiftUI

/// Main timer display view
struct TimerView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @ObservedObject var settings = SettingsManager.shared
    
    @State private var pulseAnimation = false
    @State private var isFullscreen = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with glassmorphism effect
                RoundedRectangle(cornerRadius: 12)
                    .fill(settings.selectedTheme.backgroundColor.opacity(0.95))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                // Content based on current view
                switch settings.currentView {
                case .timer:
                    if settings.miniFloaterMode {
                        MiniTimerView(viewModel: viewModel)
                    } else if settings.detailedView {
                        DetailedTimerView(viewModel: viewModel)
                    } else {
                        timerContent(geometry: geometry)
                    }
                case .weeklyProgress:
                    InAppWeeklyProgressView()
                case .goalSetup:
                    InAppGoalSetupView()
                case .taskList:
                    TaskListView()
                case .addTask:
                    AddTaskView()
                case .settings:
                    SettingsView()
                }
                
                // Top buttons (fullscreen left, settings right - only on timer view, not mini mode)
                if settings.currentView == .timer && !settings.miniFloaterMode {
                    VStack {
                        HStack {
                            // Fullscreen button (left)
                            Button(action: {
                                SettingsManager.mainWindow?.toggleFullScreen(nil)
                            }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                            .padding(10)
                            
                            Spacer()
                            
                            // Settings button (right)
                            Button(action: { settings.navigateTo(.settings) }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                            .padding(10)
                        }
                        Spacer()
                    }
                }
            }
        }
        .clipShape(settings.miniFloaterMode ? AnyShape(Capsule()) : AnyShape(RoundedRectangle(cornerRadius: 12)))
        .frame(
            minWidth: settings.miniFloaterMode ? 90 : 140,
            minHeight: settings.miniFloaterMode ? 32 : 100
        )
        .gesture(settings.currentView == .timer && settings.enableClickActions ? 
            TapGesture(count: 2).onEnded { viewModel.resetCurrentMode() } : nil
        )
        .gesture(settings.currentView == .timer && settings.enableClickActions ?
            TapGesture(count: 1).onEnded {
                if viewModel.status == .pulsing {
                    viewModel.continueToNextPhase()
                } else {
                    viewModel.toggleStartPause()
                }
            } : nil
        )
        .overlay(
            // Native right-click handler using NSViewRepresentable
            RightClickHandler(viewModel: viewModel, settings: settings)
                .allowsHitTesting(true)
        )
        .onAppear {
            startPulseAnimationIfNeeded()
            checkFullscreenState()
        }
        .onChange(of: viewModel.status) { newStatus in
            if newStatus == .pulsing {
                startPulseAnimation()
            } else {
                pulseAnimation = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
            isFullscreen = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
            isFullscreen = false
        }
    }
    
    private func checkFullscreenState() {
        if let window = SettingsManager.mainWindow {
            isFullscreen = window.styleMask.contains(.fullScreen)
        }
    }
    
    private var currentFontSize: Double {
        isFullscreen ? settings.fullscreenFontSize : settings.timerFontSize
    }
    
    /// Scale factor for UI elements in fullscreen (based on font size ratio)
    private var fullscreenScale: CGFloat {
        isFullscreen ? CGFloat(settings.fullscreenFontSize / settings.timerFontSize) : 1.0
    }
    
    /// Convert font weight string to Font.Weight
    private var currentFontWeight: Font.Weight {
        switch settings.timerFontWeightRaw {
        case "Thin": return .thin
        case "Light": return .light
        case "Regular": return .regular
        case "Medium": return .medium
        case "DemiBold": return .semibold
        case "Bold": return .bold
        default: return .medium
        }
    }
    
    private func startPulseAnimationIfNeeded() {
        if viewModel.status == .pulsing {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
    
    @ViewBuilder
    private func timerContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            // Active task display (above timer)
            if let activeTask = TaskManager.shared.activeTask {
                Button(action: { settings.navigateTo(.taskList) }) {
                    Text(activeTask.name)
                        .font(.system(size: taskNameFontSize(for: activeTask.name, width: geometry.size.width) * fullscreenScale))
                        .fontWeight(.medium)
                        .foregroundColor(settings.selectedTheme.workAccent)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .buttonStyle(.plain)
                .padding(.bottom, isFullscreen ? 16 : 4)
            }
            
            // Timer display with optional control buttons
            HStack(spacing: 6) {
                // Play/Pause button (left)
                if settings.showTimerControls {
                    Button(action: {
                        if viewModel.status == .pulsing {
                            viewModel.continueToNextPhase()
                        } else {
                            viewModel.toggleStartPause()
                        }
                    }) {
                        Image(systemName: viewModel.status == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 12 * fullscreenScale))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                
                // Timer text
                Text(viewModel.formattedTime)
                    .font(.custom("Avenir Next", size: currentFontSize))
                    .fontWeight(currentFontWeight)
                    .foregroundColor(settings.selectedTheme.textColor)
                    .monospacedDigit()
                    .opacity(viewModel.status == .pulsing ? (pulseAnimation ? 0.5 : 1.0) : 1.0)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .layoutPriority(1)
                    .shadow(
                        color: settings.enableGlow ? viewModel.currentAccentColor.opacity(0.6) : .clear,
                        radius: settings.enableGlow ? 8 : 0
                    )
                
                // Reset button (right)
                if settings.showTimerControls {
                    Button(action: {
                        viewModel.resetCurrentMode()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12 * fullscreenScale))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Progress bar (hidden in infinity mode)
            if settings.showProgressBar && geometry.size.width >= 100 && viewModel.currentMode != .infinity {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(settings.selectedTheme.textColor.opacity(0.2))
                        .frame(height: 4)
                    
                    GeometryReader { barProxy in
                        let totalBarWidth = barProxy.size.width
                        let totalSeconds = Double(viewModel.totalSecondsForCurrentMode)
                        let widthPerTick = totalSeconds > 0 ? (totalBarWidth / totalSeconds) : 0
                        let elapsedSeconds = Double(totalSeconds - Double(viewModel.remainingSeconds))
                        let currentWidth = min(max(elapsedSeconds * widthPerTick, 0), totalBarWidth)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(viewModel.currentAccentColor)
                            .frame(width: currentWidth, height: 4)
                            .animation(.linear(duration: 1), value: currentWidth)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
            }
            
            // Workflow counter (hidden in infinity mode)
            if viewModel.currentMode != .infinity {
                HStack(spacing: 4 * fullscreenScale) {
                    ForEach(0..<settings.workflowCount, id: \.self) { index in
                        let isHighlighted = viewModel.currentMode == .longBreak ||
                            (viewModel.currentMode == .work && index <= viewModel.completedWorkflows) ||
                            (viewModel.currentMode != .work && index < viewModel.completedWorkflows)
                        Circle()
                            .fill(isHighlighted ? viewModel.currentAccentColor : settings.selectedTheme.textColor.opacity(0.3))
                            .frame(width: 6 * fullscreenScale, height: 6 * fullscreenScale)
                    }
                }
                .padding(.top, isFullscreen ? 16 : 4)
            } else {
                // End infinity mode button
                Button(action: {
                    settings.infinityMode = false
                }) {
                    HStack(spacing: 4 * fullscreenScale) {
                        Text("End ∞")
                            .font(.system(size: 10 * fullscreenScale, weight: .medium))
                    }
                    .foregroundColor(viewModel.currentAccentColor)
                    .padding(.horizontal, 10 * fullscreenScale)
                    .padding(.vertical, 4 * fullscreenScale)
                    .background(
                        RoundedRectangle(cornerRadius: 6 * fullscreenScale)
                            .fill(viewModel.currentAccentColor.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, isFullscreen ? 16 : 4)
            }
            
            // Skip Break button (only visible during breaks)
            if viewModel.isOnBreak && geometry.size.height >= 120 {
                Button(action: { viewModel.skipBreak() }) {
                    HStack(spacing: 4 * fullscreenScale) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 9 * fullscreenScale))
                        Text("Skip")
                            .font(.system(size: 10 * fullscreenScale, weight: .medium))
                    }
                    .foregroundColor(settings.selectedTheme.breakAccent)
                    .padding(.horizontal, 10 * fullscreenScale)
                    .padding(.vertical, 4 * fullscreenScale)
                    .background(
                        RoundedRectangle(cornerRadius: 6 * fullscreenScale)
                            .fill(settings.selectedTheme.breakAccent.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, isFullscreen ? 16 : 4)
            }
            
            // Music controls
            if settings.showMusicControls && geometry.size.height >= 140 && geometry.size.width >= 200 {
                MusicControlsView(isFullscreen: isFullscreen, scale: fullscreenScale)
                    .padding(.top, isFullscreen ? 24 : 6)
                    .frame(maxWidth: geometry.size.width - 32)
            }
        }
        .padding(16)
    }
    
    /// Calculate font size for task name based on text length and available width
    private func taskNameFontSize(for text: String, width: CGFloat) -> CGFloat {
        let baseSize: CGFloat = 14
        let minSize: CGFloat = 9
        
        // Shorter names get larger fonts, longer names get smaller
        let charCount = text.count
        if charCount <= 10 {
            return baseSize
        } else if charCount <= 20 {
            return 12
        } else if charCount <= 30 {
            return 10
        } else {
            return minSize
        }
    }
}

/// Compact view for Mini-Floater Mode
struct MiniTimerView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        Text(viewModel.formattedTime)
            .font(.custom("Avenir Next", size: 18))
            .fontWeight(.bold)
            .foregroundColor(settings.selectedTheme.textColor)
            .monospacedDigit()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(minWidth: 90, minHeight: 32)
            .background(settings.selectedTheme.backgroundColor)
            .onTapGesture {
                viewModel.toggleStartPause()
            }
    }
}

/// In-app Weekly Progress View with back button
struct InAppWeeklyProgressView: View {
    @ObservedObject var goalTracker = GoalTracker.shared
    @ObservedObject var settings = SettingsManager.shared
    @State private var weekOffset: Int = 0
    @State private var hoveredDay: Date? = nil

    var body: some View {
        VStack(spacing: 12) {
            // Header with back button
            HStack {
                Button(action: { settings.navigateTo(.timer) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Goal Tracker")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(settings.selectedTheme.textColor)
                
                Spacer()
                
                Button(action: { settings.navigateTo(.goalSetup) }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            
            // Week navigation
            HStack {
                Button(action: { weekOffset -= 1 }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
                
                Spacer()
                
                Text(goalTracker.getWeekRangeString(weekOffset: weekOffset))
                    .font(.system(size: 11))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.8))
                
                Spacer()
                
                Button(action: { weekOffset += 1 }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(settings.selectedTheme.textColor.opacity(weekOffset >= 0 ? 0.2 : 0.6))
                .disabled(weekOffset >= 0)
            }
            .padding(.horizontal, 16)
            
            // Bar chart
            let weekData = goalTracker.getWeekData(weekOffset: weekOffset)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(weekData.enumerated()), id: \.offset) { _, day in
                    let progress = goalTracker.dailyGoalMinutes > 0
                        ? Double(day.minutes) / Double(goalTracker.dailyGoalMinutes)
                        : 0
                    let barColor: Color = progress >= 1.25 ? Color(hex: "FFD700") :
                                          progress >= 1.0 ? Color(hex: "4CAF50") :
                                          settings.selectedTheme.workAccent
                    let isHovered = hoveredDay == day.date

                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(barColor)
                            .frame(width: 24, height: max(4, min(CGFloat(progress) * 60, 80)))
                            .shadow(color: progress >= 1.25 ? barColor.opacity(0.6) : .clear, radius: progress >= 1.25 ? 4 : 0)
                            .opacity(isHovered ? 0.7 : 1.0)

                        Text(day.dayName.prefix(1))
                            .font(.system(size: 8))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.5))
                    }
                    .onHover { hovering in
                        hoveredDay = hovering ? day.date : nil
                    }
                }
            }
            .frame(height: 90)
            .padding(.horizontal, 8)

            // Hovered day info or today's summary
            if let hovered = hoveredDay,
               let day = weekData.first(where: { $0.date == hovered }) {
                Text(dayTooltip(date: day.date, minutes: day.minutes))
                    .font(.system(size: 10))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.8))
                    .transition(.opacity)
            } else if goalTracker.hasGoalSet {
                let progress = goalTracker.getTodayProgress()
                Text("Today: \(GoalTracker.formatMinutes(goalTracker.getTodayMinutes())) / \(GoalTracker.formatMinutes(goalTracker.dailyGoalMinutes)) (\(Int(progress * 100))%)")
                    .font(.system(size: 10))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
            }
        }
        .padding(12)
    }

    private func dayTooltip(date: Date, minutes: Int) -> String {
        let df = DateFormatter()
        df.dateFormat = "yy.MM.dd"
        let dateStr = df.string(from: date)
        let hours = minutes / 60
        let mins = minutes % 60
        if minutes == 0 {
            return "\(dateStr) — No work"
        } else if hours > 0 && mins > 0 {
            return "\(dateStr) — \(hours) hour\(hours == 1 ? "" : "s") \(mins) min"
        } else if hours > 0 {
            return "\(dateStr) — \(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(dateStr) — \(mins) min"
        }
    }
}

/// In-app Goal Setup View with back button
struct InAppGoalSetupView: View {
    @ObservedObject var goalTracker = GoalTracker.shared
    @ObservedObject var settings = SettingsManager.shared
    @State private var selectedIndex: Int = 5
    
    let hourLabels = ["30m", "1h", "1.5h", "2h", "3h", "4h", "5h", "6h", "8h"]
    let hourValues: [Double] = [0.5, 1, 1.5, 2, 3, 4, 5, 6, 8]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with back button
            HStack {
                Button(action: { 
                    if goalTracker.hasGoalSet {
                        settings.navigateTo(.weeklyProgress)
                    } else {
                        settings.navigateTo(.timer)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Set Daily Goal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(settings.selectedTheme.textColor)
                
                Spacer()
                
                // Placeholder for balance
                Image(systemName: "chevron.left")
                    .font(.system(size: 14))
                    .opacity(0)
            }
            .padding(.horizontal, 8)
            
            Text("How many hours per day?")
                .font(.system(size: 11))
                .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
            
            // Hour picker grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                ForEach(0..<hourLabels.count, id: \.self) { index in
                    Button(action: { selectedIndex = index }) {
                        Text(hourLabels[index])
                            .font(.system(size: 12, weight: selectedIndex == index ? .bold : .regular))
                            .foregroundColor(selectedIndex == index ? settings.selectedTheme.backgroundColor : settings.selectedTheme.textColor)
                            .frame(width: 40, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedIndex == index ? settings.selectedTheme.workAccent : settings.selectedTheme.textColor.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            
            // Save button
            Button(action: {
                goalTracker.setDailyGoal(hours: hourValues[selectedIndex])
                settings.navigateTo(.weeklyProgress)
            }) {
                Text("Save")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(settings.selectedTheme.backgroundColor)
                    .frame(width: 80, height: 28)
                    .background(settings.selectedTheme.workAccent)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .onAppear {
            if goalTracker.hasGoalSet {
                let currentHours = Double(goalTracker.dailyGoalMinutes) / 60.0
                if let index = hourValues.firstIndex(where: { abs($0 - currentHours) < 0.1 }) {
                    selectedIndex = index
                }
            }
        }
    }
}


/// Detailed view with timer on left, tasks + goal on right
struct DetailedTimerView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var taskManager = TaskManager.shared
    @ObservedObject var goalTracker = GoalTracker.shared
    @State private var pulseAnimation = false
    @State private var showingAddTask = false
    @State private var newTaskName = ""
    @State private var newTaskDuration: Int? = nil

    private let durationOptions: [(String, Int?)] = [
        ("∞", nil), ("30m", 30), ("1h", 60), ("2h", 120), ("3h", 180), ("4h", 240)
    ]

    var body: some View {
        HStack(spacing: 0) {
            // Left 2/3: Timer
            VStack(spacing: 12) {
                Spacer()

                // Mode label
                Text(viewModel.currentMode.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(viewModel.currentAccentColor.opacity(0.8))
                    .textCase(.uppercase)

                // Timer display
                Text(viewModel.formattedTime)
                    .font(.custom("Avenir Next", size: 64))
                    .fontWeight(timerFontWeight)
                    .foregroundColor(settings.selectedTheme.textColor)
                    .monospacedDigit()
                    .opacity(viewModel.status == .pulsing ? (pulseAnimation ? 0.5 : 1.0) : 1.0)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .shadow(
                        color: settings.enableGlow ? viewModel.currentAccentColor.opacity(0.6) : .clear,
                        radius: settings.enableGlow ? 10 : 0
                    )

                // Progress bar (hidden in infinity mode)
                if viewModel.currentMode != .infinity {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(settings.selectedTheme.textColor.opacity(0.2))
                            .frame(height: 4)

                        GeometryReader { barProxy in
                            let total = Double(viewModel.totalSecondsForCurrentMode)
                            let elapsed = total - Double(viewModel.remainingSeconds)
                            let ratio = total > 0 ? min(max(elapsed / total, 0), 1) : 0

                            RoundedRectangle(cornerRadius: 4)
                                .fill(viewModel.currentAccentColor)
                                .frame(width: barProxy.size.width * ratio, height: 4)
                                .animation(.linear(duration: 1), value: ratio)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 30)

                    // Workflow dots
                    HStack(spacing: 5) {
                        ForEach(0..<settings.workflowCount, id: \.self) { index in
                            let isHighlighted = viewModel.currentMode == .longBreak ||
                                (viewModel.currentMode == .work && index <= viewModel.completedWorkflows) ||
                                (viewModel.currentMode != .work && index < viewModel.completedWorkflows)
                            Circle()
                                .fill(isHighlighted ? viewModel.currentAccentColor : settings.selectedTheme.textColor.opacity(0.3))
                                .frame(width: 7, height: 7)
                        }
                    }
                } else {
                    // End infinity button
                    Button(action: { settings.infinityMode = false }) {
                        Text("End ∞")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(viewModel.currentAccentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(viewModel.currentAccentColor.opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)
                }

                // Controls
                HStack(spacing: 20) {
                    Button(action: { viewModel.resetCurrentMode() }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.5))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        if viewModel.status == .pulsing {
                            viewModel.continueToNextPhase()
                        } else {
                            viewModel.toggleStartPause()
                        }
                    }) {
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

                Spacer()

                // Music controls at the bottom
                if settings.showMusicControls {
                    MusicControlsView()
                        .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)

            // Divider
            Rectangle()
                .fill(settings.selectedTheme.textColor.opacity(0.1))
                .frame(width: 1)
                .padding(.vertical, 16)

            // Right side: Tasks + Playlist drawer + Goal
            VStack(spacing: 0) {
                // Tasks section — fills all available space
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Tasks")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.5))
                            .textCase(.uppercase)

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingAddTask.toggle()
                                if !showingAddTask {
                                    newTaskName = ""
                                    newTaskDuration = nil
                                }
                            }
                        }) {
                            Image(systemName: showingAddTask ? "xmark.circle.fill" : "plus.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(showingAddTask ? settings.selectedTheme.textColor.opacity(0.5) : settings.selectedTheme.workAccent)
                        }
                        .buttonStyle(.plain)
                        .help(showingAddTask ? "Cancel" : "Add Task")

                        Spacer()
                    }

                    // Inline add task form
                    if showingAddTask {
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

                            Button(action: {
                                let name = newTaskName.trimmingCharacters(in: .whitespaces)
                                guard !name.isEmpty else { return }
                                taskManager.addTask(name: name, targetMinutes: newTaskDuration)
                                newTaskName = ""
                                newTaskDuration = nil
                                withAnimation(.easeInOut(duration: 0.2)) { showingAddTask = false }
                            }) {
                                Text("Create")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(newTaskName.trimmingCharacters(in: .whitespaces).isEmpty ? settings.selectedTheme.textColor.opacity(0.4) : settings.selectedTheme.backgroundColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(newTaskName.trimmingCharacters(in: .whitespaces).isEmpty ? settings.selectedTheme.textColor.opacity(0.1) : settings.selectedTheme.workAccent)
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(newTaskName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(settings.selectedTheme.textColor.opacity(0.05)))
                        .transition(.opacity.combined(with: .move(edge: .top)))
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

                // Divider
                Rectangle()
                    .fill(settings.selectedTheme.textColor.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 12)

                // Daily goal — fixed intrinsic height at the bottom
                VStack(spacing: 6) {
                    if goalTracker.hasGoalSet {
                        let todayMinutes = goalTracker.getTodayMinutes()
                        let goalMinutes = goalTracker.dailyGoalMinutes
                        let progress = min(Double(todayMinutes) / Double(goalMinutes), 1.0)

                        HStack {
                            Text("Daily Goal")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(settings.selectedTheme.textColor.opacity(0.5))
                                .textCase(.uppercase)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(progress >= 1.0 ? Color(hex: "4CAF50") : viewModel.currentAccentColor)
                        }

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(settings.selectedTheme.textColor.opacity(0.15))
                                .frame(height: 6)
                            GeometryReader { barGeo in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(progress >= 1.0 ? Color(hex: "4CAF50") : viewModel.currentAccentColor)
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
            .frame(maxWidth: .infinity)
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

    private var timerFontWeight: Font.Weight {
        switch settings.timerFontWeightRaw {
        case "Thin": return .thin
        case "Light": return .light
        case "Regular": return .regular
        case "Medium": return .medium
        case "DemiBold": return .semibold
        case "Bold": return .bold
        default: return .medium
        }
    }
    

}

/// Compact task row for the detailed view
struct DetailedTaskRow: View {
    let task: WorkTask
    let isActive: Bool

    @ObservedObject var taskManager = TaskManager.shared
    @ObservedObject var settings = SettingsManager.shared

    var body: some View {
        HStack(spacing: 6) {
            Button(action: {
                taskManager.setActiveTask(id: isActive ? nil : task.id)
            }) {
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
            
            // Archive button
            Button(action: { taskManager.archiveTask(id: task.id) }) {
                Image(systemName: "archivebox")
                    .font(.system(size: 10))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help("Archive")
            
            // Delete button
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

/// Native right-click handler using NSViewRepresentable
struct RightClickHandler: NSViewRepresentable {
    let viewModel: PomodoroViewModel
    let settings: SettingsManager
    
    func makeNSView(context: Context) -> RightClickNSView {
        let view = RightClickNSView()
        view.viewModel = viewModel
        view.settings = settings
        return view
    }
    
    func updateNSView(_ nsView: RightClickNSView, context: Context) {
        nsView.viewModel = viewModel
        nsView.settings = settings
    }
}

/// Custom NSView that captures only right-click events
class RightClickNSView: NSView {
    var viewModel: PomodoroViewModel?
    var settings: SettingsManager?
    private var settingsMenu: SettingsMenu?
    
    override func rightMouseDown(with event: NSEvent) {
        guard let viewModel = viewModel, let settings = settings else { return }
        
        settingsMenu = SettingsMenu(viewModel: viewModel, settings: settings)
        guard let menu = settingsMenu?.createMenu() else { return }
        
        // Show menu at mouse location
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
    
    // Pass through all other events to the superview
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Check if this is from a right-click - if not, return nil to pass through
        let currentEvent = NSApp.currentEvent
        if currentEvent?.type == .rightMouseDown {
            return super.hitTest(point)
        }
        // For all other events (left click, etc), pass through to SwiftUI
        return nil
    }
}

/// Music controls with now playing info and buttons
struct MusicControlsView: View {
    @ObservedObject var musicManager = MusicManager.shared
    @ObservedObject var settings = SettingsManager.shared
    
    var isFullscreen: Bool = false
    var scale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 8 * scale) {
            // Song info on the left (if available)
            if !musicManager.nowPlaying.displayText.isEmpty {
                Text(musicManager.nowPlaying.displayText)
                    .font(.system(size: 9 * scale))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer(minLength: 4)
            }
            
            // Control buttons on the right
            if settings.showMusicControls {
                HStack(spacing: 12 * scale) {
                    // Shuffle Button
                    Button(action: {
                        musicManager.toggleShuffle()
                    }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 10 * scale))
                            .foregroundColor(musicManager.isShuffling ? settings.selectedTheme.workAccent : settings.selectedTheme.textColor.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Shuffle")
                    
                    // Previous
                    Button(action: { musicManager.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 12 * scale))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    
                    // Play/Pause
                    Button(action: { musicManager.togglePlayPause() }) {
                        Image(systemName: musicManager.nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14 * scale))
                            .foregroundColor(settings.selectedTheme.textColor)
                    }
                    .buttonStyle(.plain)
                    
                    // Next
                    Button(action: { musicManager.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12 * scale))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    
                    // Repeat Button
                    Button(action: {
                        musicManager.toggleRepeat()
                    }) {
                        Image(systemName: musicManager.repeatMode == .one ? "repeat.1" : "repeat")
                            .font(.system(size: 10 * scale))
                            .foregroundColor(musicManager.repeatMode != .off ? settings.selectedTheme.workAccent : settings.selectedTheme.textColor.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Repeat")
                }
            }
        }
    }
}
