import AppKit
import Foundation

extension AppDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        var shouldShowWindow = false

        for url in urls {
            if DropletWidgetDeepLink.isTimerToggle(url) {
                handleTimerWidgetToggle()
                shouldShowWindow = true
            } else if DropletWidgetDeepLink.isOpen(url) {
                shouldShowWindow = true
            }
        }

        if shouldShowWindow {
            showWindowFromExternalActivation()
        }
    }

    func handleTimerWidgetToggle() {
        viewModel.toggleFromWidget()
        viewModel.syncWidgetTimerState(reload: true)
    }
}
