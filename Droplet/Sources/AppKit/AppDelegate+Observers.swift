import Combine
import Foundation
import AppKit

extension AppDelegate {
    func setupObservers() {
        viewModel.$remainingSeconds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarTimer()
                self?.viewModel.syncWidgetTimerState(reload: false)
            }
            .store(in: &cancellables)

        viewModel.$elapsedSeconds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarTimer()
                self?.viewModel.syncWidgetTimerState(reload: false)
            }
            .store(in: &cancellables)

        viewModel.$currentMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.viewModel.syncWidgetTimerState(reload: true)
            }
            .store(in: &cancellables)

        viewModel.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.viewModel.syncWidgetTimerState(reload: true)
            }
            .store(in: &cancellables)

        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.consumeWidgetTimerRequests()
            }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: UserDefaults.standard,
            queue: .main
        ) { [weak self] _ in
            self?.handleSettingsChange()
        }

        NotificationCenter.default.addObserver(
            forName: Notification.Name("ShowOnboardingNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showOnboarding()
        }

        NotificationCenter.default.addObserver(
            forName: Notification.Name("TriggerEyeRestOverlay"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showEyeRestOverlay()
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didEnterFullScreenNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.settings.nativeFullscreenDidEnter()
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didExitFullScreenNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.settings.nativeFullscreenDidExit()
            self?.handleSettingsChange()
        }
    }

    func handleSettingsChange() {
        updateWindowLevel()
        updateMenuBarTimer()

        if settings.miniFloaterMode != lastMiniMode {
            if settings.fullscreenMode {
                settings.exitFullscreenIfNeeded()
                return
            }
            lastMiniMode = settings.miniFloaterMode
            updateWindowSize(isMini: settings.miniFloaterMode)
        }

        if settings.detailedView != lastDetailedView {
            if settings.fullscreenMode {
                settings.exitFullscreenIfNeeded()
                return
            }
            lastDetailedView = settings.detailedView
            updateWindowForDetailedView(settings.detailedView)
        }
    }

    func consumeWidgetTimerRequests() {
        let store = DropletWidgetStore.shared
        let requestId = store.timerActionRequestId
        guard requestId > 0, requestId > store.consumedTimerActionRequestId else { return }

        store.markTimerStartRequestConsumed(requestId)
        guard Date().timeIntervalSince1970 - requestId < 10 else { return }
        viewModel.toggleFromWidget()
        viewModel.syncWidgetTimerState(reload: true)
        showWindowFromExternalActivation()
    }

    var hasPendingRecentWidgetTimerRequest: Bool {
        let store = DropletWidgetStore.shared
        let requestId = store.timerActionRequestId
        guard requestId > 0, requestId > store.consumedTimerActionRequestId else { return false }
        return Date().timeIntervalSince1970 - requestId < 10
    }
}
