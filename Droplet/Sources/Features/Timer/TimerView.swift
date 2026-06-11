import SwiftUI

struct TimerView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @ObservedObject var settings = SettingsManager.shared

    @State private var pulseAnimation = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: surfaceCornerRadius)
                    .fill(settings.selectedTheme.backgroundColor.opacity(0.95))
                    .overlay {
                        if settings.gradientEnabled {
                            RoundedRectangle(cornerRadius: surfaceCornerRadius)
                                .fill(surfaceGradient)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: surfaceCornerRadius)
                            .fill(.ultraThinMaterial)
                    )
                    .shadow(
                        color: .black.opacity(settings.fullscreenMode ? 0 : 0.2),
                        radius: settings.fullscreenMode ? 0 : 10,
                        x: 0,
                        y: settings.fullscreenMode ? 0 : 5
                    )

                switch settings.currentView {
                case .timer:
                    if settings.miniFloaterMode {
                        MiniTimerView(viewModel: viewModel)
                    } else if settings.detailedViewPresented {
                        DetailedTimerView(viewModel: viewModel)
                            .transition(.opacity.combined(with: .scale(scale: 0.985)))
                    } else {
                        timerContent(geometry: geometry)
                            .transition(.opacity)
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
                case .sounds:
                    SoundsView()
                }

                if settings.currentView == .timer && !settings.miniFloaterMode {
                    TimerTopChrome(settings: settings)
                }
            }
        }
        .clipShape(settings.miniFloaterMode ? AnyShape(Capsule()) : AnyShape(RoundedRectangle(cornerRadius: surfaceCornerRadius)))
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
        .animation(.easeInOut(duration: 0.18), value: settings.detailedViewPresented)
    }

    private var surfaceCornerRadius: CGFloat {
        settings.fullscreenMode ? 0 : 28
    }

    private var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                settings.selectedTheme.textColor.opacity(themeIsDark ? 0.08 : 0.12),
                .clear,
                settings.selectedTheme.workAccent.opacity(themeIsDark ? 0.16 : 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var themeIsDark: Bool {
        switch settings.selectedTheme {
        case .light, .beige, .linen, .poppy, .blossom, .frog:
            return false
        default:
            return true
        }
    }

    private var isFullscreen: Bool {
        settings.fullscreenMode
    }

    private var currentFontSize: Double {
        settings.fullscreenMode ? settings.fullscreenFontSize : settings.timerFontSize
    }

    private var fullscreenScale: CGFloat {
        settings.fullscreenMode ? CGFloat(settings.fullscreenFontSize / settings.timerFontSize) : 1
    }

    private var currentFontWeight: Font.Weight {
        MacTimerFontWeight.weight(for: settings.timerFontWeightRaw)
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
            if let activeTask = TaskManager.shared.activeTask {
                Button(action: { settings.navigateTo(.taskList) }) {
                    Text(activeTask.name)
                        .font(.system(size: taskNameFontSize(for: activeTask.name) * fullscreenScale))
                        .fontWeight(.medium)
                        .foregroundColor(settings.selectedTheme.workAccent)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .buttonStyle(.plain)
                .padding(.bottom, isFullscreen ? 16 : 4)
            }

            HStack(spacing: 6) {
                if settings.showTimerControls {
                    Button(action: primaryTimerAction) {
                        Image(systemName: viewModel.status == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 12 * fullscreenScale))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }

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

                if settings.showTimerControls {
                    Button(action: { viewModel.resetCurrentMode() }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12 * fullscreenScale))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }

            if settings.showProgressBar && geometry.size.width >= 100 && viewModel.currentMode != .infinity {
                TimerProgressBar(
                    totalSeconds: viewModel.totalSecondsForCurrentMode,
                    remainingSeconds: viewModel.remainingSeconds,
                    color: viewModel.currentAccentColor,
                    backgroundColor: settings.selectedTheme.textColor.opacity(0.2)
                )
                .padding(.horizontal, 20)
            }

            if viewModel.currentMode != .infinity {
                TimerWorkflowDots(
                    count: settings.workflowCount,
                    mode: viewModel.currentMode,
                    completedWorkflows: viewModel.completedWorkflows,
                    color: viewModel.currentAccentColor,
                    inactiveColor: settings.selectedTheme.textColor.opacity(0.3),
                    scale: fullscreenScale
                )
                .padding(.top, isFullscreen ? 16 : 4)
            } else {
                TimerPillButton(
                    title: "End ∞",
                    color: viewModel.currentAccentColor,
                    scale: fullscreenScale,
                    action: { settings.infinityMode = false }
                )
                .padding(.top, isFullscreen ? 16 : 4)
            }

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

            if settings.showMusicControls && geometry.size.height >= 140 && geometry.size.width >= 200 {
                MusicControlsView(isFullscreen: isFullscreen, scale: fullscreenScale)
                    .padding(.top, isFullscreen ? 24 : 6)
                    .frame(maxWidth: geometry.size.width - 32)
            }
        }
        .padding(16)
    }

    private func primaryTimerAction() {
        if viewModel.status == .pulsing {
            viewModel.continueToNextPhase()
        } else {
            viewModel.toggleStartPause()
        }
    }

    private func taskNameFontSize(for text: String) -> CGFloat {
        let count = text.count
        if count <= 10 {
            return 14
        } else if count <= 20 {
            return 12
        } else if count <= 30 {
            return 10
        }
        return 9
    }
}

private struct TimerTopChrome: View {
    @ObservedObject var settings: SettingsManager
    @ObservedObject var soundManager = SoundManager.shared

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Button(action: { settings.toggleFullscreen() }) {
                    Image(systemName: settings.fullscreenMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.3))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(spacing: 8) {
                    Button(action: { settings.navigateTo(.settings) }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 11))
                            .foregroundColor(settings.selectedTheme.textColor.opacity(0.3))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)

                    if settings.soundControlsEnabled {
                        Button(action: { settings.navigateTo(.sounds) }) {
                            Image(systemName: soundManager.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                                .font(.system(size: 11))
                                .foregroundColor(
                                    soundManager.isPlaying
                                        ? settings.selectedTheme.workAccent.opacity(0.85)
                                        : settings.selectedTheme.textColor.opacity(0.34)
                                )
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, settings.fullscreenMode ? 22 : 18)
            .padding(.horizontal, settings.fullscreenMode ? 22 : 18)
            Spacer()
        }
    }
}
