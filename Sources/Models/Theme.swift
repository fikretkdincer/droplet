import SwiftUI

/// Theme definition with all color schemes for the app
enum Theme: String, CaseIterable, Identifiable {
    case dark = "Dark"
    case light = "Light"
    case beige = "Beige"
    case beigePlus = "Beige+"
    case navy = "Navy"
    case frog = "Frog"
    case blossom = "Blossom"
    case poppy = "Poppy"
    
    var id: String { rawValue }
    
    var backgroundColor: Color {
        switch self {
        case .dark: return Color(hex: "1E1E1E")
        case .light: return Color(hex: "F5F5F5")
        case .beige, .beigePlus: return Color(hex: "F5F1E4")
        case .navy: return Color(hex: "1C2E4A")
        case .frog: return Color(hex: "E8F3E8")
        case .blossom: return Color(hex: "FFF0F5")
        case .poppy: return Color(hex: "FFE4E9")
        }
    }
    
    var workAccent: Color {
        switch self {
        case .dark: return Color(hex: "81A1C1")
        case .light: return Color(hex: "5D8AA8")
        case .beige: return Color(hex: "8B5E3C")
        case .beigePlus: return Color(hex: "1C2E4A")
        case .navy: return Color(hex: "F5F1E4")
        case .frog: return Color(hex: "2D5A27")
        case .blossom: return Color(hex: "DB7093")
        case .poppy: return Color(hex: "FF6B6B")
        }
    }
    
    var breakAccent: Color {
        switch self {
        case .dark: return Color(hex: "A3BE8C")
        case .light: return Color(hex: "6B8E23")
        case .beige: return Color(hex: "A68A64")
        case .beigePlus: return Color(hex: "3E5C76")
        case .navy: return Color(hex: "E8E4D5")
        case .frog: return Color(hex: "7FB069")
        case .blossom: return Color(hex: "EAB8C5")
        case .poppy: return Color(hex: "FF8FA3")
        }
    }
    
    var textColor: Color {
        switch self {
        case .dark: return Color(hex: "E0E0E0")
        case .light: return Color(hex: "333333")
        case .beige: return Color(hex: "4A3728")
        case .beigePlus: return Color(hex: "1C2E4A")
        case .navy: return Color(hex: "F5F1E4")
        case .frog: return Color(hex: "1B3022")
        case .blossom: return Color(hex: "5F3E49")
        case .poppy: return Color(hex: "8B2942")
        }
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
