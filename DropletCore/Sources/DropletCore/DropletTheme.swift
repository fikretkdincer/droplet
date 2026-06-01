public enum DropletTheme: String, CaseIterable, Codable, Identifiable, Sendable {
    case dark = "Dark"
    case noir = "Noir"
    case light = "Light"
    case beige = "Beige"
    case linen = "Linen"
    case poppy = "Poppy"
    case blossom = "Blossom"
    case velvet = "Velvet"
    case plum = "Plum"
    case navy = "Navy"
    case royal = "Royal"
    case teal = "Teal"
    case frog = "Frog"
    case leaf = "Leaf"
    case emerald = "Emerald"

    public var id: String {
        rawValue
    }

    public var backgroundHex: String {
        switch self {
        case .dark: return "1E1E1E"
        case .noir: return "000000"
        case .light: return "F5F5F5"
        case .beige, .linen: return "F5F1E4"
        case .poppy: return "FFE4E9"
        case .blossom: return "FFF0F5"
        case .velvet: return "2F2A44"
        case .plum: return "5C4B8A"
        case .navy: return "1C2E4A"
        case .royal: return "0F1826"
        case .teal: return "008080"
        case .frog: return "E8F3E8"
        case .leaf: return "051907"
        case .emerald: return "0D2B1D"
        }
    }

    public var workAccentHex: String {
        switch self {
        case .dark: return "81A1C1"
        case .noir: return "7D7D7D"
        case .light: return "5D8AA8"
        case .beige: return "8B5E3C"
        case .linen: return "1C2E4A"
        case .poppy: return "FF6B6B"
        case .blossom: return "DB7093"
        case .velvet: return "A76D99"
        case .plum: return "A77BCA"
        case .navy: return "F5F1E4"
        case .royal: return "D7C49E"
        case .teal: return "48D1CC"
        case .frog: return "2D5A27"
        case .leaf: return "2D5A27"
        case .emerald: return "6B8F71"
        }
    }

    public var breakAccentHex: String {
        switch self {
        case .dark: return "A3BE8C"
        case .noir: return "4B4B4B"
        case .light: return "6B8E23"
        case .beige: return "A68A64"
        case .linen: return "3E5C76"
        case .poppy: return "FF8FA3"
        case .blossom: return "EAB8C5"
        case .velvet: return "6F4C7A"
        case .plum: return "D6A6E0"
        case .navy: return "E8E4D5"
        case .royal: return "E0D5B6"
        case .teal: return "7FFFD4"
        case .frog: return "7FB069"
        case .leaf: return "558B2F"
        case .emerald: return "AEC3B0"
        }
    }

    public var textHex: String {
        switch self {
        case .dark: return "E0E0E0"
        case .noir: return "BFBFBF"
        case .light: return "333333"
        case .beige: return "4A3728"
        case .linen: return "1C2E4A"
        case .poppy: return "8B2942"
        case .blossom: return "5F3E49"
        case .velvet: return "E8BFD1"
        case .plum: return "EAD1E5"
        case .navy: return "F5F1E4"
        case .royal: return "E0D5B6"
        case .teal: return "E0FFFF"
        case .frog: return "1B3022"
        case .leaf: return "E8F5E9"
        case .emerald: return "E3EFD3"
        }
    }
}
