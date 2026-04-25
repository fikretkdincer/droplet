import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var previewTheme: Theme
    @State private var selectedTheme: Theme

    var onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        let initial = SettingsManager.shared.selectedTheme
        _previewTheme = State(initialValue: initial)
        _selectedTheme = State(initialValue: initial)
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            // Animated background — follows previewTheme live
            previewTheme.backgroundColor
                .animation(.easeInOut(duration: 0.35), value: previewTheme.rawValue)

            VStack(spacing: 0) {
                topBar

                // Slide carousel — all pages are rendered, offset-driven
                ZStack {
                    page1View.carouselPage(index: 0, current: currentPage)
                    page2View.carouselPage(index: 1, current: currentPage)
                    page3View.carouselPage(index: 2, current: currentPage)
                    page4View.carouselPage(index: 3, current: currentPage)
                    page5View.carouselPage(index: 4, current: currentPage)
                    page6View.carouselPage(index: 5, current: currentPage)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
        }
        .frame(width: 540, height: 390)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Navigation

    private func advance() {
        withAnimation(.easeInOut(duration: 0.32)) {
            currentPage = min(currentPage + 1, 5)
        }
    }

    private func previous() {
        withAnimation(.easeInOut(duration: 0.32)) {
            currentPage = max(currentPage - 1, 0)
        }
    }

    func complete() {
        SettingsManager.shared.selectedTheme = selectedTheme
        UserDefaults.standard.set(true, forKey: "hasShownOnboarding")
        onComplete()
    }
}

// MARK: - Carousel helper

private extension View {
    func carouselPage(index: Int, current: Int) -> some View {
        self
            .frame(width: 540)
            .offset(x: CGFloat(index - current) * 540)
            .animation(.easeInOut(duration: 0.32), value: current)
    }
}

// MARK: - Chrome (top bar + bottom bar)

extension OnboardingView {

    var topBar: some View {
        HStack {
            Spacer()
            if currentPage < 5 {
                Button("Skip") { complete() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(previewTheme.textColor.opacity(0.35))
            } else {
                Color.clear.frame(width: 1, height: 14)
            }
        }
        .frame(height: 38)
        .padding(.horizontal, 22)
    }

    var bottomBar: some View {
        HStack(alignment: .center) {
            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(i == currentPage
                              ? previewTheme.workAccent
                              : previewTheme.textColor.opacity(0.2))
                        .frame(
                            width:  i == currentPage ? 7 : 5,
                            height: i == currentPage ? 7 : 5
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }

            Spacer()

            if currentPage > 0 && currentPage < 5 {
                Button(action: previous) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(previewTheme.textColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(previewTheme.textColor.opacity(0.08))
                    .cornerRadius(9)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }

            if currentPage < 5 {
                Button(action: advance) {
                    HStack(spacing: 5) {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(previewTheme.backgroundColor)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(previewTheme.workAccent)
                    .cornerRadius(9)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentPage)
    }
}

// MARK: - Page 1 — "A Minimal Pomodoro App"

extension OnboardingView {

    var page1View: some View {
        HStack(spacing: 0) {
            // Left: headline + cycle strip
            VStack(alignment: .leading, spacing: 14) {
                Text("💧")
                    .font(.system(size: 34))

                VStack(alignment: .leading, spacing: 3) {
                    Text("A Minimal")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundColor(previewTheme.textColor)
                    Text("Pomodoro App")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundColor(previewTheme.workAccent)
                }

                Text("Your menu bar focus companion.\nWork smarter, one session at a time.")
                    .font(.system(size: 11))
                    .foregroundColor(previewTheme.textColor.opacity(0.6))
                    .lineSpacing(3)

                // Cycle strip
                HStack(spacing: 4) {
                    cyclePill("Work",       color: previewTheme.workAccent)
                    tinyArrow
                    cyclePill("Break",      color: previewTheme.breakAccent)
                    tinyArrow
                    cyclePill("Work",       color: previewTheme.workAccent)
                    tinyArrow
                    cyclePill("Long Break", color: previewTheme.breakAccent.opacity(0.7))
                }
                .padding(.top, 2)
            }
            .padding(.leading, 34)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: static timer mockup
            timerMockup
                .padding(.trailing, 34)
        }
    }

    private var timerMockup: some View {
        VStack(spacing: 10) {
            Text("25:00")
                .font(.custom("Avenir Next", size: 36))
                .fontWeight(.medium)
                .foregroundColor(previewTheme.textColor)
                .monospacedDigit()

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(previewTheme.textColor.opacity(0.15))
                    .frame(width: 110, height: 3)
                RoundedRectangle(cornerRadius: 3)
                    .fill(previewTheme.workAccent)
                    .frame(width: 30, height: 3)
            }

            HStack(spacing: 5) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i == 0 ? previewTheme.workAccent : previewTheme.textColor.opacity(0.22))
                        .frame(width: 5, height: 5)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(previewTheme.textColor.opacity(0.07))
        )
    }

    private func cyclePill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(5)
    }

    private var tinyArrow: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 7))
            .foregroundColor(previewTheme.textColor.opacity(0.3))
    }
}

// MARK: - Page 2 — "Set your goals, follow your tasks"

extension OnboardingView {

    var page2View: some View {
        VStack(spacing: 12) {
            VStack(spacing: 2) {
                Text("Set your goals,")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(previewTheme.textColor)
                Text("follow your tasks")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(previewTheme.workAccent)
                Text("Track daily focus goals and manage your work sessions.")
                    .font(.system(size: 11))
                    .foregroundColor(previewTheme.textColor.opacity(0.55))
                    .padding(.top, 2)
            }

            HStack(spacing: 14) {
                goalCard
                tasksCard
            }
            .padding(.horizontal, 28)
        }
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 10))
                    .foregroundColor(previewTheme.workAccent)
                Text("Goal Tracker")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(previewTheme.textColor)
            }

            // Fake bar chart
            let heights: [CGFloat] = [28, 48, 18, 64, 52, 10, 5]
            let days = ["M", "T", "W", "T", "F", "S", "S"]
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(heights[i] >= 52
                                  ? previewTheme.workAccent
                                  : previewTheme.workAccent.opacity(0.45))
                            .frame(width: 16, height: heights[i])
                        Text(days[i])
                            .font(.system(size: 7))
                            .foregroundColor(previewTheme.textColor.opacity(0.4))
                    }
                }
            }
            .frame(height: 70)

            Text("Set daily goals · track your week")
                .font(.system(size: 9))
                .foregroundColor(previewTheme.textColor.opacity(0.5))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(previewTheme.textColor.opacity(0.06)))
        .frame(maxWidth: .infinity)
    }

    private var tasksCard: some View {
        let tasks: [(String, Bool, Double, String)] = [
            ("Read chapter 3", true,  1.0, "1h 0m / 1h 0m"),
            ("Write report",   false, 0.45, "0h 27m / 1h 0m"),
            ("Review code",    false, 0.0, "0h 0m / 30m"),
        ]
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(previewTheme.workAccent)
                Text("Tasks")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(previewTheme.textColor)
            }

            VStack(spacing: 5) {
                ForEach(0..<tasks.count, id: \.self) { i in
                    let (name, active, prog, progStr) = tasks[i]
                    HStack(spacing: 6) {
                        Image(systemName: active ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundColor(active ? previewTheme.workAccent : previewTheme.textColor.opacity(0.3))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(name)
                                .font(.system(size: 9, weight: active ? .semibold : .regular))
                                .foregroundColor(previewTheme.textColor)
                            Text(progStr)
                                .font(.system(size: 7))
                                .foregroundColor(previewTheme.textColor.opacity(0.5))
                        }
                        Spacer()
                        if prog > 0 {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(previewTheme.textColor.opacity(0.1))
                                    .frame(width: 28, height: 3)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(prog >= 1.0 ? Color.green : previewTheme.workAccent)
                                    .frame(width: CGFloat(28 * prog), height: 3)
                            }
                        }
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(active ? previewTheme.workAccent.opacity(0.12) : previewTheme.textColor.opacity(0.04))
                    )
                }
            }

            Spacer()

            Text("Assign tasks · track time spent")
                .font(.system(size: 9))
                .foregroundColor(previewTheme.textColor.opacity(0.5))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(previewTheme.textColor.opacity(0.06)))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Page 3 — Mini-Floater & Detailed View

extension OnboardingView {

    var page3View: some View {
        VStack(spacing: 12) {
            VStack(spacing: 2) {
                Text("More ways to focus")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(previewTheme.textColor)
                Text("Two extra view modes for different workflows.")
                    .font(.system(size: 11))
                    .foregroundColor(previewTheme.textColor.opacity(0.55))
            }

            HStack(spacing: 14) {
                miniFloaterCard
                detailedViewCard
            }
            .padding(.horizontal, 28)
        }
    }

    private var miniFloaterCard: some View {
        VStack(spacing: 10) {
            Spacer()

            // The pill itself
            Text("24:58")
                .font(.custom("Avenir Next", size: 16))
                .fontWeight(.bold)
                .foregroundColor(previewTheme.textColor)
                .monospacedDigit()
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(previewTheme.backgroundColor)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(previewTheme.textColor.opacity(0.2), lineWidth: 1))
                .shadow(color: .black.opacity(0.12), radius: 5)

            Spacer()

            VStack(spacing: 3) {
                Text("Mini-Floater")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(previewTheme.textColor)
                Text("A tiny pill that stays\nout of your way.")
                    .font(.system(size: 10))
                    .foregroundColor(previewTheme.textColor.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 10).fill(previewTheme.textColor.opacity(0.06)))
    }

    private var detailedViewCard: some View {
        VStack(spacing: 10) {
            // Detailed view mockup
            HStack(spacing: 0) {
                // Timer side
                VStack(spacing: 6) {
                    Text("25:00")
                        .font(.custom("Avenir Next", size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(previewTheme.textColor)
                        .monospacedDigit()

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(previewTheme.textColor.opacity(0.15))
                            .frame(width: 60, height: 2.5)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(previewTheme.workAccent)
                            .frame(width: 20, height: 2.5)
                    }

                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(previewTheme.workAccent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)

                Rectangle()
                    .fill(previewTheme.textColor.opacity(0.1))
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // Tasks side
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tasks")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(previewTheme.textColor.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(["Read ch. 3", "Write report", "Review"], id: \.self) { t in
                            let active = t == "Read ch. 3"
                            HStack(spacing: 4) {
                                Image(systemName: active ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 8))
                                    .foregroundColor(active ? previewTheme.workAccent : previewTheme.textColor.opacity(0.3))
                                Text(t)
                                    .font(.system(size: 8, weight: active ? .semibold : .regular))
                                    .foregroundColor(previewTheme.textColor.opacity(active ? 1.0 : 0.7))
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Divider
                    Rectangle()
                        .fill(previewTheme.textColor.opacity(0.1))
                        .frame(height: 1)
                    
                    // Daily Goal
                    VStack(spacing: 3) {
                        HStack {
                            Text("DAILY GOAL")
                                .font(.system(size: 6, weight: .semibold))
                                .foregroundColor(previewTheme.textColor.opacity(0.5))
                            Spacer()
                            Text("50%")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(previewTheme.workAccent)
                        }
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(previewTheme.textColor.opacity(0.15))
                                .frame(height: 3)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(previewTheme.workAccent)
                                .frame(width: 25, height: 3)
                        }
                        .frame(height: 3)
                        
                        Text("2h 0m / 4h 0m")
                            .font(.system(size: 6))
                            .foregroundColor(previewTheme.textColor.opacity(0.6))
                    }
                    .padding(.bottom, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.horizontal, 6)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(previewTheme.backgroundColor)
                    .shadow(color: .black.opacity(0.06), radius: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(previewTheme.textColor.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 6)

            VStack(spacing: 3) {
                Text("Detailed View")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(previewTheme.textColor)
                Text("Timer + tasks side by side.")
                    .font(.system(size: 10))
                    .foregroundColor(previewTheme.textColor.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(previewTheme.textColor.opacity(0.06)))
    }
}

// MARK: - Page 4 — Power Features

extension OnboardingView {

    var page4View: some View {
        VStack(spacing: 12) {
            VStack(spacing: 2) {
                Text("Packed with features")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(previewTheme.textColor)
                Text("Everything you need for deep work, right in the menu bar.")
                    .font(.system(size: 11))
                    .foregroundColor(previewTheme.textColor.opacity(0.55))
            }
            
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: 16) {
                featureItem(icon: "speaker.wave.2.fill", title: "Immersive Sounds", desc: "Rain, forest, & more (or custom)")
                featureItem(icon: "music.note", title: "Music Controls", desc: "Control Spotify/Apple Music")
                featureItem(icon: "infinity", title: "Infinity Mode", desc: "Work without a time limit")
                featureItem(icon: "slider.horizontal.3", title: "Custom Durations", desc: "Tailor work/break times")
                featureItem(icon: "eye.fill", title: "20-20-20 Rule", desc: "Protect your eyes from strain")
                featureItem(icon: "arrow.up.backward.and.arrow.down.forward", title: "Fullscreen Focus", desc: "Block out all distractions")
            }
            .padding(.horizontal, 36)
            .padding(.top, 10)
        }
    }

    private func featureItem(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(previewTheme.workAccent.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(previewTheme.workAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(previewTheme.textColor)
                Text(desc)
                    .font(.system(size: 9))
                    .foregroundColor(previewTheme.textColor.opacity(0.55))
            }
        }
    }
}

// MARK: - Page 5 — Theme Picker

extension OnboardingView {

    var page5View: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("Choose your appearance")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(previewTheme.textColor)
                Text("The whole view updates live as you explore.")
                    .font(.system(size: 11))
                    .foregroundColor(previewTheme.textColor.opacity(0.55))
            }

            let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(Theme.allCases) { theme in
                    themeSwatch(theme)
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private func themeSwatch(_ theme: Theme) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                previewTheme  = theme
                selectedTheme = theme
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    // Selection ring (outside the circle)
                    Circle()
                        .stroke(previewTheme.textColor.opacity(0.75), lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .opacity(selectedTheme == theme ? 1 : 0)

                    // Background circle
                    Circle()
                        .fill(theme.backgroundColor)
                        .frame(width: 34, height: 34)
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)

                    // Accent dot
                    Circle()
                        .fill(theme.workAccent)
                        .frame(width: 12, height: 12)
                }
                .scaleEffect(previewTheme == theme ? 1.12 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.65), value: previewTheme.rawValue)

                Text(theme.rawValue)
                    .font(.system(size: 7, weight: previewTheme == theme ? .semibold : .regular))
                    .foregroundColor(previewTheme.textColor.opacity(previewTheme == theme ? 0.9 : 0.5))
                    .animation(.easeInOut(duration: 0.2), value: previewTheme.rawValue)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                previewTheme = hovering ? theme : selectedTheme
            }
        }
    }
}

// MARK: - Page 6 — Ready

extension OnboardingView {

    var page6View: some View {
        VStack(spacing: 20) {
            Spacer()

            // Checkmark badge
            ZStack {
                Circle()
                    .fill(previewTheme.workAccent.opacity(0.15))
                    .frame(width: 78, height: 78)
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(previewTheme.workAccent)
            }

            VStack(spacing: 8) {
                Text("You're all set!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(previewTheme.textColor)
                Text("droplet lives in your menu bar.\nClick the 💧 icon to show or hide it anytime.")
                    .font(.system(size: 11))
                    .foregroundColor(previewTheme.textColor.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button(action: complete) {
                Text("Start Focusing")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(previewTheme.backgroundColor)
                    .padding(.horizontal, 34)
                    .padding(.vertical, 12)
                    .background(previewTheme.workAccent)
                    .cornerRadius(11)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
