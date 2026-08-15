import XCTest
import UIKit
@testable import SnackSwapAdventure

final class GameplayBackgroundTests: XCTestCase {
    /// The old plates were full-screen mockups (Play, 3 stars, Next Level).
    /// They must not ship in the app or test bundle.
    func testMockupGameplayPlatesAreNotInTheCatalog() {
        let names = [
            "bg_gameplay_cookie",
            "bg_gameplay_popcorn",
            "bg_gameplay_candy",
            "bg_gameplay_soda"
        ]
        let bundles = [Bundle.main, Bundle(for: GameplayBackgroundTests.self)]
        for name in names {
            for bundle in bundles {
                XCTAssertNil(
                    UIImage(named: name, in: bundle, compatibleWith: nil),
                    "\(name) is a UI mockup and must not be in \(bundle.bundlePath)"
                )
            }
        }
    }

    func testWorldThemesUseSnacksNotWinStars() {
        for level in 1...40 {
            let theme = GameplayWorldTheme.forLevel(level)
            XCTAssertFalse(theme.snacks.isEmpty, "level \(level) missing snacks")
            XCTAssertFalse(
                theme.snacks.contains(where: { $0.contains("⭐") || $0.contains("🌟") }),
                "level \(level) theme must not paint win stars into the backdrop"
            )
        }
    }

    func testWorldBandsMatchLevelWorlds() {
        XCTAssertEqual(GameplayWorldTheme.forLevel(1).snacks.first, "🍪")
        XCTAssertEqual(GameplayWorldTheme.forLevel(10).snacks.first, "🍪")
        XCTAssertEqual(GameplayWorldTheme.forLevel(11).snacks.first, "🍿")
        XCTAssertEqual(GameplayWorldTheme.forLevel(20).snacks.first, "🍿")
        XCTAssertEqual(GameplayWorldTheme.forLevel(21).snacks.first, "🍬")
        XCTAssertEqual(GameplayWorldTheme.forLevel(30).snacks.first, "🍬")
        XCTAssertEqual(GameplayWorldTheme.forLevel(31).snacks.first, "🥤")
    }
}
