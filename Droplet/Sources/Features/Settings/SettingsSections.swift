import SwiftUI

struct SettingsModeSection: View {
    @ObservedObject var settings = SettingsManager.shared

    var body: some View {
        MacSettingsSection(title: "Mode", theme: settings.selectedTheme) {
            MacToggleRow(label: "Infinity Mode", theme: settings.selectedTheme, isOn: $settings.infinityMode)
        }
    }
}

struct TimerSettingsSection: View {
    @ObservedObject var settings = SettingsManager.shared

    private let workDurationDefaults = [10, 15, 20, 25, 30, 45, 50, 60]
    private let breakDurationDefaults = [3, 5, 10, 15]
    private let longBreakDurationDefaults = [10, 15, 20, 30]
    private let workflowOptions = [2, 3, 4, 5]

    var body: some View {
        MacSettingsSection(title: "Timer", theme: settings.selectedTheme) {
            durationRow(label: "Work", selection: $settings.workDuration, options: workDurationOptions)
            durationRow(label: "Break", selection: $settings.shortBreakDuration, options: breakDurationOptions)
            durationRow(label: "Long Break", selection: $settings.longBreakDuration, options: longBreakDurationOptions)

            MacSettingRow(label: "Workflows", theme: settings.selectedTheme) {
                Picker("", selection: $settings.workflowCount) {
                    ForEach(workflowOptions, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
                .macSettingsPicker(width: 60)
            }
        }
    }

    private var workDurationOptions: [Int] {
        (workDurationDefaults + settings.customWorkDurations).sorted()
    }

    private var breakDurationOptions: [Int] {
        (breakDurationDefaults + settings.customBreakDurations).sorted()
    }

    private var longBreakDurationOptions: [Int] {
        (longBreakDurationDefaults + settings.customLongBreakDurations).sorted()
    }

    private func durationRow(label: String, selection: Binding<Int>, options: [Int]) -> some View {
        MacSettingRow(label: label, theme: settings.selectedTheme) {
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { minutes in
                    Text("\(minutes) min").tag(minutes)
                }
            }
            .macSettingsPicker(width: 90)
        }
    }
}

struct CustomDurationsSettingsSection: View {
    @ObservedObject var settings = SettingsManager.shared
    @State private var newDurationText = ""
    @State private var newDurationType = "Work"

    private let workDurationDefaults = [10, 15, 20, 25, 30, 45, 50, 60]
    private let breakDurationDefaults = [3, 5, 10, 15]
    private let longBreakDurationDefaults = [10, 15, 20, 30]
    private let durationTypes = ["Work", "Break", "Long Break"]

    var body: some View {
        MacSettingsSection(title: "Custom Durations", theme: settings.selectedTheme) {
            addDurationRow

            ForEach(settings.customWorkDurations.sorted(), id: \.self) { minutes in
                customDurationRow(label: "Work", minutes: minutes) {
                    settings.customWorkDurations.removeAll { $0 == minutes }
                }
            }
            ForEach(settings.customBreakDurations.sorted(), id: \.self) { minutes in
                customDurationRow(label: "Break", minutes: minutes) {
                    settings.customBreakDurations.removeAll { $0 == minutes }
                }
            }
            ForEach(settings.customLongBreakDurations.sorted(), id: \.self) { minutes in
                customDurationRow(label: "Long Break", minutes: minutes) {
                    settings.customLongBreakDurations.removeAll { $0 == minutes }
                }
            }
        }
    }

    private var addDurationRow: some View {
        HStack(spacing: 6) {
            Picker("", selection: $newDurationType) {
                ForEach(durationTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .macSettingsPicker(width: 100)

            TextField("min", text: $newDurationText)
                .macInlineTextField(theme: settings.selectedTheme, width: 40)

            Button(action: addCustomDuration) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(settings.selectedTheme.workAccent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func customDurationRow(label: String, minutes: Int, onDelete: @escaping () -> Void) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
            Text("\(minutes) min")
                .font(.system(size: 12))
                .foregroundColor(settings.selectedTheme.textColor)
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private func addCustomDuration() {
        guard let minutes = Int(newDurationText), minutes > 0 else { return }
        switch newDurationType {
        case "Work":
            if !workDurationDefaults.contains(minutes) && !settings.customWorkDurations.contains(minutes) {
                settings.customWorkDurations.append(minutes)
            }
        case "Break":
            if !breakDurationDefaults.contains(minutes) && !settings.customBreakDurations.contains(minutes) {
                settings.customBreakDurations.append(minutes)
            }
        case "Long Break":
            if !longBreakDurationDefaults.contains(minutes) && !settings.customLongBreakDurations.contains(minutes) {
                settings.customLongBreakDurations.append(minutes)
            }
        default:
            break
        }
        newDurationText = ""
    }
}

struct AppearanceSettingsSection: View {
    @ObservedObject var settings = SettingsManager.shared
    @State private var fontSizeText = ""

    private let themeColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        MacSettingsSection(title: "Appearance", theme: settings.selectedTheme) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Theme")
                    .font(.system(size: 12))
                    .foregroundColor(settings.selectedTheme.textColor)

                LazyVGrid(columns: themeColumns, spacing: 8) {
                    ForEach(Theme.allCases) { theme in
                        MacThemeSwatchButton(
                            option: theme,
                            currentTheme: settings.selectedTheme,
                            isSelected: theme == settings.selectedTheme
                        ) {
                            settings.selectedTheme = theme
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)

            MacToggleRow(
                label: "Gradient",
                theme: settings.selectedTheme,
                isOn: Binding(
                    get: { settings.gradientEnabled },
                    set: { settings.setGradientEnabled($0) }
                )
            )
            MacToggleRow(label: "Glow", theme: settings.selectedTheme, isOn: $settings.enableGlow)

            MacSettingRow(label: "Font Size", theme: settings.selectedTheme) {
                boundedNumberField(
                    hint: "(16-80)",
                    suffix: "pt",
                    text: $fontSizeText,
                    range: 16...80,
                    currentValue: settings.timerFontSize,
                    setValue: { settings.timerFontSize = $0 }
                )
                .onAppear {
                    fontSizeText = String(Int(settings.timerFontSize))
                }
            }

            MacSettingRow(label: "Fullscreen Font", theme: settings.selectedTheme) {
                boundedNumberField(
                    hint: "(80-400)",
                    suffix: "pt",
                    text: Binding(
                        get: { String(Int(settings.fullscreenFontSize)) },
                        set: { newValue in
                            if let size = Int(newValue), (80...400).contains(size) {
                                settings.fullscreenFontSize = Double(size)
                            }
                        }
                    ),
                    range: 80...400,
                    currentValue: settings.fullscreenFontSize,
                    setValue: { settings.fullscreenFontSize = $0 }
                )
            }

            MacSettingRow(label: "Font Weight", theme: settings.selectedTheme) {
                Picker("", selection: $settings.timerFontWeightRaw) {
                    Text("Thin").tag("Thin")
                    Text("Light").tag("Light")
                    Text("Regular").tag("Regular")
                    Text("Medium").tag("Medium")
                    Text("DemiBold").tag("DemiBold")
                    Text("Bold").tag("Bold")
                }
                .macSettingsPicker(width: 100)
            }

            MacToggleRow(label: "Show Progress Bar", theme: settings.selectedTheme, isOn: $settings.showProgressBar)
            MacToggleRow(label: "Timer Controls", theme: settings.selectedTheme, isOn: $settings.showTimerControls)
            MacToggleRow(label: "Menu Bar Timer", theme: settings.selectedTheme, isOn: $settings.showMenuBarTimer)
        }
    }

    private func boundedNumberField(
        hint: String,
        suffix: String,
        text: Binding<String>,
        range: ClosedRange<Int>,
        currentValue: Double,
        setValue: @escaping (Double) -> Void
    ) -> some View {
        HStack(spacing: 4) {
            Text(hint)
                .font(.system(size: 9))
                .foregroundColor(settings.selectedTheme.textColor.opacity(0.4))
            TextField("", text: Binding(
                get: { text.wrappedValue },
                set: { newValue in
                    text.wrappedValue = newValue
                    if let size = Int(newValue), range.contains(size) {
                        setValue(Double(size))
                    }
                }
            ))
            .macInlineTextField(theme: settings.selectedTheme, width: 40)
            Text(suffix)
                .font(.system(size: 10))
                .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
        }
    }
}

struct MusicSettingsSection: View {
    @ObservedObject var settings = SettingsManager.shared

    var body: some View {
        MacSettingsSection(title: "Music", theme: settings.selectedTheme) {
            MacToggleRow(label: "Music Controls", theme: settings.selectedTheme, isOn: $settings.showMusicControls)

            MacSettingRow(label: "App", theme: settings.selectedTheme) {
                Picker("", selection: $settings.musicApp) {
                    Text("Spotify").tag("Spotify")
                    Text("Apple Music").tag("Apple Music")
                }
                .macSettingsPicker(width: 110)
            }
        }
    }
}

struct SoundSettingsSection: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var soundManager = SoundManager.shared

    var body: some View {
        MacSettingsSection(title: "Sounds", theme: settings.selectedTheme) {
            MacToggleRow(label: "Enable Sounds", theme: settings.selectedTheme, isOn: $settings.soundControlsEnabled)
                .onChange(of: settings.soundControlsEnabled) { isEnabled in
                    if !isEnabled {
                        soundManager.stop()
                    }
                }
            MacToggleRow(label: "Pause Sound on Timer Pause", theme: settings.selectedTheme, isOn: $settings.pauseSoundsOnTimerPause)
        }
    }
}

struct BehaviorSettingsSection: View {
    @ObservedObject var settings = SettingsManager.shared

    var body: some View {
        MacSettingsSection(title: "Behavior", theme: settings.selectedTheme) {
            MacToggleRow(label: "Auto-Start Sessions", theme: settings.selectedTheme, isOn: $settings.autoStartNextSession)
            MacToggleRow(label: "Always on Top", theme: settings.selectedTheme, isOn: $settings.alwaysOnTop)
            MacToggleRow(label: "Click Actions", theme: settings.selectedTheme, isOn: $settings.enableClickActions)
            MacToggleRow(label: "20-20-20 Rule (Eye Health)", theme: settings.selectedTheme, isOn: $settings.enable202020Rule)

            MacSettingRow(label: "Launch at Login", theme: settings.selectedTheme) {
                Toggle("", isOn: Binding(
                    get: { LaunchAtLoginManager.shared.isEnabled },
                    set: { LaunchAtLoginManager.shared.setEnabled($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            MacSettingRow(label: "Onboarding", theme: settings.selectedTheme) {
                MacSettingsActionButton(
                    title: "Revisit",
                    systemImage: "arrow.counterclockwise",
                    theme: settings.selectedTheme
                ) {
                    NotificationCenter.default.post(name: Notification.Name("ShowOnboardingNotification"), object: nil)
                }
            }
        }
    }
}
