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
        let typeCount = min(6, 4 + ((n - 1) / 5))
        let snacks = Array(SnackType.allCases.prefix(typeCount))
        let moves = max(14, 30 - n)
        // Early levels get more time; later levels get tighter clocks.
        let timeLimit = max(45, 120 - n * 2)
        let scoreTarget = 1_600 + n * 350

        // Cycle goal types for variety.
        let goal: LevelGoal
        switch n % 4 {
        case 1:
            goal = .score(scoreTarget)
        case 2:
            let snack = snacks[n % snacks.count]
            goal = .collect(snack, count: 12 + n * 2)
        case 3:
            goal = .clearSnacks(40 + n * 4)
        default:
            goal = .makeCombos(max(2, 1 + n / 4))
        }

        return LevelConfig(
            levelNumber: n,
            boardSize: 8,
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
