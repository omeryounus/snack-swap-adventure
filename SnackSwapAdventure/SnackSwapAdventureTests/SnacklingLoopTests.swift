import XCTest
@testable import SnackSwapAdventure

/// The Snackling loop is the game's second progression track, so its economy is
/// pinned here: how fast creatures evolve, and what an evolved collection is
/// actually worth in play.
final class SnacklingLoopTests: XCTestCase {

    // MARK: - Evolution

    func testStageThresholdsAreCumulativeAndOrdered() {
        let thresholds = SnacklingRules.stageThresholds
        XCTAssertEqual(thresholds.count, SnacklingRules.maxStage)
        XCTAssertEqual(thresholds, thresholds.sorted(), "thresholds must increase")
        XCTAssertGreaterThan(thresholds.first ?? 0, 0, "stage 1 must cost something")
    }

    func testStageForFeeds() {
        XCTAssertEqual(SnacklingRules.stage(forFeeds: 0), 0)
        XCTAssertEqual(SnacklingRules.stage(forFeeds: SnacklingRules.stageThresholds[0] - 1), 0)
        XCTAssertEqual(SnacklingRules.stage(forFeeds: SnacklingRules.stageThresholds[0]), 1)
        XCTAssertEqual(SnacklingRules.stage(forFeeds: SnacklingRules.stageThresholds[1]), 2)
        XCTAssertEqual(SnacklingRules.stage(forFeeds: SnacklingRules.stageThresholds[2]), 3)
    }

    func testStageNeverExceedsMaxNoMatterHowMuchYouFeed() {
        XCTAssertEqual(SnacklingRules.stage(forFeeds: 10_000), SnacklingRules.maxStage)
    }

    /// Progress must reset each stage rather than showing a bar that never moves.
    func testStageProgressIsRelativeToTheCurrentStage() {
        let firstTarget = SnacklingRules.stageThresholds[0]
        let atStart = SnacklingRules.stageProgress(forFeeds: 0)
        XCTAssertEqual(atStart.fed, 0)
        XCTAssertEqual(atStart.needed, firstTarget)

        // One feed past stage 1 should read as 1 into the second stage.
        let justEvolved = SnacklingRules.stageProgress(forFeeds: firstTarget + 1)
        XCTAssertEqual(justEvolved.fed, 1)
        XCTAssertEqual(justEvolved.needed, SnacklingRules.stageThresholds[1] - firstTarget)
    }

    func testMaxedSnacklingReportsNoRemainingProgress() {
        let progress = SnacklingRules.stageProgress(forFeeds: SnacklingRules.stageThresholds[2])
        XCTAssertEqual(progress.needed, 0, "a maxed Snackling should not show a target")
    }

    // MARK: - Rewards

    func testEveryWinPaysSomethingAndMoreStarsPayMore() {
        XCTAssertGreaterThan(SnacklingRules.snackReward(stars: 0), 0, "a win must always pay")
        XCTAssertGreaterThan(
            SnacklingRules.snackReward(stars: 3),
            SnacklingRules.snackReward(stars: 1),
            "three stars should beat one"
        )
    }

    func testRewardIgnoresImpossibleStarCounts() {
        XCTAssertEqual(SnacklingRules.snackReward(stars: 99), SnacklingRules.snackReward(stars: 3))
        XCTAssertEqual(SnacklingRules.snackReward(stars: -5), SnacklingRules.snackReward(stars: 0))
    }

    // MARK: - Perks

    func testNoPerksFromAnEmptyOrJustHatchedCollection() {
        XCTAssertEqual(SnacklingPerks.from(stages: []), .none)
        XCTAssertEqual(SnacklingPerks.from(stages: [0, 0, 1, 1]), .none, "hatchlings are not grown")
    }

    func testGrownSnacklingsGrantMoves() {
        XCTAssertEqual(SnacklingPerks.from(stages: [2]).bonusMoves, 1)
        XCTAssertEqual(SnacklingPerks.from(stages: [2, 2, 3]).bonusMoves, 3)
    }

    func testMovesPerkIsCapped() {
        let everything = Array(repeating: 3, count: 20)
        XCTAssertEqual(
            SnacklingPerks.from(stages: everything).bonusMoves,
            SnacklingPerks.maxBonusMoves,
            "an unbounded move bonus would trivialise every level"
        )
    }

    func testMaxLivesPerkNeedsSeveralFullyEvolvedSnacklings() {
        XCTAssertEqual(SnacklingPerks.from(stages: [3, 3]).bonusMaxLives, 0)
        XCTAssertEqual(SnacklingPerks.from(stages: [3, 3, 3]).bonusMaxLives, 1)
        XCTAssertEqual(SnacklingPerks.from(stages: Array(repeating: 3, count: 6)).bonusMaxLives, 2)
    }

    func testLivesPerkIsCapped() {
        let everything = Array(repeating: 3, count: 30)
        XCTAssertEqual(
            SnacklingPerks.from(stages: everything).bonusMaxLives,
            SnacklingPerks.maxBonusLives
        )
    }

    // MARK: - Species

    /// Every Snackling must eat something a level can actually drop, or it can
    /// never be fed.
    func testEverySnacklingEatsAnObtainableSnack() {
        let droppable = Set((1...LevelConfig.totalLevels).compactMap {
            LevelTheme.forLevel($0).snacks.first
        })
        XCTAssertFalse(droppable.isEmpty)
        for monster in MetaProgress.monsters {
            XCTAssertTrue(
                droppable.contains(monster.favouriteSnack),
                "\(monster.name) eats \(monster.favouriteSnack.displayName), which no level drops"
            )
        }
    }
}
