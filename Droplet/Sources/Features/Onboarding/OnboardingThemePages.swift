import SwiftUI

// MARK: - Page 5 - Appearance

extension OnboardingView {
    var page5View: some View {
        VStack(spacing: 12) {
            onboardingTitle(
                "Appearance",
                subtitle: "Choose the theme and surface treatment Droplet should start with."
            )

            HStack(alignment: .top, spacing: 14) {
                themePickerPanel
                    .frame(maxWidth: .infinity)

                VStack(spacing: 10) {
                    OnboardingToggleRow(
                        title: "Gradient",
                        subtitle: "Use the same soft flow in app and widgets.",
                        theme: previewTheme,
                        isOn: $gradientEnabled
                    )

                    OnboardingToggleRow(
                        title: "Glow",
                        subtitle: "Add a subtle accent glow to the timer.",
                        theme: previewTheme,
                        isOn: $glowEnabled
                    )
                }
                .frame(width: 210)
            }
            .padding(.horizontal, 26)
        }
    }

    private var themePickerPanel: some View {
        OnboardingPanel(theme: previewTheme) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 5)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Theme.allCases) { theme in
                    themeSwatch(theme)
                }
            }
        }
    }

    private func themeSwatch(_ theme: Theme) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                previewTheme = theme
                selectedTheme = theme
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(theme.backgroundColor)
                        .frame(height: 30)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(theme.workAccent)
                        Circle()
                            .fill(theme.breakAccent)
                    }
                    .frame(width: 28, height: 11)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(selectedTheme == theme ? theme.workAccent : theme.textColor.opacity(0.2), lineWidth: selectedTheme == theme ? 2 : 1)
                )

                Text(theme.rawValue)
                    .font(.system(size: 7, weight: selectedTheme == theme ? .semibold : .regular))
                    .foregroundColor(previewTheme.textColor.opacity(selectedTheme == theme ? 0.9 : 0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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

// MARK: - Page 8 - Ready

extension OnboardingView {
    var page8View: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle()
                    .fill(previewTheme.workAccent.opacity(0.15))
                    .frame(width: 78, height: 78)
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(previewTheme.workAccent)
            }

            VStack(spacing: 8) {
                Text("Ready to Focus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(previewTheme.textColor)
                Text(summaryText)
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

    private var summaryText: String {
        let soundSummary = soundControlsEnabled ? selectedSoundChoice.title : "quiet mode"
        return "\(workDuration)m focus, \(shortBreakDuration)m breaks, \(formatGoal(dailyGoalHours)) daily goal, \(soundSummary)."
    }
}
