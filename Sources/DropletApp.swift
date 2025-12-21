import SwiftUI
import AppKit

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
    
    // MARK: - Main Window
    
    private func setupMainWindow() {
        let contentView = TimerView(viewModel: viewModel)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 120),
            styleMask: [.borderless, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window?.minSize = NSSize(width: 140, height: 100)
        window?.maxSize = NSSize(width: 400, height: 300)
        
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
        
        // Monitor for always on top changes
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateWindowLevel()
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
