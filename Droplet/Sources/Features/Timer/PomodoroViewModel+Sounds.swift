extension PomodoroViewModel {
    func resumeSoundsForFocusIfNeeded() {
        guard settings.pauseSoundsOnTimerPause, currentMode.tracksFocusTime else { return }
        guard SoundManager.shared.currentSound != .none || SoundManager.shared.currentCustomSound != nil else { return }
        if !SoundManager.shared.isPlaying {
            SoundManager.shared.toggle()
        }
    }

    func pauseSoundsForTimerPauseIfNeeded() {
        if settings.pauseSoundsOnTimerPause && SoundManager.shared.isPlaying {
            SoundManager.shared.stop()
        }
    }

    func stopSoundsOnResetIfNeeded() {
        if settings.pauseSoundsOnTimerPause {
            SoundManager.shared.stop()
        }
    }

    func handleSoundsForPhaseTransition(from previousMode: TimerMode) {
        switch previousMode {
        case .work:
            if SoundManager.shared.isPlaying {
                SoundManager.shared.stop()
            }
        case .shortBreak, .longBreak:
            if SoundManager.shared.currentSound != .none || SoundManager.shared.currentCustomSound != nil {
                SoundManager.shared.toggle()
            }
        case .infinity:
            break
        }
    }
}
