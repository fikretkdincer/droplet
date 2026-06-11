import AppKit

extension AppDelegate {
    func setupKeyboardMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            guard self.window?.isKeyWindow == true else { return event }

            if let firstResponder = self.window?.firstResponder,
               firstResponder is NSTextView || firstResponder is NSTextField {
                return event
            }

            guard self.settings.currentView == .timer else { return event }

            switch event.charactersIgnoringModifiers?.lowercased() {
            case " ":
                if self.viewModel.status == .pulsing {
                    self.viewModel.continueToNextPhase()
                } else {
                    self.viewModel.toggleStartPause()
                }
                return nil
            case "r":
                self.viewModel.resetCurrentMode()
                return nil
            default:
                return event
            }
        }
    }
}
