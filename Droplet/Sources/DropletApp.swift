import SwiftUI
import AppKit
import Combine

/// Custom borderless window that can become key and accept first responder
/// This is required for TextFields to work properly in borderless windows
class BorderlessKeyWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    override func resignKey() {
        super.resignKey()
        // Don't resign first responder when window loses key status
    }
}

/// Main application entry point
@main
struct DropletApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

/// App delegate handling menu bar icon and window management
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var eventMonitor: Any?
    var window: NSWindow?
    var onboardingWindow: NSWindow?
    var eyeRestWindows: [NSWindow] = []
    var cancellables = Set<AnyCancellable>()
    private var lastMiniMode: Bool = false
    private var lastDetailedView: Bool = false
    
    let viewModel = PomodoroViewModel()
    let settings = SettingsManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false

        // Initialize notification manager early to set delegate
        _ = NotificationManager.shared
        _ = GoalTracker.shared
        DropletWidgetStore.shared.syncTheme(rawValue: settings.selectedThemeRaw)
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        setupMenuBarIcon()
        setupMainWindow()
        setupKeyboardMonitor()
        setupObservers()
        consumeWidgetTimerRequests()
        setupOnboarding()
    }
    
    // MARK: - Menu Bar Icon
    
    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Water drop icon using SF Symbol
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            if let image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "droplet") {
                let configuredImage = image.withSymbolConfiguration(config)
                button.image = configuredImage
            } else {
                button.title = "💧"
            }
            
            button.action = #selector(toggleWindow)
            button.target = self
        }
    }
    
    private func setupObservers() {
        // Update menu bar timer every second
        viewModel.$remainingSeconds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarTimer()
                self?.viewModel.syncWidgetTimerState(reload: false)
            }
            .store(in: &cancellables)

        viewModel.$elapsedSeconds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarTimer()
                self?.viewModel.syncWidgetTimerState(reload: false)
            }
            .store(in: &cancellables)

        viewModel.$currentMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.viewModel.syncWidgetTimerState(reload: true)
            }
            .store(in: &cancellables)

        viewModel.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.viewModel.syncWidgetTimerState(reload: true)
            }
            .store(in: &cancellables)

        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.consumeWidgetTimerRequests()
            }
            .store(in: &cancellables)

        // Observe settings changes for window resizing and toggles
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: UserDefaults.standard,
            queue: .main
        ) { [weak self] _ in
            self?.handleSettingsChange()
        }

        NotificationCenter.default.addObserver(
            forName: Notification.Name("ShowOnboardingNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showOnboarding()
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("TriggerEyeRestOverlay"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showEyeRestOverlay()
        }
    }
    
    private func updateMenuBarTimer() {
        guard let button = statusItem?.button else { return }
        
        if settings.showMenuBarTimer {
            // Use monospaced digits to prevent jitter during countdown
            let timerText = viewModel.formattedTime
            
            // Create attributed string with monospaced digits font
            let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .baselineOffset: 0
            ]
            let attributedString = NSAttributedString(string: " \(timerText)", attributes: attributes)
            
            button.attributedTitle = attributedString
            button.imagePosition = .imageLeft
        } else {
            button.attributedTitle = NSAttributedString(string: "")
            button.title = ""
        }
    }
    
    private func handleSettingsChange() {
        updateWindowLevel()
        updateMenuBarTimer()
        
        // Check if mini mode changed
        if settings.miniFloaterMode != lastMiniMode {
            lastMiniMode = settings.miniFloaterMode
            updateWindowSize(isMini: settings.miniFloaterMode)
        }
        
        // Check if detailed view changed
        if settings.detailedView != lastDetailedView {
            lastDetailedView = settings.detailedView
            updateWindowForDetailedView(settings.detailedView)
        }
    }

    private func consumeWidgetTimerRequests() {
        let store = DropletWidgetStore.shared
        let requestId = store.timerActionRequestId
        guard requestId > 0, requestId > store.consumedTimerActionRequestId else { return }

        store.markTimerStartRequestConsumed(requestId)
        guard Date().timeIntervalSince1970 - requestId < 10 else { return }
        viewModel.toggleFromWidget()
        viewModel.syncWidgetTimerState(reload: true)
    }
    
    // MARK: - Main Window
    
    private func setupMainWindow() {
        let contentView = TimerView(viewModel: viewModel)
        
        // Use custom BorderlessKeyWindow to enable TextField focus
        // Need .titled for fullscreen support, but we hide the title bar
        window = BorderlessKeyWindow(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 120),
            styleMask: [.titled, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // Initial state
        lastMiniMode = settings.miniFloaterMode
        updateWindowSize(isMini: settings.miniFloaterMode)
        
        window?.contentView = NSHostingView(rootView: contentView)
        window?.backgroundColor = .clear
        window?.isOpaque = false
        window?.hasShadow = true
        window?.level = settings.alwaysOnTop ? .floating : .normal
        window?.isMovableByWindowBackground = true
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.collectionBehavior = [.fullScreenPrimary, .managed, .participatesInCycle]
        
        // Hide traffic light buttons but keep fullscreen capability
        hideTrafficLights(in: window!)
        
        // Position window in center of screen on first launch
        window?.center()
        
        if !hasPendingRecentWidgetTimerRequest {
            window?.makeKeyAndOrderFront(nil)
        }
        
        // Set static reference for view navigation
        SettingsManager.mainWindow = window
    }

    private var hasPendingRecentWidgetTimerRequest: Bool {
        let store = DropletWidgetStore.shared
        let requestId = store.timerActionRequestId
        guard requestId > 0, requestId > store.consumedTimerActionRequestId else { return false }
        return Date().timeIntervalSince1970 - requestId < 10
    }
    
    /// Hides all three traffic-light buttons. Must be called after any styleMask mutation
    /// because macOS automatically re-shows them whenever the style mask changes.
    private func hideTrafficLights(in window: NSWindow) {
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
    }

    // MARK: - Onboarding

    /// Called on first launch only — skips if already completed.
    private func setupOnboarding() {
        guard !UserDefaults.standard.bool(forKey: "hasShownOnboarding") else { return }
        showOnboarding()
    }

    /// Create and present the onboarding window unconditionally.
    /// Called on first launch via setupOnboarding() and directly from Settings → Revisit.
    func showOnboarding() {
        // Close any existing onboarding window first
        onboardingWindow?.orderOut(nil)
        onboardingWindow = nil

        let onboardingView = OnboardingView {
            // Show the timer window FIRST, then dismiss onboarding.
            // Dismissing before the timer is visible creates a zero-windows
            // gap that can trigger an implicit app quit.
            NSApp.activate(ignoringOtherApps: true)
            self.window?.makeKeyAndOrderFront(nil)
            self.onboardingWindow?.orderOut(nil)
            self.onboardingWindow = nil
        }

        let onbWindow = BorderlessKeyWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 390),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        onbWindow.contentView = NSHostingView(rootView: onboardingView)
        onbWindow.titlebarAppearsTransparent = true
        onbWindow.titleVisibility = .hidden
        onbWindow.backgroundColor = .clear
        onbWindow.isOpaque = false
        onbWindow.hasShadow = true
        onbWindow.level = .floating
        onbWindow.isMovableByWindowBackground = true
        onbWindow.center()
        onbWindow.makeKeyAndOrderFront(nil)
        hideTrafficLights(in: onbWindow)
        onboardingWindow = onbWindow
    }
    
    // MARK: - Eye Rest Overlay
    
    private func showEyeRestOverlay() {
        guard eyeRestWindows.isEmpty else { return }
        
        for screen in NSScreen.screens {
            let overlayWindow = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            let overlayView = EyeRestOverlayView { [weak self] in
                self?.eyeRestWindows.forEach { $0.orderOut(nil) }
                self?.eyeRestWindows.removeAll()
            }
            
            overlayWindow.contentView = NSHostingView(rootView: overlayView)
            overlayWindow.backgroundColor = .clear
            overlayWindow.isOpaque = false
            overlayWindow.hasShadow = false
            overlayWindow.level = .screenSaver
            overlayWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            
            overlayWindow.setFrame(screen.frame, display: true)
            overlayWindow.makeKeyAndOrderFront(nil)
            
            eyeRestWindows.append(overlayWindow)
        }
    }

    /// Position window directly below the menu bar icon
    private func positionWindowUnderMenuBar() {
        guard let window = window,
              let button = statusItem?.button,
              let buttonWindow = button.window else { return }
        
        let buttonFrame = buttonWindow.convertToScreen(button.frame)
        let windowFrame = window.frame
        
        // Position: centered under button, just below menu bar (2px gap)
        let x = buttonFrame.midX - windowFrame.width / 2
        let y = buttonFrame.minY - windowFrame.height - 2
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    private func updateWindowSize(isMini: Bool) {
        guard let window = window else { return }
        
        if isMini {
            // Save current frame before shrinking
            SettingsManager.savedFrameBeforeMini = window.frame
            
            // Remove resizable style for fixed mini size
            window.styleMask.remove(.resizable)
            
            window.minSize = settings.miniViewMinSize
            window.maxSize = settings.miniViewMaxSize
            
            // Shrink to mini size
            let currentFrame = window.frame
            let newHeight = settings.miniViewMinSize.height
            let newWidth = settings.miniViewMinSize.width
            let newY = currentFrame.maxY - newHeight
            
            window.setFrame(NSRect(x: currentFrame.origin.x, y: newY, width: newWidth, height: newHeight), display: true, animate: true)
        } else {
            // Restore resizable style
            window.styleMask.insert(.resizable)
            // styleMask change causes macOS to un-hide traffic lights — re-hide them immediately
            hideTrafficLights(in: window)

            // Use appropriate sizes based on detailed view state
            if settings.detailedView {
                window.minSize = settings.detailedViewMinSize
                window.maxSize = NSSize(width: 1200, height: 800)
            } else {
                window.minSize = NSSize(width: 140, height: 100)
                window.maxSize = NSSize(width: 400, height: 300)
            }
            
            // Restore saved frame if available, otherwise position under menu bar
            if let savedFrame = SettingsManager.savedFrameBeforeMini {
                window.setFrame(savedFrame, display: true, animate: true)
                SettingsManager.savedFrameBeforeMini = nil
            } else {
                // Position under menu bar icon with default size
                let newWidth: CGFloat = 260
                let newHeight: CGFloat = 220
                
                if let button = statusItem?.button,
                   let buttonWindow = button.window {
                    let buttonFrame = buttonWindow.convertToScreen(button.frame)
                    let x = buttonFrame.midX - newWidth / 2
                    let y = buttonFrame.minY - newHeight - 10
                    window.setFrame(NSRect(x: x, y: y, width: newWidth, height: newHeight), display: true, animate: true)
                } else {
                    // Fallback: expand in place
                    let currentFrame = window.frame
                    let newY = currentFrame.maxY - newHeight
                    window.setFrame(NSRect(x: currentFrame.origin.x, y: newY, width: newWidth, height: newHeight), display: true, animate: true)
                }
            }

            // Re-hide after frame animation completes — macOS can re-show them post-animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak window] in
                guard let window = window else { return }
                self.hideTrafficLights(in: window)
            }
        }
    }
    
    private func updateWindowForDetailedView(_ isDetailed: Bool) {
        guard let window = window else { return }
        
        if isDetailed {
            // Save current frame before entering detailed view
            SettingsManager.savedFrameBeforeDetailed = window.frame
            let minSize = settings.detailedViewMinSize
            window.minSize = minSize
            window.maxSize = NSSize(width: 1200, height: 800)
            // Resize to at least minSize
            let newWidth = max(window.frame.size.width, minSize.width)
            let newHeight = max(window.frame.size.height, minSize.height)
            let newFrame = NSRect(
                x: window.frame.origin.x,
                y: window.frame.origin.y - (newHeight - window.frame.size.height),
                width: newWidth,
                height: newHeight
            )
            window.setFrame(newFrame, display: true, animate: true)
        } else {
            // Restore normal constraints and previous frame
            window.minSize = NSSize(width: 140, height: 100)
            window.maxSize = NSSize(width: 400, height: 300)
            if let saved = SettingsManager.savedFrameBeforeDetailed {
                window.setFrame(saved, display: true, animate: true)
                SettingsManager.savedFrameBeforeDetailed = nil
            }
        }
    }
    
    private func updateWindowLevel() {
        window?.level = settings.alwaysOnTop ? .floating : .normal
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // No-op: window raising is handled explicitly in toggleWindow.
        // Doing it here caused the window to re-appear when switching
        // back to the app after hiding it intentionally.
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // This is a menu bar app — never quit just because windows close.
        return false
    }
    
    // MARK: - Keyboard Shortcuts
    
    private func setupKeyboardMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            // Only respond if our window is key
            guard self.window?.isKeyWindow == true else { return event }
            
            // Don't intercept if a text field is active (first responder is a text input)
            if let firstResponder = self.window?.firstResponder,
               firstResponder is NSTextView || firstResponder is NSTextField {
                return event
            }
            
            // Only intercept on timer view
            guard self.settings.currentView == .timer else { return event }
            
            switch event.charactersIgnoringModifiers?.lowercased() {
            case " ":
                // Space: Start/Pause
                if self.viewModel.status == .pulsing {
                    self.viewModel.continueToNextPhase()
                } else {
                    self.viewModel.toggleStartPause()
                }
                return nil
            case "r":
                // R: Reset
                self.viewModel.resetCurrentMode()
                return nil
            default:
                return event
            }
        }
    }
    
    // MARK: - Actions
    
    @objc func toggleWindow() {
        if window?.isVisible == true {
            window?.orderOut(nil)
        } else {
            positionWindowUnderMenuBar()

            // Activate the app first so our window can own the front.
            NSApp.activate(ignoringOtherApps: true)

            if !settings.alwaysOnTop {
                // Normal-level windows can lose the z-order race against the
                // previously active app. Briefly float to guarantee we surface,
                // then restore the correct level once we're on screen.
                window?.level = .floating
                window?.makeKeyAndOrderFront(nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.window?.level = .normal
                }
            } else {
                window?.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}
