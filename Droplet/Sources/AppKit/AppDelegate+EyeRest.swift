import AppKit
import SwiftUI

extension AppDelegate {
    func showEyeRestOverlay() {
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
}
