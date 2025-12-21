import AppKit
import SwiftUI

/// Native NSMenu for settings - doesn't refresh with SwiftUI view updates
class SettingsMenu: NSObject {
    private let viewModel: PomodoroViewModel
    private let settings: SettingsManager
    
    init(viewModel: PomodoroViewModel, settings: SettingsManager) {
        self.viewModel = viewModel
        self.settings = settings
        super.init()
    }
    
    func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Sounds submenu
        let soundsMenu = NSMenu()
        
        // Built-in sounds
        for sound in AmbientSound.allCases {
            let item = NSMenuItem(title: sound.rawValue, action: #selector(selectSound(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = sound
            if SoundManager.shared.currentSound == sound && sound != .none && SoundManager.shared.currentCustomSound == nil {
                item.state = .on
            }
            soundsMenu.addItem(item)
        }
        
        // Custom sounds section
        let customSounds = SoundManager.shared.customSounds
        if !customSounds.isEmpty {
            soundsMenu.addItem(NSMenuItem.separator())
            
            for sound in customSounds {
                let item = NSMenuItem(title: sound.name, action: #selector(selectCustomSound(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = sound
                if SoundManager.shared.currentCustomSound?.id == sound.id {
                    item.state = .on
                }
                soundsMenu.addItem(item)
            }
        }
        
        soundsMenu.addItem(NSMenuItem.separator())
        
        // Import Sound
        let importSound = NSMenuItem(title: "Import Sound...", action: #selector(importSound), keyEquivalent: "")
        importSound.target = self
        soundsMenu.addItem(importSound)
        
        // Delete Sounds submenu (only if there are custom sounds)
        if !customSounds.isEmpty {
            let deleteMenu = NSMenu()
            for sound in customSounds {
                let item = NSMenuItem(title: sound.name, action: #selector(deleteCustomSound(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = sound
                deleteMenu.addItem(item)
            }
            let deleteItem = NSMenuItem(title: "Delete Sound", action: nil, keyEquivalent: "")
            deleteItem.submenu = deleteMenu
            soundsMenu.addItem(deleteItem)
        }
        
        soundsMenu.addItem(NSMenuItem.separator())
        
        // Pause sounds when timer paused toggle
        let pauseOnPause = NSMenuItem(title: "Pause When Paused", action: #selector(togglePauseSoundsOnTimerPause), keyEquivalent: "")
        pauseOnPause.target = self
        pauseOnPause.state = settings.pauseSoundsOnTimerPause ? .on : .off
        soundsMenu.addItem(pauseOnPause)
        
        soundsMenu.addItem(NSMenuItem.separator())
        
        let volumeUp = NSMenuItem(title: "Volume Up", action: #selector(volumeUp), keyEquivalent: "")
        volumeUp.target = self
        volumeUp.isEnabled = SoundManager.shared.isPlaying
        soundsMenu.addItem(volumeUp)
        let volumeDown = NSMenuItem(title: "Volume Down", action: #selector(volumeDown), keyEquivalent: "")
        volumeDown.target = self
        volumeDown.isEnabled = SoundManager.shared.isPlaying
        soundsMenu.addItem(volumeDown)
        
        let soundsItem = NSMenuItem(title: "Sounds", action: nil, keyEquivalent: "")
        soundsItem.submenu = soundsMenu
        menu.addItem(soundsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Work Duration
        let workMenu = NSMenu()
        for minutes in [1, 10, 15, 20, 25, 30, 45, 50, 60] {
            let item = NSMenuItem(title: "\(minutes) min", action: #selector(setWorkDuration(_:)), keyEquivalent: "")
            item.target = self
            item.tag = minutes
            if settings.workDuration == minutes { item.state = .on }
            workMenu.addItem(item)
        }
        let workItem = NSMenuItem(title: "Work Duration", action: nil, keyEquivalent: "")
        workItem.submenu = workMenu
        menu.addItem(workItem)
        
        // Break Duration
        let breakMenu = NSMenu()
        for minutes in [1, 3, 5, 10, 15] {
            let item = NSMenuItem(title: "\(minutes) min", action: #selector(setBreakDuration(_:)), keyEquivalent: "")
            item.target = self
            item.tag = minutes
            if settings.shortBreakDuration == minutes { item.state = .on }
            breakMenu.addItem(item)
        }
        let breakItem = NSMenuItem(title: "Break Duration", action: nil, keyEquivalent: "")
        breakItem.submenu = breakMenu
        menu.addItem(breakItem)
        
        // Long Break Duration
        let longBreakMenu = NSMenu()
        for minutes in [10, 15, 20, 30] {
            let item = NSMenuItem(title: "\(minutes) min", action: #selector(setLongBreakDuration(_:)), keyEquivalent: "")
            item.target = self
            item.tag = minutes
            if settings.longBreakDuration == minutes { item.state = .on }
            longBreakMenu.addItem(item)
        }
        let longBreakItem = NSMenuItem(title: "Long Break Duration", action: nil, keyEquivalent: "")
        longBreakItem.submenu = longBreakMenu
        menu.addItem(longBreakItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Workflows
        let workflowMenu = NSMenu()
        for count in [2, 3, 4, 5, 6] {
            let item = NSMenuItem(title: "\(count) workflows", action: #selector(setWorkflowCount(_:)), keyEquivalent: "")
            item.target = self
            item.tag = count
            if settings.workflowCount == count { item.state = .on }
            workflowMenu.addItem(item)
        }
        let workflowItem = NSMenuItem(title: "Workflows Before Long Break", action: nil, keyEquivalent: "")
        workflowItem.submenu = workflowMenu
        menu.addItem(workflowItem)
        
        // End Session
        let endSession = NSMenuItem(title: "End Session", action: #selector(endSession), keyEquivalent: "")
        endSession.target = self
        menu.addItem(endSession)
        
        menu.addItem(NSMenuItem.separator())
        
        // Toggles
        let autoStart = NSMenuItem(title: "Auto-start Next Session", action: #selector(toggleAutoStart), keyEquivalent: "")
        autoStart.target = self
        autoStart.state = settings.autoStartNextSession ? .on : .off
        menu.addItem(autoStart)
        
        let alwaysOnTop = NSMenuItem(title: "Always on Top", action: #selector(toggleAlwaysOnTop), keyEquivalent: "")
        alwaysOnTop.target = self
        alwaysOnTop.state = settings.alwaysOnTop ? .on : .off
        menu.addItem(alwaysOnTop)
        
        let launchAtLogin = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLogin.target = self
        launchAtLogin.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
        menu.addItem(launchAtLogin)
        
        menu.addItem(NSMenuItem.separator())
        
        // Theme submenu
        let themeMenu = NSMenu()
        for theme in Theme.allCases {
            let item = NSMenuItem(title: theme.rawValue, action: #selector(selectTheme(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = theme
            if settings.selectedTheme == theme { item.state = .on }
            themeMenu.addItem(item)
        }
        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        themeItem.submenu = themeMenu
        menu.addItem(themeItem)
        
        // Visuals submenu
        let visualsMenu = NSMenu()
        let fontMenu = NSMenu()
        for size in [16, 24, 32, 42, 52, 64] {
            let item = NSMenuItem(title: "\(size)px", action: #selector(setFontSize(_:)), keyEquivalent: "")
            item.target = self
            item.tag = size
            if Int(settings.timerFontSize) == size { item.state = .on }
            fontMenu.addItem(item)
        }
        let fontItem = NSMenuItem(title: "Font Size", action: nil, keyEquivalent: "")
        fontItem.submenu = fontMenu
        visualsMenu.addItem(fontItem)
        visualsMenu.addItem(NSMenuItem.separator())
        let glow = NSMenuItem(title: "Enable Glow", action: #selector(toggleGlow), keyEquivalent: "")
        glow.target = self
        glow.state = settings.enableGlow ? .on : .off
        visualsMenu.addItem(glow)
        let progressBar = NSMenuItem(title: "Show Progress Bar", action: #selector(toggleProgressBar), keyEquivalent: "")
        progressBar.target = self
        progressBar.state = settings.showProgressBar ? .on : .off
        visualsMenu.addItem(progressBar)
        let timerControls = NSMenuItem(title: "Timer Controls", action: #selector(toggleTimerControls), keyEquivalent: "")
        timerControls.target = self
        timerControls.state = settings.showTimerControls ? .on : .off
        visualsMenu.addItem(timerControls)
        let visualsItem = NSMenuItem(title: "Visuals", action: nil, keyEquivalent: "")
        visualsItem.submenu = visualsMenu
        menu.addItem(visualsItem)
        
        // Music submenu
        let musicMenu = NSMenu()
        let showMusicControls = NSMenuItem(title: "Show Music Controls", action: #selector(toggleMusicControls), keyEquivalent: "")
        showMusicControls.target = self
        showMusicControls.state = settings.showMusicControls ? .on : .off
        musicMenu.addItem(showMusicControls)
        musicMenu.addItem(NSMenuItem.separator())
        for app in ["Spotify", "Apple Music"] {
            let item = NSMenuItem(title: app, action: #selector(selectMusicApp(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = app
            if settings.musicApp == app { item.state = .on }
            musicMenu.addItem(item)
        }
        let musicItem = NSMenuItem(title: "Music", action: nil, keyEquivalent: "")
        musicItem.submenu = musicMenu
        menu.addItem(musicItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Goal Tracker
        let goalTracker = NSMenuItem(title: "Goal Tracker", action: #selector(openGoalTracker), keyEquivalent: "")
        goalTracker.target = self
        menu.addItem(goalTracker)
        
        menu.addItem(NSMenuItem.separator())
        
        // Check for Updates
        let updates = NSMenuItem(title: "Check for Updates", action: #selector(checkForUpdates), keyEquivalent: "")
        updates.target = self
        menu.addItem(updates)
        
        // Quit
        let quit = NSMenuItem(title: "Quit droplet", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        
        return menu
    }
    
    // MARK: - Actions
    
    @objc func selectSound(_ sender: NSMenuItem) {
        if let sound = sender.representedObject as? AmbientSound {
            if sound == .none {
                SoundManager.shared.stop()
                SoundManager.shared.currentSound = .none
            } else {
                SoundManager.shared.play(sound)
            }
        }
    }
    
    @objc func volumeUp() { SoundManager.shared.volumeUp() }
    @objc func volumeDown() { SoundManager.shared.volumeDown() }
    
    @objc func setWorkDuration(_ sender: NSMenuItem) { settings.workDuration = sender.tag }
    @objc func setBreakDuration(_ sender: NSMenuItem) { settings.shortBreakDuration = sender.tag }
    @objc func setLongBreakDuration(_ sender: NSMenuItem) { settings.longBreakDuration = sender.tag }
    @objc func setWorkflowCount(_ sender: NSMenuItem) { settings.workflowCount = sender.tag }
    
    @objc func endSession() { viewModel.endCurrentSession() }
    
    @objc func toggleAutoStart() { settings.autoStartNextSession.toggle() }
    @objc func toggleAlwaysOnTop() { settings.alwaysOnTop.toggle() }
    @objc func toggleLaunchAtLogin() { LaunchAtLoginManager.shared.setEnabled(!LaunchAtLoginManager.shared.isEnabled) }
    
    @objc func selectTheme(_ sender: NSMenuItem) {
        if let theme = sender.representedObject as? Theme {
            settings.selectedTheme = theme
        }
    }
    
    @objc func setFontSize(_ sender: NSMenuItem) { settings.timerFontSize = Double(sender.tag) }
    @objc func toggleGlow() { settings.enableGlow.toggle() }
    @objc func toggleProgressBar() { settings.showProgressBar.toggle() }
    @objc func toggleTimerControls() { settings.showTimerControls.toggle() }
    
    @objc func checkForUpdates() { UpdateManager.shared.checkForUpdates() }
    @objc func quitApp() { NSApplication.shared.terminate(nil) }
    
    @objc func toggleMusicControls() { settings.showMusicControls.toggle() }
    @objc func selectMusicApp(_ sender: NSMenuItem) {
        if let app = sender.representedObject as? String {
            settings.musicApp = app
        }
    }
    
    @objc func togglePauseSoundsOnTimerPause() { settings.pauseSoundsOnTimerPause.toggle() }
    
    @objc func openGoalTracker() {
        let goalTracker = GoalTracker.shared
        
        if goalTracker.hasGoalSet {
            settings.navigateTo(.weeklyProgress)
        } else {
            settings.navigateTo(.goalSetup)
        }
    }
    
    // MARK: - Custom Sound Actions
    
    @objc func selectCustomSound(_ sender: NSMenuItem) {
        if let sound = sender.representedObject as? CustomSound {
            SoundManager.shared.playCustom(sound)
        }
    }
    
    @objc func importSound() {
        SoundManager.shared.importSound()
    }
    
    @objc func deleteCustomSound(_ sender: NSMenuItem) {
        if let sound = sender.representedObject as? CustomSound {
            let alert = NSAlert()
            alert.messageText = "Delete '\(sound.name)'?"
            alert.informativeText = "This will permanently remove the sound file."
            alert.addButton(withTitle: "Delete")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .warning
            
            if alert.runModal() == .alertFirstButtonReturn {
                SoundManager.shared.deleteCustomSound(sound)
            }
        }
    }
}
