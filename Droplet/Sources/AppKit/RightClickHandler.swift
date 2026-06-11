import AppKit
import SwiftUI

struct RightClickHandler: NSViewRepresentable {
    let viewModel: PomodoroViewModel
    let settings: SettingsManager

    func makeNSView(context: Context) -> RightClickNSView {
        let view = RightClickNSView()
        view.viewModel = viewModel
        view.settings = settings
        return view
    }

    func updateNSView(_ nsView: RightClickNSView, context: Context) {
        nsView.viewModel = viewModel
        nsView.settings = settings
    }
}

final class RightClickNSView: NSView {
    var viewModel: PomodoroViewModel?
    var settings: SettingsManager?
    private var settingsMenu: SettingsMenu?

    override func rightMouseDown(with event: NSEvent) {
        guard let viewModel, let settings else { return }

        settingsMenu = SettingsMenu(viewModel: viewModel, settings: settings)
        guard let menu = settingsMenu?.createMenu() else { return }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if NSApp.currentEvent?.type == .rightMouseDown {
            return super.hitTest(point)
        }
        return nil
    }
}
