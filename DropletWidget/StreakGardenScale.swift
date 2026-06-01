import Foundation

enum StreakGardenLevel: Equatable {
    case empty
    case low
    case medium
    case high
    case complete
    case gold
}

enum StreakGardenScale {
    static func level(minutes: Int, goalMinutes: Int) -> StreakGardenLevel {
        guard minutes > 0 else { return .empty }

        if goalMinutes <= 0 {
            switch minutes {
            case 1..<25: return .low
            case 25..<50: return .medium
            case 50..<75: return .high
            default: return .complete
            }
        }

        let ratio = Double(minutes) / Double(goalMinutes)
        switch ratio {
        case 1.25...: return .gold
        case 1.0..<1.25: return .complete
        case 0.75..<1.0: return .high
        case 0.5..<0.75: return .medium
        default: return .low
        }
    }
}
