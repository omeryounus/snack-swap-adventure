import XCTest
@testable import SnackSwapAdventure

/// The gameplay backdrop is composed from a seed seeded by level number, so a
/// level looks the same every time you play it but different from its
/// neighbours. Both halves of that matter.
final class SeededGeneratorTests: XCTestCase {

    private func sequence(seed: UInt64, count: Int = 12) -> [Double] {
        var rng = SeededGenerator(seed: seed)
        return (0..<count).map { _ in rng.unit() }
    }

    func testSameSeedAlwaysProducesTheSameSequence() {
        XCTAssertEqual(
            sequence(seed: 1_234),
            sequence(seed: 1_234),
            "a level's backdrop would change every launch"
        )
    }

    func testDifferentSeedsDiverge() {
        XCTAssertNotEqual(
            sequence(seed: 1_234),
            sequence(seed: 1_235),
            "neighbouring levels would share a layout"
        )
    }

    /// Values feed straight into unit-space positions, so anything outside
    /// 0..<1 would place a snack off screen.
    func testUnitValuesStayInRange() {
        var rng = SeededGenerator(seed: 99)
        for _ in 0..<500 {
            let value = rng.unit()
            XCTAssertGreaterThanOrEqual(value, 0)
            XCTAssertLessThan(value, 1)
        }
    }

    func testBoundedNextStaysBelowBound() {
        var rng = SeededGenerator(seed: 7)
        for _ in 0..<200 {
            XCTAssertLessThan(rng.next(upTo: 6), 6)
        }
    }

    /// A zero bound is what an empty snack list would produce; it must not trap.
    func testZeroBoundIsSafe() {
        var rng = SeededGenerator(seed: 7)
        XCTAssertEqual(rng.next(upTo: 0), 0)
    }

    /// A zero seed must not collapse the generator to a constant.
    func testZeroSeedStillVaries() {
        let values = sequence(seed: 0)
        XCTAssertGreaterThan(Set(values).count, 1, "zero seed produced a constant stream")
    }

    /// Every level in the campaign should get a distinct arrangement.
    func testEveryLevelSeedIsDistinct() {
        var fingerprints: [String] = []
        for level in 1...LevelConfig.totalLevels {
            let seed = UInt64(level &* 2_654_435_761 &+ 17)
            let values: [Double] = sequence(seed: seed, count: 6)
            let parts: [String] = values.map { String($0) }
            fingerprints.append(parts.joined(separator: ","))
        }
        XCTAssertEqual(
            Set(fingerprints).count,
            fingerprints.count,
            "two levels share a backdrop layout"
        )
    }
}
