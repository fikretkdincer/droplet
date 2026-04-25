import SwiftUI

/// Theme definition with all color schemes for the app
enum Theme: String, CaseIterable, Identifiable {
    // Neutral/Classic
    case dark = "Dark"
    case noir = "Noir"
    case light = "Light"
    
    // Warm/Earth
    case beige = "Beige"
    case linen = "Linen"      // Was Beige+
    case poppy = "Poppy"
    
    // Pink/Purple
    case blossom = "Blossom"
    case velvet = "Velvet"
    case plum = "Plum"
    
    // Cool/Blue
    case navy = "Navy"
    case royal = "Royal"      // Was Navy+
    case teal = "Teal"
    
    // Green
    case frog = "Frog"
    case leaf = "Leaf"
    case emerald = "Emerald"
    
    var id: String { rawValue }
    
    var backgroundColor: Color {
        switch self {
        case .dark: return Color(hex: "1E1E1E")
        case .noir: return Color(hex: "000000")
        case .light: return Color(hex: "F5F5F5")
        case .beige, .linen: return Color(hex: "F5F1E4")
        case .poppy: return Color(hex: "FFE4E9")
        case .blossom: return Color(hex: "FFF0F5")
        case .velvet: return Color(hex: "2F2A44")
        case .plum: return Color(hex: "5C4B8A")
        case .navy: return Color(hex: "1C2E4A")
        case .royal: return Color(hex: "0F1826")
        case .teal: return Color(hex: "008080")
        case .frog: return Color(hex: "E8F3E8")
        case .leaf: return Color(hex: "051907")
        case .emerald: return Color(hex: "0D2B1D")
        }
    }
    
    var workAccent: Color {
        switch self {
        case .dark: return Color(hex: "81A1C1")
        case .noir: return Color(hex: "7D7D7D")
        case .light: return Color(hex: "5D8AA8")
        case .beige: return Color(hex: "8B5E3C")
        case .linen: return Color(hex: "1C2E4A")
        case .poppy: return Color(hex: "FF6B6B")
        case .blossom: return Color(hex: "DB7093")
        case .velvet: return Color(hex: "A76D99")
        case .plum: return Color(hex: "A77BCA")
        case .navy: return Color(hex: "F5F1E4")
        case .royal: return Color(hex: "D7C49E")
        case .teal: return Color(hex: "48D1CC")
        case .frog: return Color(hex: "2D5A27")
        case .leaf: return Color(hex: "2D5A27")
        case .emerald: return Color(hex: "6B8F71")
        }
    }
    
    var breakAccent: Color {
        switch self {
        case .dark: return Color(hex: "A3BE8C")
        case .noir: return Color(hex: "4B4B4B")
        case .light: return Color(hex: "6B8E23")
        case .beige: return Color(hex: "A68A64")
        case .linen: return Color(hex: "3E5C76")
        case .poppy: return Color(hex: "FF8FA3")
        case .blossom: return Color(hex: "EAB8C5")
        case .velvet: return Color(hex: "6F4C7A")
        case .plum: return Color(hex: "D6A6E0")
        case .navy: return Color(hex: "E8E4D5")
        case .royal: return Color(hex: "E0D5B6")
        case .teal: return Color(hex: "7FFFD4")
        case .frog: return Color(hex: "7FB069")
        case .leaf: return Color(hex: "558B2F")
        case .emerald: return Color(hex: "AEC3B0")
        }
    }
    
    var textColor: Color {
        switch self {
        case .dark: return Color(hex: "E0E0E0")
        case .noir: return Color(hex: "BFBFBF")
        case .light: return Color(hex: "333333")
        case .beige: return Color(hex: "4A3728")
        case .linen: return Color(hex: "1C2E4A")
        case .poppy: return Color(hex: "8B2942")
        case .blossom: return Color(hex: "5F3E49")
        case .velvet: return Color(hex: "E8BFD1")
        case .plum: return Color(hex: "EAD1E5")
        case .navy: return Color(hex: "F5F1E4")
        case .royal: return Color(hex: "E0D5B6")
        case .teal: return Color(hex: "E0FFFF")
        case .frog: return Color(hex: "1B3022")
        case .leaf: return Color(hex: "E8F5E9")
        case .emerald: return Color(hex: "E3EFD3")
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
