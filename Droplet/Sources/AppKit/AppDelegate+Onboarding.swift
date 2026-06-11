import AppKit
import SwiftUI

extension AppDelegate {
    func setupOnboarding() {
        guard !UserDefaults.standard.bool(forKey: "hasShownOnboarding") else { return }
        showOnboarding()
    }

    func showOnboarding() {
        onboardingWindow?.orderOut(nil)
        onboardingWindow = nil

        let onboardingView = OnboardingView { [weak self] in
            guard let self else { return }
            NSApp.activate(ignoringOtherApps: true)
            self.window?.makeKeyAndOrderFront(nil)
            self.onboardingWindow?.orderOut(nil)
            self.onboardingWindow = nil
        }

        let window = BorderlessKeyWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 430),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: onboardingView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.isMovableByWindowBackground = true
        window.center()
        window.makeKeyAndOrderFront(nil)
        hideTrafficLights(in: window)
        onboardingWindow = window
    }
}
