import SwiftUI
import ServiceManagement

/// Dedicated Settings view with organized sections
struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    @State private var fontSizeText: String = ""
    
    let workDurationOptions = [10, 15, 20, 25, 30, 45, 50, 60]
    let breakDurationOptions = [3, 5, 10, 15]
    let longBreakDurationOptions = [10, 15, 20, 30]
    let workflowOptions = [2, 3, 4, 5]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
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
                    toggleRow(label: "Pause Sound on Timer Pause", isOn: $settings.pauseSoundsOnTimerPause)
                }
                
                // Behavior Section
                settingsSection(title: "Behavior") {
                    toggleRow(label: "Auto-Start Sessions", isOn: $settings.autoStartNextSession)
                    toggleRow(label: "Always on Top", isOn: $settings.alwaysOnTop)
                    
                    settingRow(label: "Launch at Login") {
                        Toggle("", isOn: Binding(
                            get: { LaunchAtLoginManager.shared.isEnabled },
                            set: { LaunchAtLoginManager.shared.setEnabled($0) }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }
                }
            }
            .padding(12)
        }
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
