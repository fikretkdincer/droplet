import AppKit
import Foundation

extension AppDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where DropletWidgetDeepLink.isTimerToggle(url) {
            handleTimerWidgetToggle()
        }
    }

    func handleTimerWidgetToggle() {
        viewModel.toggleFromWidget()
        viewModel.syncWidgetTimerState(reload: true)
    }
}
