import SwiftUI

/// Main timer display view
struct TimerView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @ObservedObject var settings = SettingsManager.shared
    
    @State private var pulseAnimation = false
    
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
                    timerContent(geometry: geometry)
                case .weeklyProgress:
                    InAppWeeklyProgressView()
                case .goalSetup:
                    InAppGoalSetupView()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(minWidth: 140, minHeight: 100)
        .onTapGesture(count: 2) {
            // Only enable on timer view
            if settings.currentView == .timer {
                viewModel.resetCurrentMode()
            }
        }
        .onTapGesture(count: 1) {
            // Only enable on timer view
            if settings.currentView == .timer {
                if viewModel.status == .pulsing {
                    viewModel.continueToNextPhase()
                } else {
                    viewModel.toggleStartPause()
                }
            }
        }
        .overlay(
            // Native right-click handler using NSViewRepresentable
            RightClickHandler(viewModel: viewModel, settings: settings)
                .allowsHitTesting(true)
        )
        .onAppear {
            startPulseAnimationIfNeeded()
        }
        .onChange(of: viewModel.status) { newStatus in
            if newStatus == .pulsing {
                startPulseAnimation()
            } else {
                pulseAnimation = false
            }
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
                            .font(.system(size: 12))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                
                // Timer text
                Text(viewModel.formattedTime)
                    .font(.custom("Avenir Next", size: settings.timerFontSize))
                    .fontWeight(.medium)
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
                            .font(.system(size: 12))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Progress bar
            if settings.showProgressBar && geometry.size.width >= 100 {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(settings.selectedTheme.textColor.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(viewModel.currentAccentColor)
                        .frame(width: max(0, (geometry.size.width - 40) * viewModel.progressRatio), height: 4)
                        .animation(.linear(duration: 0.5), value: viewModel.progressRatio)
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
            }
            
            // Workflow counter
            HStack(spacing: 4) {
                ForEach(0..<settings.workflowCount, id: \.self) { index in
                    let isHighlighted = viewModel.currentMode == .longBreak ||
                        (viewModel.currentMode == .work && index <= viewModel.completedWorkflows) ||
                        (viewModel.currentMode != .work && index < viewModel.completedWorkflows)
                    Circle()
                        .fill(isHighlighted ? viewModel.currentAccentColor : settings.selectedTheme.textColor.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.top, 4)
            
            // Music controls
            if settings.showMusicControls && geometry.size.height >= 140 && geometry.size.width >= 200 {
                MusicControlsView()
                    .padding(.top, 6)
                    .frame(maxWidth: geometry.size.width - 32)
            }
        }
        .padding(16)
    }
}

/// In-app Weekly Progress View with back button
struct InAppWeeklyProgressView: View {
    @ObservedObject var goalTracker = GoalTracker.shared
    @ObservedObject var settings = SettingsManager.shared
    @State private var weekOffset: Int = 0
    
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
            HStack(alignment: .bottom, spacing: 8) {
                let weekData = goalTracker.getWeekData(weekOffset: weekOffset)
                ForEach(Array(weekData.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 2) {
                        let progress = goalTracker.dailyGoalMinutes > 0 
                            ? Double(day.minutes) / Double(goalTracker.dailyGoalMinutes) 
                            : 0
                        let barColor: Color = progress >= 1.25 ? Color(hex: "FFD700") :
                                              progress >= 1.0 ? Color(hex: "4CAF50") :
                                              settings.selectedTheme.workAccent
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(barColor)
                            .frame(width: 24, height: max(4, min(CGFloat(progress) * 60, 80)))
                            .shadow(color: progress >= 1.25 ? barColor.opacity(0.6) : .clear, radius: progress >= 1.25 ? 4 : 0)
                        
                        Text(day.dayName.prefix(1))
                            .font(.system(size: 8))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.5))
                    }
                }
            }
            .frame(height: 90)
            .padding(.horizontal, 8)
            
            // Today's summary
            if goalTracker.hasGoalSet {
                let progress = goalTracker.getTodayProgress()
                Text("Today: \(GoalTracker.formatMinutes(goalTracker.getTodayMinutes())) / \(GoalTracker.formatMinutes(goalTracker.dailyGoalMinutes)) (\(Int(progress * 100))%)")
                    .font(.system(size: 10))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
            }
        }
        .padding(12)
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
        let menu = settingsMenu!.createMenu()
        
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
    
    var body: some View {
        HStack(spacing: 8) {
            // Song info on the left (if available)
            if !musicManager.nowPlaying.displayText.isEmpty {
                Text(musicManager.nowPlaying.displayText)
                    .font(.system(size: 9))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer(minLength: 4)
            }
            
            // Control buttons on the right
            if settings.showMusicControls {
                HStack(spacing: 12) {
                    // Shuffle Button
                    Button(action: {
                        musicManager.toggleShuffle()
                    }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 10)) // Increased from 8
                            .foregroundColor(musicManager.isShuffling ? settings.selectedTheme.workAccent : settings.selectedTheme.textColor.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Shuffle")
                    
                    // Previous
                    Button(action: { musicManager.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 12)) // Increased from 10
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    
                    // Play/Pause
                    Button(action: { musicManager.togglePlayPause() }) {
                        Image(systemName: musicManager.nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14)) // Increased from 12
                            .foregroundColor(settings.selectedTheme.textColor)
                    }
                    .buttonStyle(.plain)
                    
                    // Next
                    Button(action: { musicManager.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12)) // Increased from 10
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    
                    // Repeat Button
                    Button(action: {
                        musicManager.toggleRepeat()
                    }) {
                        Image(systemName: musicManager.repeatMode == .one ? "repeat.1" : "repeat")
                            .font(.system(size: 10)) // Increased from 8
                            .foregroundColor(musicManager.repeatMode != .off ? settings.selectedTheme.workAccent : settings.selectedTheme.textColor.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Repeat")
                }
            }
        }
    }
}
