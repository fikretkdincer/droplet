import SwiftUI
import ServiceManagement

/// Dedicated Settings view with organized sections
struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var soundManager = SoundManager.shared
    
    @State private var fontSizeText: String = ""
    @State private var newDurationText: String = ""
    @State private var newDurationType: String = "Work"

    let workDurationDefaults = [10, 15, 20, 25, 30, 45, 50, 60]
    let breakDurationDefaults = [3, 5, 10, 15]
    let longBreakDurationDefaults = [10, 15, 20, 30]
    let workflowOptions = [2, 3, 4, 5]
    let durationTypes = ["Work", "Break", "Long Break"]

    private var workDurationOptions: [Int] {
        (workDurationDefaults + settings.customWorkDurations).sorted()
    }
    private var breakDurationOptions: [Int] {
        (breakDurationDefaults + settings.customBreakDurations).sorted()
    }
    private var longBreakDurationOptions: [Int] {
        (longBreakDurationDefaults + settings.customLongBreakDurations).sorted()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed Header
            HStack {
                Button(action: { settings.navigateTo(.timer) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(settings.selectedTheme.textColor.opacity(0.7))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Settings")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(settings.selectedTheme.textColor)
                
                Spacer()
                
                Color.clear.frame(width: 14, height: 14)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(settings.selectedTheme.backgroundColor)
            
            // Scrollable Content
            ScrollView {
                VStack(spacing: 16) {
                    // Mode Section
                    settingsSection(title: "Mode") {
                        toggleRow(label: "Infinity Mode", isOn: $settings.infinityMode)
                    }

                    // Timer Section
                    settingsSection(title: "Timer") {
                        settingRow(label: "Work") {
                            Picker("", selection: $settings.workDuration) {
                                ForEach(workDurationOptions, id: \.self) { min in
                                    Text("\(min) min").tag(min)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 90)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }

                        settingRow(label: "Break") {
                            Picker("", selection: $settings.shortBreakDuration) {
                                ForEach(breakDurationOptions, id: \.self) { min in
                                    Text("\(min) min").tag(min)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 90)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }

                        settingRow(label: "Long Break") {
                            Picker("", selection: $settings.longBreakDuration) {
                                ForEach(longBreakDurationOptions, id: \.self) { min in
                                    Text("\(min) min").tag(min)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 90)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }
                        
                        settingRow(label: "Workflows") {
                            Picker("", selection: $settings.workflowCount) {
                                ForEach(workflowOptions, id: \.self) { count in
                                    Text("\(count)").tag(count)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 60)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }
                    }
                    
                    // Custom Durations Section
                    settingsSection(title: "Custom Durations") {
                        // Add new duration row
                        HStack(spacing: 6) {
                            Picker("", selection: $newDurationType) {
                                ForEach(durationTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 100)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))

                            TextField("min", text: $newDurationText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .foregroundColor(settings.selectedTheme.textColor)
                                .frame(width: 40)
                                .multilineTextAlignment(.center)
                                .padding(4)
                                .background(settings.selectedTheme.textColor.opacity(0.1))
                                .cornerRadius(4)

                            Button(action: addCustomDuration) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(settings.selectedTheme.workAccent)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)

                        // List custom durations with delete buttons
                        ForEach(settings.customWorkDurations.sorted(), id: \.self) { min in
                            customDurationRow(label: "Work", minutes: min) {
                                settings.customWorkDurations.removeAll { $0 == min }
                            }
                        }
                        ForEach(settings.customBreakDurations.sorted(), id: \.self) { min in
                            customDurationRow(label: "Break", minutes: min) {
                                settings.customBreakDurations.removeAll { $0 == min }
                            }
                        }
                        ForEach(settings.customLongBreakDurations.sorted(), id: \.self) { min in
                            customDurationRow(label: "Long Break", minutes: min) {
                                settings.customLongBreakDurations.removeAll { $0 == min }
                            }
                        }
                    }

                    // Appearance Section
                    settingsSection(title: "Appearance") {
                        settingRow(label: "Theme") {
                            Picker("", selection: $settings.selectedTheme) {
                                ForEach(Theme.allCases) { theme in
                                    Text(theme.rawValue).tag(theme)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 100)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }
                        
                        settingRow(label: "Font Size") {
                            HStack(spacing: 4) {
                                Text("(16-80)")
                                    .font(.system(size: 9))
                                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.4))
                                TextField("", text: $fontSizeText)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12))
                                    .foregroundColor(settings.selectedTheme.textColor)
                                    .frame(width: 40)
                                    .multilineTextAlignment(.center)
                                    .padding(4)
                                    .background(settings.selectedTheme.textColor.opacity(0.1))
                                    .cornerRadius(4)
                                    .onAppear {
                                        fontSizeText = String(Int(settings.timerFontSize))
                                    }
                                    .onChange(of: fontSizeText) { newValue in
                                        if let size = Int(newValue), size >= 16, size <= 80 {
                                            settings.timerFontSize = Double(size)
                                        }
                                    }
                                Text("pt")
                                    .font(.system(size: 10))
                                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
                            }
                        }
                        
                        settingRow(label: "Fullscreen Font") {
                            HStack(spacing: 4) {
                                Text("(80-400)")
                                    .font(.system(size: 9))
                                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.4))
                                TextField("", text: Binding(
                                    get: { String(Int(settings.fullscreenFontSize)) },
                                    set: { newValue in
                                        if let size = Int(newValue), size >= 80, size <= 400 {
                                            settings.fullscreenFontSize = Double(size)
                                        }
                                    }
                                ))
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12))
                                    .foregroundColor(settings.selectedTheme.textColor)
                                    .frame(width: 40)
                                    .multilineTextAlignment(.center)
                                    .padding(4)
                                    .background(settings.selectedTheme.textColor.opacity(0.1))
                                    .cornerRadius(4)
                                Text("pt")
                                    .font(.system(size: 10))
                                    .foregroundColor(settings.selectedTheme.textColor.opacity(0.6))
                            }
                        }
                        
                        settingRow(label: "Font Weight") {
                            Picker("", selection: $settings.timerFontWeightRaw) {
                                Text("Thin").tag("Thin")
                                Text("Light").tag("Light")
                                Text("Regular").tag("Regular")
                                Text("Medium").tag("Medium")
                                Text("DemiBold").tag("DemiBold")
                                Text("Bold").tag("Bold")
                            }
                            .labelsHidden()
                            .frame(width: 100)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }
                        
                        toggleRow(label: "Show Progress Bar", isOn: $settings.showProgressBar)
                        toggleRow(label: "Timer Controls", isOn: $settings.showTimerControls)
                        toggleRow(label: "Menu Bar Timer", isOn: $settings.showMenuBarTimer)
                        toggleRow(label: "Enable Glow", isOn: $settings.enableGlow)
                    }
                    
                    // Music Section
                    settingsSection(title: "Music") {
                        toggleRow(label: "Music Controls", isOn: $settings.showMusicControls)
                        
                        settingRow(label: "App") {
                            Picker("", selection: $settings.musicApp) {
                                Text("Spotify").tag("Spotify")
                                Text("Apple Music").tag("Apple Music")
                            }
                            .labelsHidden()
                            .frame(width: 110)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }
                    }
                    
                    // Sounds Section
                    settingsSection(title: "Sounds") {
                        settingRow(label: "Sound") {
                            Picker("", selection: Binding(
                                get: { soundManager.selectedSoundOptionId },
                                set: { soundManager.selectOption($0) }
                            )) {
                                ForEach(soundManager.soundOptions) { option in
                                    Text(option.title).tag(option.id)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 130)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }

                        toggleRow(label: "Pause Sound on Timer Pause", isOn: $settings.pauseSoundsOnTimerPause)
                    }
                    
                    // Behavior Section
                    settingsSection(title: "Behavior") {
                        toggleRow(label: "Auto-Start Sessions", isOn: $settings.autoStartNextSession)
                        toggleRow(label: "Always on Top", isOn: $settings.alwaysOnTop)
                        toggleRow(label: "Click Actions", isOn: $settings.enableClickActions)
                        toggleRow(label: "20-20-20 Rule (Eye Health)", isOn: $settings.enable202020Rule)
                        
                        settingRow(label: "Launch at Login") {
                            Toggle("", isOn: Binding(
                                get: { LaunchAtLoginManager.shared.isEnabled },
                                set: { LaunchAtLoginManager.shared.setEnabled($0) }
                            ))
                            .toggleStyle(.switch)
                            .labelsHidden()
                        }

                        settingRow(label: "Onboarding") {
                            Button("Revisit") {
                                NotificationCenter.default.post(name: Notification.Name("ShowOnboardingNotification"), object: nil)
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundColor(settings.selectedTheme.workAccent)
                        }
                    }
                }
                .padding(12)
            }
        }
    }
    
    // MARK: - Actions

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

    @ViewBuilder
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

    // MARK: - Helper Views
    
    @ViewBuilder
    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(settings.selectedTheme.textColor.opacity(0.5))
                .textCase(.uppercase)
            
            VStack(spacing: 0) {
                content()
            }
            .background(settings.selectedTheme.textColor.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private func settingRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(settings.selectedTheme.textColor)
            
            Spacer()
            
            content()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(settings.selectedTheme.textColor)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}
