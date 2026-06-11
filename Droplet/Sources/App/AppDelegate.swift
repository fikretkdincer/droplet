import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var eventMonitor: Any?
    var window: NSWindow?
    var onboardingWindow: NSWindow?
    var eyeRestWindows: [NSWindow] = []
    var cancellables = Set<AnyCancellable>()
    var lastMiniMode = false
    var lastDetailedView = false

    let viewModel = PomodoroViewModel()
    let settings = SettingsManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false

        _ = NotificationManager.shared
        _ = GoalTracker.shared
        DropletWidgetStore.shared.syncTheme(rawValue: settings.selectedThemeRaw)

        NSApp.setActivationPolicy(.accessory)

        setupMenuBarIcon()
        setupMainWindow()
        setupKeyboardMonitor()
        setupObservers()
        DropletWidgetStore.shared.syncGradient(isEnabled: settings.gradientEnabled)
        consumeWidgetTimerRequests()
        setupOnboarding()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Window raising is handled explicitly in toggleWindow.
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}
