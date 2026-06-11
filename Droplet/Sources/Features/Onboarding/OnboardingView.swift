import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    static let pageCount = 8

    @State var currentPage = 0
    @State var previewTheme: Theme
    @State var selectedTheme: Theme
    @State var workDuration: Int
    @State var shortBreakDuration: Int
    @State var longBreakDuration: Int
    @State var workflowCount: Int
    @State var dailyGoalHours: Double
    @State var autoStartNextSession: Bool
    @State var launchAtLoginEnabled: Bool
    @State var gradientEnabled: Bool
    @State var glowEnabled: Bool
    @State var soundControlsEnabled: Bool
    @State var soundVolume: Double
    @State var selectedSoundChoice: OnboardingSoundChoice

    var onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        let settings = SettingsManager.shared
        let soundManager = SoundManager.shared
        let initialTheme = settings.selectedTheme
        let goalMinutes = GoalTracker.shared.dailyGoalMinutes
        let initialGoalHours = goalMinutes > 0 ? Double(goalMinutes) / 60 : 3
        let initialSoundChoice: OnboardingSoundChoice

        if let generatedNoise = soundManager.currentGeneratedNoise {
            initialSoundChoice = .generated(generatedNoise)
        } else if soundManager.currentSound != .none {
            initialSoundChoice = .ambient(soundManager.currentSound)
        } else {
            initialSoundChoice = .generated(.white)
        }

        _previewTheme = State(initialValue: initialTheme)
        _selectedTheme = State(initialValue: initialTheme)
        _workDuration = State(initialValue: settings.workDuration)
        _shortBreakDuration = State(initialValue: settings.shortBreakDuration)
        _longBreakDuration = State(initialValue: settings.longBreakDuration)
        _workflowCount = State(initialValue: settings.workflowCount)
        _dailyGoalHours = State(initialValue: initialGoalHours)
        _autoStartNextSession = State(initialValue: settings.autoStartNextSession)
        _launchAtLoginEnabled = State(initialValue: LaunchAtLoginManager.shared.isEnabled)
        _gradientEnabled = State(initialValue: settings.gradientEnabled)
        _glowEnabled = State(initialValue: settings.enableGlow)
        _soundControlsEnabled = State(initialValue: settings.soundControlsEnabled)
        _soundVolume = State(initialValue: Double(soundManager.volume))
        _selectedSoundChoice = State(initialValue: initialSoundChoice)
        self.onComplete = onComplete
    }

    var lastPageIndex: Int {
        Self.pageCount - 1
    }

    var body: some View {
        ZStack {
            // Animated background follows previewTheme live.
            previewTheme.backgroundColor
                .animation(.easeInOut(duration: 0.35), value: previewTheme.rawValue)

            VStack(spacing: 0) {
                topBar

                // Slide carousel keeps all pages rendered and offset-driven.
                ZStack {
                    page1View.carouselPage(index: 0, current: currentPage)
                    page2View.carouselPage(index: 1, current: currentPage)
                    page3View.carouselPage(index: 2, current: currentPage)
                    page4View.carouselPage(index: 3, current: currentPage)
                    page5View.carouselPage(index: 4, current: currentPage)
                    page6View.carouselPage(index: 5, current: currentPage)
                    page7View.carouselPage(index: 6, current: currentPage)
                    page8View.carouselPage(index: 7, current: currentPage)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
        }
        .frame(width: 540, height: 430)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Navigation

    func advance() {
        withAnimation(.easeInOut(duration: 0.32)) {
            currentPage = min(currentPage + 1, lastPageIndex)
        }
    }

    func previous() {
        withAnimation(.easeInOut(duration: 0.32)) {
            currentPage = max(currentPage - 1, 0)
        }
    }

    func complete() {
        let settings = SettingsManager.shared
        let soundManager = SoundManager.shared

        settings.workDuration = workDuration
        settings.shortBreakDuration = shortBreakDuration
        settings.longBreakDuration = longBreakDuration
        settings.workflowCount = workflowCount
        settings.autoStartNextSession = autoStartNextSession
        settings.selectedTheme = selectedTheme
        settings.setGradientEnabled(gradientEnabled)
        settings.enableGlow = glowEnabled
        settings.soundControlsEnabled = soundControlsEnabled

        GoalTracker.shared.setDailyGoal(hours: dailyGoalHours)

        if LaunchAtLoginManager.shared.isEnabled != launchAtLoginEnabled {
            LaunchAtLoginManager.shared.setEnabled(launchAtLoginEnabled)
        }

        soundManager.setVolume(Float(soundVolume))
        if soundControlsEnabled {
            selectedSoundChoice.apply(to: soundManager)
        } else {
            soundManager.stop()
        }

        UserDefaults.standard.set(true, forKey: "hasShownOnboarding")
        onComplete()
    }
}

enum OnboardingSoundChoice: Hashable {
    case generated(GeneratedNoise)
    case ambient(AmbientSound)

    var title: String {
        switch self {
        case .generated(let noise):
            return noise.rawValue.replacingOccurrences(of: " Noise", with: "")
        case .ambient(let sound):
            return sound.rawValue
        }
    }

    var systemImage: String {
        switch self {
        case .generated(let noise):
            switch noise {
            case .white:
                return "waveform"
            case .brown:
                return "water.waves"
            case .pink:
                return "circle.lefthalf.filled"
            case .green:
                return "leaf.fill"
            case .blue:
                return "wind"
            case .violet:
                return "sparkles"
            }
        case .ambient(let sound):
            switch sound {
            case .none:
                return "speaker.slash"
            case .forest:
                return "tree.fill"
            case .train:
                return "tram.fill"
            case .library:
                return "books.vertical.fill"
            case .crickets:
                return "moon.stars.fill"
            }
        }
    }

    func apply(to soundManager: SoundManager) {
        switch self {
        case .generated(let noise):
            soundManager.selectGenerated(noise)
        case .ambient(let sound):
            soundManager.selectAmbient(sound)
        }
    }
}
