import Foundation
import SwiftUI
import AppKit

/// App view states for navigation
enum AppView {
    case timer
    case weeklyProgress
    case goalSetup
    case taskList
    case addTask
    case settings
    case sounds
}

/// Settings manager using UserDefaults for persistence
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // Navigation state (not persisted)
    @Published var currentView: AppView = .timer
    @Published var fullscreenMode: Bool = false
    @Published var detailedViewPresented: Bool = false

    // Saved window size when switching to goal tracker
    var savedTimerSize: CGSize?

    @AppStorage("workDuration") var workDuration: Int = 25
    @AppStorage("shortBreakDuration") var shortBreakDuration: Int = 5
    @AppStorage("longBreakDuration") var longBreakDuration: Int = 15
    @AppStorage("workflowCount") var workflowCount: Int = 4
    @AppStorage("autoStartNextSession") var autoStartNextSession: Bool = true
    @AppStorage("alwaysOnTop") var alwaysOnTop: Bool = true
    @AppStorage("enableClickActions") var enableClickActions: Bool = false
    @AppStorage("selectedTheme") var selectedThemeRaw: String = "Dark"

    // Visual settings
    @AppStorage("timerFontSize") var timerFontSize: Double = 42
    @AppStorage("fullscreenFontSize") var fullscreenFontSize: Double = 120
    @AppStorage("timerFontWeight") var timerFontWeightRaw: String = "Medium"
    @AppStorage("enableGlow") var enableGlow: Bool = false
    @AppStorage("showProgressBar") var showProgressBar: Bool = true
    @AppStorage("showTimerControls") var showTimerControls: Bool = false
    @AppStorage("showMenuBarTimer") var showMenuBarTimer: Bool = false
    @AppStorage("gradientEnabled") private var gradientEnabledStorage: Bool = true
    @AppStorage("miniFloaterMode") var miniFloaterMode: Bool = false
    @AppStorage("detailedView") var detailedView: Bool = false
    @AppStorage("enable202020Rule") var enable202020Rule: Bool = false

    // Music settings
    @AppStorage("showMusicControls") var showMusicControls: Bool = true
    @AppStorage("musicApp") var musicApp: String = "Spotify"

    // Sound behavior
    @AppStorage("soundControlsEnabled") var soundControlsEnabled: Bool = false
    @AppStorage("pauseSoundsOnTimerPause") var pauseSoundsOnTimerPause: Bool = true

    // Mode
    @AppStorage("infinityMode") var infinityMode: Bool = false

    // Custom durations (stored as JSON arrays)
    @AppStorage("customWorkDurations") var customWorkDurationsData: String = "[]"
    @AppStorage("customBreakDurations") var customBreakDurationsData: String = "[]"
    @AppStorage("customLongBreakDurations") var customLongBreakDurationsData: String = "[]"

    var customWorkDurations: [Int] {
        get { (try? JSONDecoder().decode([Int].self, from: Data(customWorkDurationsData.utf8))) ?? [] }
        set { customWorkDurationsData = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }
    var customBreakDurations: [Int] {
        get { (try? JSONDecoder().decode([Int].self, from: Data(customBreakDurationsData.utf8))) ?? [] }
        set { customBreakDurationsData = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }
    var customLongBreakDurations: [Int] {
        get { (try? JSONDecoder().decode([Int].self, from: Data(customLongBreakDurationsData.utf8))) ?? [] }
        set { customLongBreakDurationsData = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    var selectedTheme: Theme {
        get { Theme(rawValue: selectedThemeRaw) ?? .dark }
        set {
            selectedThemeRaw = newValue.rawValue
            DropletWidgetStore.shared.syncTheme(rawValue: newValue.rawValue)
        }
    }

    var gradientEnabled: Bool {
        gradientEnabledStorage
    }

    // Minimum sizes for in-app views
    let goalTrackerMinSize = CGSize(width: 280, height: 220)
    let taskViewMinSize = CGSize(width: 280, height: 280)
    let settingsMinSize = CGSize(width: 340, height: 460)
    let soundsMinSize = CGSize(width: 340, height: 430)
    let detailedViewMinSize = CGSize(width: 500, height: 340)

    // Mini-floater size constraints (truly compact, fixed size)
    let miniViewMinSize = CGSize(width: 100, height: 36)
    let miniViewMaxSize = CGSize(width: 100, height: 36)  // Same as min = not resizable

    // Saved window frame before entering mini mode
    static var savedFrameBeforeMini: NSRect?

    // Saved window frame before entering detailed view
    static var savedFrameBeforeDetailed: NSRect?

    // Saved window state before entering native fullscreen.
    static var savedStyleMaskBeforeFullscreen: NSWindow.StyleMask?
    static var savedCollectionBehaviorBeforeFullscreen: NSWindow.CollectionBehavior?
    static var savedLevelBeforeFullscreen: NSWindow.Level?

    // Reference to main window (set by AppDelegate)
    static weak var mainWindow: NSWindow?

    func setGradientEnabled(_ isEnabled: Bool) {
        gradientEnabledStorage = isEnabled
        DropletWidgetStore.shared.syncGradient(isEnabled: isEnabled)
    }

    func setDetailedViewPresented(_ isPresented: Bool) {
        guard detailedViewPresented != isPresented else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            detailedViewPresented = isPresented
        }
    }

    func toggleFullscreen() {
        guard let window = SettingsManager.mainWindow else { return }

        if fullscreenMode || window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
            return
        }

        prepareForNativeFullscreen(window)
        withAnimation(.easeInOut(duration: 0.18)) {
            fullscreenMode = true
        }
        window.toggleFullScreen(nil)
    }

    func exitFullscreenIfNeeded() {
        guard fullscreenMode else { return }
        SettingsManager.mainWindow?.toggleFullScreen(nil)
    }

    func nativeFullscreenDidEnter() {
        withAnimation(.easeInOut(duration: 0.18)) {
            fullscreenMode = true
        }
        hideTrafficLights()
    }

    func nativeFullscreenDidExit() {
        restoreAfterNativeFullscreen()
        withAnimation(.easeInOut(duration: 0.18)) {
            fullscreenMode = false
        }
    }

    private func prepareForNativeFullscreen(_ window: NSWindow) {
        SettingsManager.savedStyleMaskBeforeFullscreen = window.styleMask
        SettingsManager.savedCollectionBehaviorBeforeFullscreen = window.collectionBehavior
        SettingsManager.savedLevelBeforeFullscreen = window.level

        window.level = .normal
        window.collectionBehavior = [.fullScreenPrimary]
        window.styleMask.insert([.titled, .resizable])
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        hideTrafficLights()
    }

    private func restoreAfterNativeFullscreen() {
        guard let window = SettingsManager.mainWindow else { return }

        if let savedStyleMask = SettingsManager.savedStyleMaskBeforeFullscreen {
            window.styleMask = savedStyleMask
        }
        if let savedCollectionBehavior = SettingsManager.savedCollectionBehaviorBeforeFullscreen {
            window.collectionBehavior = savedCollectionBehavior
        }
        if let savedLevel = SettingsManager.savedLevelBeforeFullscreen {
            window.level = savedLevel
        }

        SettingsManager.savedStyleMaskBeforeFullscreen = nil
        SettingsManager.savedCollectionBehaviorBeforeFullscreen = nil
        SettingsManager.savedLevelBeforeFullscreen = nil
    }

    private func hideTrafficLights() {
        guard let window = SettingsManager.mainWindow else { return }
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
    }

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
            // Determine minimum size based on target view
            let minSize: CGSize
            switch view {
            case .taskList, .addTask:
                minSize = taskViewMinSize
            case .settings:
                minSize = settingsMinSize
            case .sounds:
                minSize = soundsMinSize
            default:
                minSize = goalTrackerMinSize
            }

            // Ensure window is large enough
            let currentSize = window.frame.size
            if currentSize.width < minSize.width || currentSize.height < minSize.height {
                let newWidth = max(currentSize.width, minSize.width)
                let newHeight = max(currentSize.height, minSize.height)
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

    private init() {
        // Always start in normal mode regardless of last state
        detailedView = false

        if UserDefaults.standard.object(forKey: "gradientEnabled") == nil,
           UserDefaults.standard.object(forKey: "widgetGradientEnabled") != nil {
            gradientEnabledStorage = UserDefaults.standard.bool(forKey: "widgetGradientEnabled")
        }
    }
}
