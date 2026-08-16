import XCTest
@testable import SnackSwapAdventure

/// Lives gate play and are the main sink for stars, so every rule that could
/// hand one out for free is pinned here.
final class LivesRegenTests: XCTestCase {

    private let max = 5
    private let interval: TimeInterval = 30 * 60
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    private func apply(lives: Int, anchor: Date?, after seconds: TimeInterval) -> LivesRegen.Result {
        LivesRegen.apply(
            lives: lives,
            anchor: anchor,
            now: t0.addingTimeInterval(seconds),
            maxLives: max,
            interval: interval
        )
    }

    func testFullTankNeverRegenerates() {
        let result = apply(lives: max, anchor: t0, after: interval * 100)
        XCTAssertEqual(result.lives, max)
        XCTAssertNil(result.anchor, "a full tank should not be counting down")
    }

    func testNoLifeBeforeTheIntervalElapses() {
        let result = apply(lives: 2, anchor: t0, after: interval - 1)
        XCTAssertEqual(result.lives, 2)
        XCTAssertEqual(result.anchor, t0, "partial progress must be preserved")
    }

    func testOneLifePerInterval() {
        XCTAssertEqual(apply(lives: 2, anchor: t0, after: interval).lives, 3)
        XCTAssertEqual(apply(lives: 2, anchor: t0, after: interval * 2).lives, 4)
    }

    func testRemainderCarriesToTheNextLife() {
        // 1.5 intervals: one life granted, half an interval already banked.
        let result = apply(lives: 1, anchor: t0, after: interval * 1.5)
        XCTAssertEqual(result.lives, 2)
        XCTAssertEqual(
            result.anchor,
            t0.addingTimeInterval(interval),
            "the leftover half interval was thrown away"
        )
    }

    func testRegenerationStopsAtMaxAndClearsTheAnchor() {
        let result = apply(lives: 1, anchor: t0, after: interval * 50)
        XCTAssertEqual(result.lives, max, "regeneration overshot the cap")
        XCTAssertNil(result.anchor)
    }

    /// Winding the clock backwards must not bank negative progress, and must
    /// not stall regeneration forever either.
    func testClockMovedBackwardsReanchorsInsteadOfStalling() {
        let result = LivesRegen.apply(
            lives: 2,
            anchor: t0,
            now: t0.addingTimeInterval(-interval * 10),
            maxLives: max,
            interval: interval
        )
        XCTAssertEqual(result.lives, 2, "a backwards clock granted or removed lives")
        XCTAssertEqual(
            result.anchor,
            t0.addingTimeInterval(-interval * 10),
            "anchor should re-base to now so the timer keeps running"
        )
    }

    func testMissingAnchorStartsTheClockRatherThanGrantingALife() {
        let result = apply(lives: 0, anchor: nil, after: interval * 3)
        XCTAssertEqual(result.lives, 0, "a missing anchor must not mint lives")
        XCTAssertNotNil(result.anchor)
    }

    func testLivesAreClampedIntoRange() {
        XCTAssertEqual(apply(lives: -3, anchor: nil, after: 0).lives, 0)
        XCTAssertEqual(apply(lives: 99, anchor: nil, after: 0).lives, max)
    }

    func testZeroIntervalDoesNotDivideByZero() {
        let result = LivesRegen.apply(lives: 1, anchor: t0, now: t0, maxLives: max, interval: 0)
        XCTAssertEqual(result.lives, 1)
    }

    func testCountdownFormatting() {
        XCTAssertEqual(LivesPill.countdown(0), "0:00")
        XCTAssertEqual(LivesPill.countdown(59), "0:59")
        XCTAssertEqual(LivesPill.countdown(60), "1:00")
        XCTAssertEqual(LivesPill.countdown(1800), "30:00")
    }
}
