import Foundation

public enum GeneratedNoise: String, CaseIterable, Codable, Identifiable, Sendable {
    case white = "White Noise"
    case pink = "Pink Noise"
    case brown = "Brown Noise"
    case green = "Green Noise"
    case blue = "Blue Noise"
    case violet = "Violet Noise"

    public var id: String { rawValue }

    public var outputGain: Float {
        switch self {
        case .white:
            return 0.075
        case .pink:
            return 0.095
        case .brown:
            return 0.135
        case .green:
            return 0.070
        case .blue:
            return 0.030
        case .violet:
            return 0.014
        }
    }
}
