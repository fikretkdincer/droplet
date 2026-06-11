import AppKit

private let menuBarWindowGap: CGFloat = 2
private let temporaryRaiseDuration: TimeInterval = 0.12

extension AppDelegate {
    func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        if let image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "droplet") {
            button.image = image.withSymbolConfiguration(config)
        } else {
            button.title = "Droplet"
        }

        button.action = #selector(toggleWindow)
        button.target = self
    }

    func updateMenuBarTimer() {
        guard let button = statusItem?.button else { return }

        if settings.showMenuBarTimer {
            let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .baselineOffset: 0
            ]
            button.attributedTitle = NSAttributedString(string: " \(viewModel.formattedTime)", attributes: attributes)
            button.imagePosition = .imageLeft
        } else {
            button.attributedTitle = NSAttributedString(string: "")
            button.title = ""
        }
    }

    @objc func toggleWindow() {
        guard let window else { return }

        if shouldHideWindowOnMenuBarClick(window) {
            window.orderOut(nil)
            return
        }

        positionWindowUnderMenuBar()
        raiseWindowFromMenuBar(window)
    }

    private func shouldHideWindowOnMenuBarClick(_ window: NSWindow) -> Bool {
        window.isVisible && NSApp.isActive && (window.isKeyWindow || window.isMainWindow)
    }

    private func raiseWindowFromMenuBar(_ window: NSWindow) {
        if settings.alwaysOnTop {
            window.level = .floating
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        window.level = .floating
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + temporaryRaiseDuration) { [weak self, weak window] in
            guard let self, let window, !self.settings.alwaysOnTop else { return }
            window.level = .normal
            window.makeKeyAndOrderFront(nil)
        }
    }

    func positionWindowUnderMenuBar() {
        guard let window,
              let frame = frameUnderMenuBar(for: window.frame.size, gap: menuBarWindowGap) else { return }

        window.setFrame(frame, display: true)
    }

    func frameUnderMenuBar(for size: NSSize, gap: CGFloat = menuBarWindowGap) -> NSRect? {
        guard let button = statusItem?.button,
              let buttonWindow = button.window else {
            return fallbackFrameUnderMenuBar(for: size, gap: gap)
        }

        let buttonFrame = buttonWindow.convertToScreen(button.frame)
        let screen = buttonWindow.screen
            ?? screen(containing: NSPoint(x: buttonFrame.midX, y: buttonFrame.midY))
            ?? NSScreen.main

        return frameUnderMenuBar(for: size, anchoredTo: buttonFrame, on: screen, gap: gap)
    }

    private func fallbackFrameUnderMenuBar(for size: NSSize, gap: CGFloat) -> NSRect? {
        guard let screen = screen(containing: NSEvent.mouseLocation) ?? NSScreen.main else { return nil }
        let anchor = NSRect(
            x: screen.visibleFrame.midX,
            y: screen.visibleFrame.maxY,
            width: 0,
            height: 0
        )
        return frameUnderMenuBar(for: size, anchoredTo: anchor, on: screen, gap: gap)
    }

    private func frameUnderMenuBar(
        for size: NSSize,
        anchoredTo anchor: NSRect,
        on screen: NSScreen?,
        gap: CGFloat
    ) -> NSRect? {
        guard let screen else { return nil }

        let visibleFrame = screen.visibleFrame
        let width = min(size.width, visibleFrame.width)
        let height = min(size.height, visibleFrame.height)
        let minX = visibleFrame.minX
        let maxX = visibleFrame.maxX - width
        let minY = visibleFrame.minY
        let maxY = visibleFrame.maxY - height

        let proposedX = anchor.midX - width / 2
        let proposedY = anchor.minY - height - gap
        let x = min(max(proposedX, minX), maxX)
        let y = min(max(proposedY, minY), maxY)

        return NSRect(x: x, y: y, width: width, height: height)
    }

    private func screen(containing point: NSPoint) -> NSScreen? {
        NSScreen.screens.first { screen in
            screen.frame.contains(point)
        }
    }
}
