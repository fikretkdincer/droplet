import Foundation

/// Timer mode representing the current phase
enum TimerMode: String, CaseIterable {
    case work = "Work"
    case shortBreak = "Break"
    case longBreak = "Long Break"
    case infinity = "Infinity"

    var icon: String {
        switch self {
        case .work: return "💧"
        case .shortBreak: return "🌿"
        case .longBreak: return "🌊"
        case .infinity: return "∞"
        }
    }
}

/// Timer running status
enum TimerStatus {
    case idle
    case running
    case paused
    case pulsing // Waiting for user to start next phase
}
