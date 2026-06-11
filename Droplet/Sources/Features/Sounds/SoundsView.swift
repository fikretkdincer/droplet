import SwiftUI

struct SoundsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @ObservedObject private var soundManager = SoundManager.shared

    private let generatedNoiseRows: [[GeneratedNoise]] = [
        [.white, .brown, .pink],
        [.green, .blue, .violet]
    ]
    private let buttonColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            MacNavigationHeader(
                title: "Sounds",
                theme: settings.selectedTheme,
                backAction: { settings.navigateTo(.timer) }
            )

            ScrollView {
                VStack(spacing: 14) {
                    playbackSection
                    generatedNoiseSection
                    bundledSoundsSection
                    customSoundsSection
                }
                .padding(12)
            }
        }
    }

    private var playbackSection: some View {
        MacSettingsSection(title: "Playback", theme: settings.selectedTheme) {
            HStack(spacing: 10) {
                Button(action: { soundManager.toggle() }) {
                    Label(soundManager.isPlaying ? "Pause" : "Play", systemImage: soundManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(settings.selectedTheme.backgroundColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(soundManager.canTogglePlayback ? settings.selectedTheme.workAccent : settings.selectedTheme.textColor.opacity(0.2))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!soundManager.canTogglePlayback)

                Text(soundManager.currentSelectionTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.68))
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            MacSettingsSliderRow(
                label: "Volume",
                valueText: "\(Int((Double(soundManager.volume) * 100).rounded()))%",
                theme: settings.selectedTheme,
                value: Binding(
                    get: { Double(soundManager.volume) },
                    set: { soundManager.setVolume(Float($0)) }
                )
            )
        }
    }

    private var generatedNoiseSection: some View {
        MacSettingsSection(title: "Generated Noise", theme: settings.selectedTheme) {
            VStack(spacing: 8) {
                ForEach(generatedNoiseRows, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(row) { noise in
                            SoundChoiceButton(
                                title: noise.shortTitle,
                                systemImage: noise.systemImage,
                                theme: settings.selectedTheme,
                                isSelected: soundManager.currentGeneratedNoise == noise,
                                isPlaying: soundManager.currentGeneratedNoise == noise && soundManager.isPlaying
                            ) {
                                soundManager.playGenerated(noise)
                            }
                        }
                    }
                }
            }
            .padding(10)
        }
    }

    private var bundledSoundsSection: some View {
        MacSettingsSection(title: "Bundled Sounds", theme: settings.selectedTheme) {
            LazyVGrid(columns: buttonColumns, spacing: 8) {
                ForEach(AmbientSound.allCases.filter { $0 != .none }) { sound in
                    SoundChoiceButton(
                        title: sound.rawValue,
                        systemImage: sound.systemImage,
                        theme: settings.selectedTheme,
                        isSelected: soundManager.currentSound == sound,
                        isPlaying: soundManager.currentSound == sound && soundManager.isPlaying
                    ) {
                        soundManager.play(sound)
                    }
                }
            }
            .padding(10)
        }
    }

    private var customSoundsSection: some View {
        MacSettingsSection(title: "Custom Sounds", theme: settings.selectedTheme) {
            VStack(spacing: 0) {
                HStack {
                    Text(customSoundsSummary)
                        .font(.system(size: 12))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.62))

                    Spacer()

                    MacSettingsActionButton(
                        title: "Import",
                        systemImage: "plus.circle.fill",
                        theme: settings.selectedTheme
                    ) {
                        soundManager.importSound()
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

                ForEach(soundManager.customSounds) { sound in
                    customSoundRow(sound)
                }
            }
        }
    }

    private var customSoundsSummary: String {
        soundManager.customSounds.isEmpty ? "No custom sounds" : "\(soundManager.customSounds.count) imported"
    }

    private func customSoundRow(_ sound: CustomSound) -> some View {
        HStack(spacing: 8) {
            Button(action: { soundManager.playCustom(sound) }) {
                HStack(spacing: 7) {
                    Image(systemName: soundManager.currentCustomSound?.id == sound.id && soundManager.isPlaying ? "speaker.wave.2.fill" : "music.note")
                        .font(.system(size: 12))
                    Text(sound.name)
                        .font(.system(size: 12, weight: soundManager.currentCustomSound?.id == sound.id ? .semibold : .regular))
                        .lineLimit(1)
                }
                .foregroundColor(settings.selectedTheme.textColor.opacity(soundManager.currentCustomSound?.id == sound.id ? 1 : 0.72))
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: { soundManager.deleteCustomSound(sound) }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.65))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }
}

private struct SoundChoiceButton: View {
    let title: String
    let systemImage: String
    let theme: Theme
    let isSelected: Bool
    let isPlaying: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isPlaying ? "speaker.wave.2.fill" : systemImage)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(strokeColor, lineWidth: isSelected ? 1.4 : 1)
            )
            .contentShape(Rectangle())
            .scaleEffect(isHovering ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(title)
    }

    private var foregroundColor: Color {
        isSelected ? theme.workAccent : theme.textColor.opacity(0.72)
    }

    private var backgroundColor: Color {
        if isSelected {
            return theme.workAccent.opacity(isPlaying ? 0.2 : 0.14)
        }
        return theme.textColor.opacity(isHovering ? 0.1 : 0.06)
    }

    private var strokeColor: Color {
        if isSelected {
            return theme.workAccent.opacity(0.72)
        }
        return theme.textColor.opacity(isHovering ? 0.16 : 0.08)
    }
}

private extension GeneratedNoise {
    var shortTitle: String {
        rawValue.replacingOccurrences(of: " Noise", with: "")
    }

    var systemImage: String {
        switch self {
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
    }
}

private extension AmbientSound {
    var systemImage: String {
        switch self {
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
