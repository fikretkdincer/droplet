import Foundation
import SwiftUI
import AppKit

/// App view states for navigation
enum AppView {
    case timer
    case weeklyProgress
    case goalSetup
}

/// Settings manager using UserDefaults for persistence
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // Navigation state (not persisted)
    @Published var currentView: AppView = .timer
    
    // Saved window size when switching to goal tracker
    var savedTimerSize: CGSize?
    
    @AppStorage("workDuration") var workDuration: Int = 25
    @AppStorage("shortBreakDuration") var shortBreakDuration: Int = 5
    @AppStorage("longBreakDuration") var longBreakDuration: Int = 15
    @AppStorage("workflowCount") var workflowCount: Int = 4
    @AppStorage("autoStartNextSession") var autoStartNextSession: Bool = true
    @AppStorage("alwaysOnTop") var alwaysOnTop: Bool = false
    @AppStorage("selectedTheme") var selectedThemeRaw: String = "Dark"
    
    // Visual settings
    @AppStorage("timerFontSize") var timerFontSize: Double = 42
    @AppStorage("enableGlow") var enableGlow: Bool = false
    @AppStorage("showProgressBar") var showProgressBar: Bool = true
    @AppStorage("showTimerControls") var showTimerControls: Bool = false
    
    // Music settings
    @AppStorage("showMusicControls") var showMusicControls: Bool = true
    @AppStorage("musicApp") var musicApp: String = "Spotify"
    
    // Sound behavior
    @AppStorage("pauseSoundsOnTimerPause") var pauseSoundsOnTimerPause: Bool = true
    
    var selectedTheme: Theme {
        get { Theme(rawValue: selectedThemeRaw) ?? .dark }
        set { selectedThemeRaw = newValue.rawValue }
    }
    
    // Minimum sizes for goal tracker views
    let goalTrackerMinSize = CGSize(width: 280, height: 220)
    
    // Reference to main window (set by AppDelegate)
    static weak var mainWindow: NSWindow?
    
    func navigateTo(_ view: AppView) {
        // Get main window from static reference
        guard let window = SettingsManager.mainWindow else {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentView = view
            }
            return
        }
        
        // Save timer size when leaving timer view
        if currentView == .timer && view != .timer {
            savedTimerSize = window.frame.size
        }
        
        // Resize window based on target view
        if view == .timer {
            // Restore saved timer size
            if let saved = savedTimerSize {
                let newFrame = NSRect(
                    x: window.frame.origin.x,
                    y: window.frame.origin.y + (window.frame.height - saved.height),
                    width: saved.width,
                    height: saved.height
                )
                window.setFrame(newFrame, display: true, animate: true)
            }
        } else {
            // Ensure window is large enough for goal tracker
            let currentSize = window.frame.size
            if currentSize.width < goalTrackerMinSize.width || currentSize.height < goalTrackerMinSize.height {
                let newWidth = max(currentSize.width, goalTrackerMinSize.width)
                let newHeight = max(currentSize.height, goalTrackerMinSize.height)
                let newFrame = NSRect(
                    x: window.frame.origin.x,
                    y: window.frame.origin.y - (newHeight - currentSize.height),
                    width: newWidth,
                    height: newHeight
                )
                window.setFrame(newFrame, display: true, animate: true)
            }
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            currentView = view
        }
    }
    
    private init() {}
}
