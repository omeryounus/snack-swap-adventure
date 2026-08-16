import XCTest
import SwiftUI
@testable import SnackSwapAdventure

final class WinShareCardTests: XCTestCase {

    @MainActor
    func testRendersAShareableImage() throws {
        let image = WinShareCardRenderer.render(
            level: 7,
            themeName: "Choco Caramel Crunch",
            stars: 3,
            score: 8420,
            playerName: "HappyCrunch70",
            snacks: ["🍪", "🍩", "🍬"]
        )
        let card = try XCTUnwrap(image, "share card failed to render")
        // 380x480 points at scale 3.
        XCTAssertEqual(card.size.width, 380, accuracy: 1)
        XCTAssertEqual(card.size.height, 480, accuracy: 1)
        XCTAssertGreaterThan(card.scale, 1, "card would be blurry when shared")
    }

    @MainActor
    func testRendersWithNoSnacksOrThemeName() throws {
        // Levels above the themed range fall back to empty metadata; the card
        // still has to produce something shareable.
        let image = WinShareCardRenderer.render(
            level: 99,
            themeName: "",
            stars: 0,
            score: 0,
            playerName: "",
            snacks: []
        )
        XCTAssertNotNil(image, "share card must render even with empty metadata")
    }
}
