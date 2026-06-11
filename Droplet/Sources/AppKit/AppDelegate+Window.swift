import AppKit
import SwiftUI

extension AppDelegate {
    private var detailedContentDelay: TimeInterval { 0.11 }
    private var detailedConstraintDelay: TimeInterval { 0.24 }

    func setupMainWindow() {
        window = BorderlessKeyWindow(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 120),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        lastMiniMode = settings.miniFloaterMode
        updateWindowSize(isMini: settings.miniFloaterMode)

        window?.contentView = NSHostingView(rootView: TimerView(viewModel: viewModel))
        window?.backgroundColor = .clear
        window?.isOpaque = false
        window?.hasShadow = true
        window?.title = "Droplet"
        window?.level = settings.alwaysOnTop ? .floating : .normal
        window?.isMovableByWindowBackground = true
        window?.collectionBehavior = [.moveToActiveSpace, .transient, .fullScreenAuxiliary]

        window?.center()

        window?.makeKeyAndOrderFront(nil)

        SettingsManager.mainWindow = window
    }

    func hideTrafficLights(in window: NSWindow) {
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
    }

    func updateWindowSize(isMini: Bool) {
        guard let window else { return }

        if isMini {
            SettingsManager.savedFrameBeforeMini = window.frame
            window.styleMask.remove(.resizable)
            window.minSize = settings.miniViewMinSize
            window.maxSize = settings.miniViewMaxSize

            let currentFrame = window.frame
            let newHeight = settings.miniViewMinSize.height
            let newWidth = settings.miniViewMinSize.width
            let newY = currentFrame.maxY - newHeight
            window.setFrame(
                NSRect(x: currentFrame.origin.x, y: newY, width: newWidth, height: newHeight),
                display: true,
                animate: true
            )
            return
        }

        window.styleMask.insert(.resizable)

        if settings.detailedView {
            window.minSize = settings.detailedViewMinSize
            window.maxSize = NSSize(width: 1200, height: 800)
        } else {
            window.minSize = NSSize(width: 140, height: 100)
            window.maxSize = NSSize(width: 400, height: 300)
        }

        if let savedFrame = SettingsManager.savedFrameBeforeMini {
            window.setFrame(savedFrame, display: true, animate: true)
            SettingsManager.savedFrameBeforeMini = nil
        } else {
            expandWindowFromMenuBarAnchor()
        }
    }

    func updateWindowForDetailedView(_ isDetailed: Bool) {
        guard let window else { return }

        if isDetailed {
            SettingsManager.savedFrameBeforeDetailed = window.frame
            let minSize = settings.detailedViewMinSize
            window.maxSize = NSSize(width: 1200, height: 800)

            let newWidth = max(window.frame.size.width, minSize.width)
            let newHeight = max(window.frame.size.height, minSize.height)
            let newFrame = NSRect(
                x: window.frame.origin.x,
                y: window.frame.origin.y - (newHeight - window.frame.size.height),
                width: newWidth,
                height: newHeight
            )
            window.setFrame(newFrame, display: true, animate: true)
            presentDetailedView(after: detailedContentDelay, for: window)
            applyDetailedConstraints(after: detailedConstraintDelay, for: window)
            return
        }

        settings.setDetailedViewPresented(false)
        if let saved = SettingsManager.savedFrameBeforeDetailed {
            window.setFrame(saved, display: true, animate: true)
            SettingsManager.savedFrameBeforeDetailed = nil
        }
        applyCompactConstraints(after: detailedConstraintDelay, for: window)
    }

    func updateWindowLevel() {
        window?.level = settings.alwaysOnTop ? .floating : .normal
    }

    private func expandWindowFromMenuBarAnchor() {
        guard let window else { return }

        let newWidth: CGFloat = 260
        let newHeight: CGFloat = 180

        if let frame = frameUnderMenuBar(for: NSSize(width: newWidth, height: newHeight), gap: 10) {
            window.setFrame(frame, display: true, animate: true)
        } else {
            let currentFrame = window.frame
            let newY = currentFrame.maxY - newHeight
            window.setFrame(
                NSRect(x: currentFrame.origin.x, y: newY, width: newWidth, height: newHeight),
                display: true,
                animate: true
            )
        }
    }

    private func presentDetailedView(after delay: TimeInterval, for targetWindow: NSWindow) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak targetWindow] in
            guard let self,
                  let targetWindow,
                  self.window === targetWindow,
                  self.settings.detailedView,
                  !self.settings.miniFloaterMode else { return }

            self.settings.setDetailedViewPresented(true)
        }
    }

    private func applyDetailedConstraints(after delay: TimeInterval, for targetWindow: NSWindow) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak targetWindow] in
            guard let self,
                  let targetWindow,
                  self.window === targetWindow,
                  self.settings.detailedView,
                  !self.settings.miniFloaterMode else { return }

            targetWindow.minSize = self.settings.detailedViewMinSize
            targetWindow.maxSize = NSSize(width: 1200, height: 800)
        }
    }

    private func applyCompactConstraints(after delay: TimeInterval, for targetWindow: NSWindow) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak targetWindow] in
            guard let self,
                  let targetWindow,
                  self.window === targetWindow,
                  !self.settings.detailedView,
                  !self.settings.miniFloaterMode else { return }

            targetWindow.minSize = NSSize(width: 140, height: 100)
            targetWindow.maxSize = NSSize(width: 400, height: 300)
        }
    }
}
