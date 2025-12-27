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
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                    NSApplication.shared.windows.first?.close()
                }
        }
    }
}

/// App delegate handling menu bar icon and window management
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var eventMonitor: Any?
    var window: NSWindow?
    var cancellables = Set<AnyCancellable>()
    private var lastMiniMode: Bool = false
    
    let viewModel = PomodoroViewModel()
    let settings = SettingsManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize notification manager early to set delegate
        _ = NotificationManager.shared
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        setupMenuBarIcon()
        setupMainWindow()
        setupKeyboardMonitor()
        setupObservers()
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
            }
            .store(in: &cancellables)
            
        // Observe settings changes for window resizing and toggles
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSettingsChange()
        }
    }
    
    private func updateMenuBarTimer() {
        guard let button = statusItem?.button else { return }
        
        if settings.showMenuBarTimer {
            // Use fixed width font if possible or mono digit string to prevent jitter
            button.title = " \(viewModel.formattedTime)"
            button.imagePosition = .imageLeft
        } else {
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
    }
    
    // MARK: - Main Window
    
    private func setupMainWindow() {
        let contentView = TimerView(viewModel: viewModel)
        
        // Use custom BorderlessKeyWindow to enable TextField focus
        window = BorderlessKeyWindow(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 120),
            styleMask: [.borderless, .fullSizeContentView, .resizable],
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
        
        // Position window near menu bar icon
        if let button = statusItem?.button {
            let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
            let windowFrame = window?.frame ?? .zero
            let x = buttonFrame.midX - windowFrame.width / 2
            let y = buttonFrame.minY - windowFrame.height - 10
            window?.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        window?.makeKeyAndOrderFront(nil)
        
        // Set static reference for view navigation
        SettingsManager.mainWindow = window
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
            
            window.minSize = NSSize(width: 140, height: 100)
            window.maxSize = NSSize(width: 400, height: 300)
            
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
        }
    }
    
    private func updateWindowLevel() {
        window?.level = settings.alwaysOnTop ? .floating : .normal
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
            // Reposition near menu bar icon
            if let button = statusItem?.button {
                let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
                let windowFrame = window?.frame ?? .zero
                let x = buttonFrame.midX - windowFrame.width / 2
                let y = buttonFrame.minY - windowFrame.height - 10
                window?.setFrameOrigin(NSPoint(x: x, y: y))
            }
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}
