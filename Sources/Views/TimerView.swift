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
                
                VStack(spacing: 8) {
                    // Timer display - using elegant Avenir Next font with dynamic size
                    Text(viewModel.formattedTime)
                        .font(.custom("Avenir Next", size: settings.timerFontSize))
                        .fontWeight(.medium)
                        .foregroundColor(settings.selectedTheme.textColor)
                        .monospacedDigit()
                        .opacity(viewModel.status == .pulsing ? (pulseAnimation ? 0.5 : 1.0) : 1.0)
                        .minimumScaleFactor(0.5)
                        .shadow(
                            color: settings.enableGlow ? viewModel.currentAccentColor.opacity(0.6) : .clear,
                            radius: settings.enableGlow ? 8 : 0
                        )
                    
                    // Progress bar (conditionally shown, needs minimum width)
                    if settings.showProgressBar && geometry.size.width >= 100 {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(settings.selectedTheme.textColor.opacity(0.2))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(viewModel.currentAccentColor)
                                .frame(width: max(0, (geometry.size.width - 40) * viewModel.progressRatio), height: 4)
                                .animation(.linear(duration: 0.5), value: viewModel.progressRatio)
                                .shadow(
                                    color: settings.enableGlow ? viewModel.currentAccentColor.opacity(0.8) : .clear,
                                    radius: settings.enableGlow ? 6 : 0
                                )
                        }
                        .frame(height: 4)
                        .padding(.horizontal, 20)
                    }
                    
                    // Workflow counter - shows current progress
                    HStack(spacing: 4) {
                        ForEach(0..<settings.workflowCount, id: \.self) { index in
                            let isHighlighted: Bool = {
                                if viewModel.currentMode == .longBreak {
                                    return true  // All lit during long break
                                } else if viewModel.currentMode == .work {
                                    return index <= viewModel.completedWorkflows  // Current + completed
                                } else {
                                    return index < viewModel.completedWorkflows  // Just completed
                                }
                            }()
                            Circle()
                                .fill(isHighlighted ? 
                                      viewModel.currentAccentColor : 
                                      settings.selectedTheme.textColor.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.top, 4)
                    
                    // Music controls (only shown if enabled AND enough vertical space)
                    if settings.showMusicControls && geometry.size.height >= 140 {
                        MusicControlsView()
                            .padding(.top, 6)
                            .frame(maxWidth: geometry.size.width - 32)
                    }
                }
                .padding(16)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(minWidth: 140, minHeight: 100)
        .onTapGesture(count: 2) {
            viewModel.resetCurrentMode()
        }
        .onTapGesture(count: 1) {
            if viewModel.status == .pulsing {
                viewModel.continueToNextPhase()
            } else {
                viewModel.toggleStartPause()
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
            HStack(spacing: 12) {
                Button(action: { musicManager.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 10))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                }
                .buttonStyle(.plain)
                
                Button(action: { musicManager.togglePlayPause() }) {
                    Image(systemName: musicManager.nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 12))
                        .foregroundColor(settings.selectedTheme.textColor)
                }
                .buttonStyle(.plain)
                
                Button(action: { musicManager.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 10))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

