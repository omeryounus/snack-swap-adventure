import Foundation

enum LevelGoal: Equatable, Codable {
    case score(Int)
    case collect(SnackType, count: Int)
    case clearSnacks(Int)
    case makeCombos(Int)

    var shortTitle: String {
        switch self {
        case .score(let n): return "Score \(n)"
        case .collect(let type, let count): return "Collect \(count) \(type.emoji)"
        case .clearSnacks(let n): return "Clear \(n) snacks"
        case .makeCombos(let n): return "Make \(n) combos"
        }
    }

    var detail: String {
        switch self {
        case .score(let n): return "Reach \(n) points"
        case .collect(let type, let count): return "Match \(count) \(type.displayName)s"
        case .clearSnacks(let n): return "Clear \(n) snacks from the board"
        case .makeCombos(let n): return "Create \(n) cascade combos"
        }
    }
}

/// Level parameters for all 30 campaign levels.
struct LevelConfig: Equatable {
    let levelNumber: Int
    let boardSize: Int
    let moves: Int
    /// Countdown seconds for this level.
    let timeLimit: Int
    let targetScore: Int
    let snackTypes: [SnackType]
    let goal: LevelGoal
    let worldName: String
    let worldEmoji: String

    /// Seconds granted when the player extends time (ad or stars).
    static let timeExtensionSeconds = 30
    /// Star cost to buy a time extension.
    static let timeExtensionStarCost = 15

    /// Backward-compatible score target for HUD progress when goal is score-based.
    var progressDenominator: Int {
        switch goal {
        case .score(let n): return max(1, n)
        case .collect(_, let c): return max(1, c)
        case .clearSnacks(let n): return max(1, n)
        case .makeCombos(let n): return max(1, n)
        }
    }

    static let prototype = level(1)

    static func world(for level: Int) -> (name: String, emoji: String) {
        switch level {
        case 1...10: return ("Cookie Kingdom", "🍪")
        case 11...20: return ("Popcorn Plains", "🍿")
        default: return ("Candy Canyon", "🍬")
        }
    }

    static func level(_ number: Int) -> LevelConfig {
        let n = max(1, min(30, number))
        let world = world(for: n)
        
        // Define board size and snack counts dynamically based on level progression
        let boardSize: Int
        let typeCount: Int
        switch n {
        case 1...5:
            boardSize = 6
            typeCount = 4
        case 6...12:
            boardSize = 7
            typeCount = 5
        case 13...22:
            boardSize = 8
            typeCount = 5
        default:
            boardSize = 9
            typeCount = 6
        }
        
        let snacks = Array(SnackType.allCases.prefix(typeCount))
        let moves = max(12, 35 - n)
        let timeLimit = max(40, 130 - n * 3)
        
        // Scale scores and goals relative to board cells
        let totalCells = boardSize * boardSize
        let scoreTarget: Int
        let goal: LevelGoal
        
        switch n {
        case 1:
            scoreTarget = 300
            goal = .clearSnacks(6)
        case 2:
            scoreTarget = 500
            goal = .makeCombos(1)
        case 3:
            scoreTarget = 700
            goal = .collect(.popcorn, count: 8)
        case _ where n % 4 == 1:
            scoreTarget = (500 + n * 250) * totalCells / 64
            goal = .score(scoreTarget)
        case _ where n % 4 == 2:
            scoreTarget = (600 + n * 250) * totalCells / 64
            let snack = snacks[n % snacks.count]
            let collectCount = max(8, (8 + n * 2) * totalCells / 64)
            goal = .collect(snack, count: collectCount)
        case _ where n % 4 == 3:
            scoreTarget = (600 + n * 250) * totalCells / 64
            let clearCount = max(15, (25 + n * 3) * totalCells / 64)
            goal = .clearSnacks(clearCount)
        default:
            scoreTarget = (700 + n * 250) * totalCells / 64
            let combos = max(2, 2 + n / 5)
            goal = .makeCombos(combos)
        }
        
        return LevelConfig(
            levelNumber: n,
            boardSize: boardSize,
            moves: moves,
            timeLimit: timeLimit,
            targetScore: scoreTarget,
            snackTypes: snacks,
            goal: goal,
            worldName: world.name,
            worldEmoji: world.emoji
        )
    }

    static let totalLevels = 30
}

enum GameOutcome: Equatable {
    case playing
    /// Timer hit zero — offer ad / stars before final fail.
    case timedOut
    case won(stars: Int, score: Int)
    case lost(score: Int)
}
