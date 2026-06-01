import XCTest
@testable import DropletCore

final class DropletThemeTests: XCTestCase {
    func testThemeCatalogMatchesMacAppThemeNames() {
        XCTAssertEqual(
            DropletTheme.allCases.map(\.rawValue),
            [
                "Dark",
                "Noir",
                "Light",
                "Beige",
                "Linen",
                "Poppy",
                "Blossom",
                "Velvet",
                "Plum",
                "Navy",
                "Royal",
                "Teal",
                "Frog",
                "Leaf",
                "Emerald"
            ]
        )
    }

    func testThemeHexValuesMatchMacAppPalette() {
        XCTAssertEqual(DropletTheme.dark.backgroundHex, "1E1E1E")
        XCTAssertEqual(DropletTheme.dark.workAccentHex, "81A1C1")
        XCTAssertEqual(DropletTheme.dark.breakAccentHex, "A3BE8C")
        XCTAssertEqual(DropletTheme.dark.textHex, "E0E0E0")

        XCTAssertEqual(DropletTheme.poppy.backgroundHex, "FFE4E9")
        XCTAssertEqual(DropletTheme.poppy.workAccentHex, "FF6B6B")
        XCTAssertEqual(DropletTheme.poppy.breakAccentHex, "FF8FA3")
        XCTAssertEqual(DropletTheme.poppy.textHex, "8B2942")

        XCTAssertEqual(DropletTheme.emerald.backgroundHex, "0D2B1D")
        XCTAssertEqual(DropletTheme.emerald.workAccentHex, "6B8F71")
        XCTAssertEqual(DropletTheme.emerald.breakAccentHex, "AEC3B0")
        XCTAssertEqual(DropletTheme.emerald.textHex, "E3EFD3")
    }
}
