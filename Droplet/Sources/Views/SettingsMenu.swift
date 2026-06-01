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
        
        // Mini-Floater: Show minimal menu with just the toggle option
        if settings.miniFloaterMode {
            let miniFloater = NSMenuItem(title: "Exit Mini Mode", action: #selector(toggleMiniFloater), keyEquivalent: "")
            miniFloater.target = self
            menu.addItem(miniFloater)
            
            menu.addItem(NSMenuItem.separator())
            
            let quit = NSMenuItem(title: "Quit droplet", action: #selector(quitApp), keyEquivalent: "q")
            quit.target = self
            menu.addItem(quit)
            
            return menu
        }
        
        // Regular menu when not in Mini-Floater mode
        
        // Settings at top
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Goal Tracker
        let goalTracker = NSMenuItem(title: "Goal Tracker", action: #selector(openGoalTracker), keyEquivalent: "")
        goalTracker.target = self
        menu.addItem(goalTracker)
        
        // Tasks
        let tasksItem = NSMenuItem(title: "Tasks", action: #selector(openTasks), keyEquivalent: "")
        tasksItem.target = self
        menu.addItem(tasksItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Sounds submenu — quick ambient sound switching
        let soundsMenu = NSMenu()
        
        // Built-in sounds
        for sound in AmbientSound.allCases {
            let item = NSMenuItem(title: sound.rawValue, action: #selector(selectSound(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = sound
            if sound == .none &&
                SoundManager.shared.currentSound == .none &&
                SoundManager.shared.currentCustomSound == nil &&
                SoundManager.shared.currentGeneratedNoise == nil {
                item.state = .on
            } else if SoundManager.shared.currentSound == sound &&
                        sound != .none &&
                        SoundManager.shared.currentCustomSound == nil &&
                        SoundManager.shared.currentGeneratedNoise == nil {
                item.state = .on
            }
            soundsMenu.addItem(item)
        }

        soundsMenu.addItem(NSMenuItem.separator())

        for noise in GeneratedNoise.allCases {
            let item = NSMenuItem(title: noise.rawValue, action: #selector(selectGeneratedNoise(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = noise
            if SoundManager.shared.currentGeneratedNoise == noise {
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
        
        // Import / Delete custom sounds
        let importSoundItem = NSMenuItem(title: "Import Sound...", action: #selector(importSound), keyEquivalent: "")
        importSoundItem.target = self
        soundsMenu.addItem(importSoundItem)
        
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

        // View / mode toggles
        let infinityItem = NSMenuItem(title: "Infinity Mode", action: #selector(toggleInfinityMode), keyEquivalent: "")
        infinityItem.target = self
        infinityItem.state = settings.infinityMode ? .on : .off
        menu.addItem(infinityItem)

        let miniFloater = NSMenuItem(title: "Mini-Floater Mode", action: #selector(toggleMiniFloater), keyEquivalent: "")
        miniFloater.target = self
        miniFloater.state = settings.miniFloaterMode ? .on : .off
        menu.addItem(miniFloater)

        let detailedView = NSMenuItem(title: "Detailed View", action: #selector(toggleDetailedView), keyEquivalent: "")
        detailedView.target = self
        detailedView.state = settings.detailedView ? .on : .off
        menu.addItem(detailedView)

        menu.addItem(NSMenuItem.separator())
        
        // Toggle Fullscreen
        let fullscreen = NSMenuItem(title: "Toggle Fullscreen", action: #selector(toggleFullscreen), keyEquivalent: "")
        fullscreen.target = self
        menu.addItem(fullscreen)
        
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

    @objc func toggleInfinityMode() {
        settings.infinityMode.toggle()
    }

    @objc func selectSound(_ sender: NSMenuItem) {
        if let sound = sender.representedObject as? AmbientSound {
            if sound == .none {
                SoundManager.shared.clearSelection()
            } else {
                SoundManager.shared.play(sound)
            }
        }
    }

    @objc func selectGeneratedNoise(_ sender: NSMenuItem) {
        if let noise = sender.representedObject as? GeneratedNoise {
            SoundManager.shared.playGenerated(noise)
        }
    }
    
    @objc func volumeUp() { SoundManager.shared.volumeUp() }
    @objc func volumeDown() { SoundManager.shared.volumeDown() }

    @objc func toggleFullscreen() {
        guard let window = SettingsManager.mainWindow else { return }
        window.toggleFullScreen(nil)
    }
    
    @objc func toggleMiniFloater() { settings.miniFloaterMode.toggle() }

    @objc func toggleDetailedView() {
        settings.detailedView.toggle()
        // Window resize is handled by handleSettingsChange in AppDelegate
    }
    
    @objc func checkForUpdates() { UpdateManager.shared.checkForUpdates() }
    @objc func quitApp() { NSApplication.shared.terminate(nil) }
    
    @objc func togglePauseSoundsOnTimerPause() { settings.pauseSoundsOnTimerPause.toggle() }
    
    @objc func openGoalTracker() {
        let goalTracker = GoalTracker.shared
        
        if goalTracker.hasGoalSet {
            settings.navigateTo(.weeklyProgress)
        } else {
            settings.navigateTo(.goalSetup)
        }
    }
    
    @objc func openTasks() {
        settings.navigateTo(.taskList)
    }
    
    @objc func openSettings() {
        settings.navigateTo(.settings)
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
