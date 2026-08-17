import XCTest
@testable import SnackSwapAdventure

/// 300 procedurally generated levels across three acts. Every level has to be
/// playable, and each act has to be a real step up rather than more of the same.
final class LevelCampaignTests: XCTestCase {

    func testCampaignIsThreeHundredLevelsInThreeActs() {
        XCTAssertEqual(LevelConfig.totalLevels, 300)
        XCTAssertEqual(LevelConfig.totalLevels, LevelConfig.levelsPerAct * 3)
        XCTAssertEqual(LevelConfig.Act.containing(level: 1).index, 0)
        XCTAssertEqual(LevelConfig.Act.containing(level: 100).index, 0)
        XCTAssertEqual(LevelConfig.Act.containing(level: 101).index, 1)
        XCTAssertEqual(LevelConfig.Act.containing(level: 200).index, 1)
        XCTAssertEqual(LevelConfig.Act.containing(level: 201).index, 2)
        XCTAssertEqual(LevelConfig.Act.containing(level: 300).index, 2)
    }

    /// The whole campaign is generated, so a single bad branch would ship a
    /// level nobody can complete. Sweep all 300.
    func testEveryLevelIsPlayable() {
        for level in 1...LevelConfig.totalLevels {
            let config = LevelConfig.level(level)

            XCTAssertEqual(config.levelNumber, level)
            XCTAssertTrue(
                (6...9).contains(config.boardSize),
                "level \(level) board \(config.boardSize) outside the drawable range"
            )
            XCTAssertGreaterThanOrEqual(config.moves, 10, "level \(level) has too few moves")
            XCTAssertGreaterThanOrEqual(config.timeLimit, 40, "level \(level) too little time")
            XCTAssertGreaterThan(config.targetScore, 0, "level \(level) has no score target")

            XCTAssertGreaterThanOrEqual(config.snackTypes.count, 3, "level \(level) too few snacks")
            XCTAssertLessThanOrEqual(config.snackTypes.count, SnackType.allCases.count)
            XCTAssertEqual(
                Set(config.snackTypes).count,
                config.snackTypes.count,
                "level \(level) repeats a snack type, skewing the board"
            )
            XCTAssertFalse(config.themeName.isEmpty, "level \(level) has no theme")
            XCTAssertFalse(config.worldName.isEmpty, "level \(level) has no world")

            // A goal of zero would complete instantly; a negative one never.
            switch config.goal {
            case .score(let n): XCTAssertGreaterThan(n, 0, "level \(level) score goal")
            case .collect(_, let n): XCTAssertGreaterThan(n, 0, "level \(level) collect goal")
            case .clearSnacks(let n): XCTAssertGreaterThan(n, 0, "level \(level) clear goal")
            case .makeCombos(let n): XCTAssertGreaterThan(n, 0, "level \(level) combo goal")
            }
        }
    }

    /// A collect goal must ask for a snack that is actually on the board.
    func testCollectGoalsUseSnacksPresentOnTheBoard() {
        for level in 1...LevelConfig.totalLevels {
            let config = LevelConfig.level(level)
            if case .collect(let snack, _) = config.goal {
                XCTAssertTrue(
                    config.snackTypes.contains(snack),
                    "level \(level) asks for \(snack.displayName), which never spawns"
                )
            }
        }
    }

    // MARK: - Act escalation

    func testSnackVarietyStepsUpWithEachAct() {
        let early = LevelConfig.snackVariety(for: 1)
        let actTwo = LevelConfig.snackVariety(for: 150)
        let actThree = LevelConfig.snackVariety(for: 250)
        XCTAssertLessThan(early, actTwo, "act two is no harder to read than act one")
        XCTAssertLessThanOrEqual(actTwo, actThree)
        XCTAssertEqual(actThree, SnackType.allCases.count, "the last act should use every snack")
    }

    func testBoardsGrowAcrossActs() {
        XCTAssertLessThan(
            LevelConfig.boardSize(for: 1),
            LevelConfig.boardSize(for: 250),
            "the final act plays on the same grid as the tutorial"
        )
        XCTAssertGreaterThanOrEqual(LevelConfig.boardSize(for: 201), 8)
    }

    /// Comparing the same position within each act isolates the act multiplier.
    func testScoreTargetsEscalateAcrossActs() {
        let actOne = LevelConfig.level(50).targetScore
        let actTwo = LevelConfig.level(150).targetScore
        let actThree = LevelConfig.level(250).targetScore
        XCTAssertGreaterThan(actTwo, actOne)
        XCTAssertGreaterThan(actThree, actTwo)
    }

    func testBudgetsTightenAcrossAnAct() {
        XCTAssertGreaterThan(
            LevelConfig.level(101).moves,
            LevelConfig.level(200).moves,
            "moves do not tighten through act two"
        )
        XCTAssertGreaterThan(
            LevelConfig.level(101).timeLimit,
            LevelConfig.level(200).timeLimit
        )
    }

    /// A new act opens on a bigger board with more colours, so it hands back
    /// some budget rather than continuing the previous act's squeeze.
    func testEachActOpensWithMoreRoomThanThePreviousActEnded() {
        XCTAssertGreaterThan(LevelConfig.level(101).moves, LevelConfig.level(100).moves)
        XCTAssertGreaterThan(LevelConfig.level(201).moves, LevelConfig.level(200).moves)
    }

    // MARK: - Theming

    func testEveryLevelIsThemedAndPalettesCycle() {
        XCTAssertEqual(
            LevelTheme.forLevel(1).name,
            LevelTheme.forLevel(LevelTheme.paletteCount + 1).name,
            "palettes should cycle so no level is unthemed"
        )
        for level in 1...LevelConfig.totalLevels {
            XCTAssertFalse(LevelTheme.forLevel(level).snacks.isEmpty, "level \(level)")
        }
    }

    func testOutOfRangeLevelsClampInsteadOfCrashing() {
        XCTAssertEqual(LevelConfig.level(0).levelNumber, 1)
        XCTAssertEqual(LevelConfig.level(-99).levelNumber, 1)
        XCTAssertEqual(LevelConfig.level(9_999).levelNumber, LevelConfig.totalLevels)
    }
}
