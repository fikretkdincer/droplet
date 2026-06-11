import SwiftUI

// MARK: - Page 4 - Automation

extension OnboardingView {
    var page4View: some View {
        VStack(spacing: 14) {
            onboardingTitle(
                "Automation",
                subtitle: "Choose how much Droplet should handle without extra clicks."
            )

            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 10) {
                    OnboardingToggleRow(
                        title: "Auto-Start Sessions",
                        subtitle: "Move from focus to break automatically.",
                        theme: previewTheme,
                        isOn: $autoStartNextSession
                    )

                    OnboardingToggleRow(
                        title: "Launch at Login",
                        subtitle: "Keep the menu-bar timer ready after restart.",
                        theme: previewTheme,
                        isOn: $launchAtLoginEnabled
                    )
                }
                .frame(maxWidth: .infinity)

                automationPreview
                    .frame(width: 190)
            }
            .padding(.horizontal, 34)
        }
    }

    private var automationPreview: some View {
        OnboardingPanel(theme: previewTheme) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: autoStartNextSession ? "forward.fill" : "pause.fill")
                        .font(.system(size: 11))
                        .foregroundColor(previewTheme.workAccent)
                    Text(autoStartNextSession ? "Continuous flow" : "Manual breaks")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(previewTheme.textColor)
                }

                VStack(spacing: 6) {
                    automationStep("Focus", active: true, color: previewTheme.workAccent)
                    automationStep("Break", active: autoStartNextSession, color: previewTheme.breakAccent)
                    automationStep("Next focus", active: autoStartNextSession, color: previewTheme.workAccent)
                }
            }
        }
    }

    private func automationStep(_ title: String, active: Bool, color: Color) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(active ? color : previewTheme.textColor.opacity(0.18))
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 10, weight: active ? .semibold : .regular))
                .foregroundColor(active ? previewTheme.textColor : previewTheme.textColor.opacity(0.45))
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(active ? color.opacity(0.12) : previewTheme.textColor.opacity(0.04))
        )
    }
}

// MARK: - Page 6 - Sounds

extension OnboardingView {
    private var generatedSoundChoices: [OnboardingSoundChoice] {
        [.generated(.white), .generated(.brown), .generated(.pink)]
    }

    private var ambientSoundChoices: [OnboardingSoundChoice] {
        [.ambient(.forest), .ambient(.train), .ambient(.library)]
    }

    var page6View: some View {
        VStack(spacing: 12) {
            onboardingTitle(
                "Sounds",
                subtitle: "Enable focus audio now, or keep the timer quiet."
            )

            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 10) {
                    OnboardingToggleRow(
                        title: "Enable Sounds",
                        subtitle: "Adds the sound button to the timer surface.",
                        theme: previewTheme,
                        isOn: $soundControlsEnabled
                    )

                    soundVolumePanel
                }
                .frame(maxWidth: .infinity)

                soundSelectionPanel
                    .frame(width: 236)
            }
            .padding(.horizontal, 28)
        }
    }

    private var soundVolumePanel: some View {
        OnboardingPanel(theme: previewTheme) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Volume")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(previewTheme.textColor)
                    Spacer()
                    Text("\(Int((soundVolume * 100).rounded()))%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(previewTheme.textColor.opacity(0.58))
                        .monospacedDigit()
                }

                Slider(value: $soundVolume, in: 0...1, step: 0.01)
                    .tint(previewTheme.workAccent)
                    .controlSize(.small)
                    .disabled(!soundControlsEnabled)
                    .opacity(soundControlsEnabled ? 1 : 0.45)
            }
        }
    }

    private var soundSelectionPanel: some View {
        OnboardingPanel(theme: previewTheme) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Generated Noise")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(previewTheme.textColor.opacity(0.58))

                HStack(spacing: 6) {
                    ForEach(generatedSoundChoices, id: \.self) { choice in
                        soundChoiceButton(choice)
                    }
                }

                Text("Bundled")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(previewTheme.textColor.opacity(0.58))
                    .padding(.top, 2)

                HStack(spacing: 6) {
                    ForEach(ambientSoundChoices, id: \.self) { choice in
                        soundChoiceButton(choice)
                    }
                }
            }
            .opacity(soundControlsEnabled ? 1 : 0.45)
        }
    }

    private func soundChoiceButton(_ choice: OnboardingSoundChoice) -> some View {
        OnboardingChoiceButton(
            title: choice.title,
            systemImage: choice.systemImage,
            theme: previewTheme,
            isSelected: selectedSoundChoice == choice
        ) {
            soundControlsEnabled = true
            selectedSoundChoice = choice
        }
    }
}

// MARK: - Page 7 - Widgets

extension OnboardingView {
    var page7View: some View {
        VStack(spacing: 13) {
            onboardingTitle(
                "Widgets",
                subtitle: "Droplet now has desktop glances for progress, streaks, and timer state."
            )

            HStack(spacing: 10) {
                widgetCard(
                    title: "Today",
                    subtitle: "Goal progress",
                    systemImage: "drop.fill",
                    accent: previewTheme.workAccent
                )

                widgetCard(
                    title: "Streak Garden",
                    subtitle: "Month view",
                    systemImage: "calendar",
                    accent: previewTheme.breakAccent
                )

                widgetCard(
                    title: "Timer Bucket",
                    subtitle: "Start focus",
                    systemImage: "play.circle.fill",
                    accent: previewTheme.workAccent
                )
            }
            .padding(.horizontal, 24)

            Text("The same theme, goal, and gradient setting are shared with widgets.")
                .font(.system(size: 10))
                .foregroundColor(previewTheme.textColor.opacity(0.54))
        }
    }

    private func widgetCard(title: String, subtitle: String, systemImage: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(accent)
                Spacer()
                Circle()
                    .fill(accent.opacity(0.35))
                    .frame(width: 10, height: 10)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(previewTheme.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(previewTheme.textColor.opacity(0.55))
                    .lineLimit(1)
            }

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(previewTheme.textColor.opacity(0.12))
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 3)
                    .fill(accent.opacity(0.9))
                    .frame(width: 48, height: 4)
            }
        }
        .padding(12)
        .frame(height: 130)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(previewTheme.textColor.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(previewTheme.textColor.opacity(0.08), lineWidth: 1)
        )
    }
}
