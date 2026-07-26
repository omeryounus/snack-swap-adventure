import SwiftUI
import SpriteKit

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

struct LevelTheme: Equatable {
    let name: String
    let snacks: [SnackType]
    let bgColors: [Color]
    let boardFill: SKColor
    let boardStroke: SKColor
    let backdropColor: SKColor
    let plateAsset: String

    static func forLevel(_ level: Int) -> LevelTheme {
        let n = max(1, min(30, level))
        switch n {
        case 1:
            return LevelTheme(
                name: "Warm Cookie Bakery",
                snacks: [.cookie, .donut, .candy, .popcorn],
                bgColors: [Color(hex: "2A140E"), Color(hex: "4D2415"), Color(hex: "120805")],
                boardFill: SKColor(red: 0.28, green: 0.16, blue: 0.12, alpha: 1.0),
                boardStroke: SKColor(red: 0.95, green: 0.65, blue: 0.35, alpha: 1.0),
                backdropColor: SKColor(red: 0.16, green: 0.08, blue: 0.06, alpha: 1.0),
                plateAsset: "bg_gameplay_cookie"
            )
        case 2:
            return LevelTheme(
                name: "Donut Dreamland",
                snacks: [.donut, .lollipop, .cupcake, .candy],
                bgColors: [Color(hex: "341126"), Color(hex: "5E1A42"), Color(hex: "14060F")],
                boardFill: SKColor(red: 0.30, green: 0.14, blue: 0.25, alpha: 1.0),
                boardStroke: SKColor(red: 1.00, green: 0.50, blue: 0.75, alpha: 1.0),
                backdropColor: SKColor(red: 0.18, green: 0.07, blue: 0.15, alpha: 1.0),
                plateAsset: "bg_gameplay_cookie"
            )
        case 3:
            return LevelTheme(
                name: "Cinema Popcorn Party",
                snacks: [.popcorn, .cookie, .cupcake, .lollipop],
                bgColors: [Color(hex: "2E2007"), Color(hex: "573B0C"), Color(hex: "120C03")],
                boardFill: SKColor(red: 0.28, green: 0.20, blue: 0.08, alpha: 1.0),
                boardStroke: SKColor(red: 1.00, green: 0.85, blue: 0.30, alpha: 1.0),
                backdropColor: SKColor(red: 0.16, green: 0.11, blue: 0.04, alpha: 1.0),
                plateAsset: "bg_gameplay_popcorn"
            )
        case 4:
            return LevelTheme(
                name: "Neon Candy Festival",
                snacks: [.candy, .lollipop, .donut, .popcorn],
                bgColors: [Color(hex: "0D2638"), Color(hex: "164866"), Color(hex: "050F17")],
                boardFill: SKColor(red: 0.10, green: 0.22, blue: 0.32, alpha: 1.0),
                boardStroke: SKColor(red: 0.35, green: 0.85, blue: 1.00, alpha: 1.0),
                backdropColor: SKColor(red: 0.05, green: 0.12, blue: 0.18, alpha: 1.0),
                plateAsset: "bg_gameplay_candy"
            )
        case 5:
            return LevelTheme(
                name: "Cupcake Creamery",
                snacks: [.cupcake, .cookie, .candy, .lollipop],
                bgColors: [Color(hex: "0C2B1F"), Color(hex: "18543D"), Color(hex: "04120D")],
                boardFill: SKColor(red: 0.10, green: 0.26, blue: 0.18, alpha: 1.0),
                boardStroke: SKColor(red: 0.40, green: 0.92, blue: 0.60, alpha: 1.0),
                backdropColor: SKColor(red: 0.05, green: 0.15, blue: 0.10, alpha: 1.0),
                plateAsset: "bg_gameplay_cookie"
            )
        case 6:
            return LevelTheme(
                name: "Lollipop Lagoon",
                snacks: [.lollipop, .donut, .cookie, .candy, .cupcake],
                bgColors: [Color(hex: "291038"), Color(hex: "521B6E"), Color(hex: "100517")],
                boardFill: SKColor(red: 0.24, green: 0.12, blue: 0.32, alpha: 1.0),
                boardStroke: SKColor(red: 0.78, green: 0.45, blue: 0.98, alpha: 1.0),
                backdropColor: SKColor(red: 0.14, green: 0.06, blue: 0.18, alpha: 1.0),
                plateAsset: "bg_gameplay_candy"
            )
        case 7:
            return LevelTheme(
                name: "Choco Caramel Crunch",
                snacks: [.cookie, .popcorn, .candy, .cupcake, .donut],
                bgColors: [Color(hex: "301B0E"), Color(hex: "5A3118"), Color(hex: "120904")],
                boardFill: SKColor(red: 0.30, green: 0.18, blue: 0.10, alpha: 1.0),
                boardStroke: SKColor(red: 0.92, green: 0.58, blue: 0.28, alpha: 1.0),
                backdropColor: SKColor(red: 0.16, green: 0.09, blue: 0.05, alpha: 1.0),
                plateAsset: "bg_gameplay_cookie"
            )
        case 8:
            return LevelTheme(
                name: "Berry Blast Oasis",
                snacks: [.donut, .lollipop, .candy, .cookie, .cupcake],
                bgColors: [Color(hex: "3B0F25"), Color(hex: "6A1741"), Color(hex: "15050C")],
                boardFill: SKColor(red: 0.32, green: 0.10, blue: 0.22, alpha: 1.0),
                boardStroke: SKColor(red: 1.00, green: 0.40, blue: 0.65, alpha: 1.0),
                backdropColor: SKColor(red: 0.18, green: 0.05, blue: 0.12, alpha: 1.0),
                plateAsset: "bg_gameplay_candy"
            )
        case 9:
            return LevelTheme(
                name: "Golden Honeycomb",
                snacks: [.popcorn, .cupcake, .cookie, .lollipop, .candy],
                bgColors: [Color(hex: "362608"), Color(hex: "66470C"), Color(hex: "150E03")],
                boardFill: SKColor(red: 0.32, green: 0.22, blue: 0.08, alpha: 1.0),
                boardStroke: SKColor(red: 1.00, green: 0.88, blue: 0.35, alpha: 1.0),
                backdropColor: SKColor(red: 0.18, green: 0.12, blue: 0.04, alpha: 1.0),
                plateAsset: "bg_gameplay_popcorn"
            )
        case 10:
            return LevelTheme(
                name: "Bakery Grand Carnival",
                snacks: [.cookie, .donut, .candy, .popcorn, .lollipop, .cupcake],
                bgColors: [Color(hex: "2B1238"), Color(hex: "56206B"), Color(hex: "100617")],
                boardFill: SKColor(red: 0.26, green: 0.14, blue: 0.34, alpha: 1.0),
                boardStroke: SKColor(red: 1.00, green: 0.70, blue: 0.30, alpha: 1.0),
                backdropColor: SKColor(red: 0.15, green: 0.07, blue: 0.20, alpha: 1.0),
                plateAsset: "bg_gameplay_cookie"
            )
        case 11...20:
            let sub = n - 10
            let names = ["Crispy Popcorn Sunrise", "Butterscotch Breeze", "Popcorn Twilight", "Caramel Mountain", "Popcorn Starlight", "Honey Meadow", "Golden Kernel Valley", "Velvet Popcorn Night", "Popcorn Galaxy", "Popcorn Kingdom Peak"]
            let snackPacks: [[SnackType]] = [
                [.popcorn, .cookie, .candy, .lollipop, .cupcake],
                [.popcorn, .donut, .cupcake, .cookie, .candy],
                [.popcorn, .lollipop, .donut, .candy, .cookie],
                [.popcorn, .cookie, .donut, .cupcake, .lollipop],
                [.popcorn, .candy, .cookie, .lollipop, .cupcake],
                [.popcorn, .donut, .candy, .cookie, .lollipop],
                [.popcorn, .cupcake, .donut, .lollipop, .candy],
                [.popcorn, .cookie, .lollipop, .candy, .donut],
                [.popcorn, .donut, .cookie, .candy, .cupcake],
                [.popcorn, .cookie, .donut, .candy, .lollipop, .cupcake]
            ]
            let bgSets: [[Color]] = [
                [Color(hex: "342008"), Color(hex: "613C0E"), Color(hex: "140B03")],
                [Color(hex: "2B1C0B"), Color(hex: "523514"), Color(hex: "100903")],
                [Color(hex: "201830"), Color(hex: "3F2E5C"), Color(hex: "0A0712")],
                [Color(hex: "331D0A"), Color(hex: "5C3312"), Color(hex: "120A03")],
                [Color(hex: "182436"), Color(hex: "2D4566"), Color(hex: "080D14")],
                [Color(hex: "2E240A"), Color(hex: "544212"), Color(hex: "100B03")],
                [Color(hex: "38220A"), Color(hex: "633C12"), Color(hex: "150C03")],
                [Color(hex: "24122C"), Color(hex: "482057"), Color(hex: "0D0512")],
                [Color(hex: "1A1838"), Color(hex: "322E69"), Color(hex: "080714")],
                [Color(hex: "3A2808"), Color(hex: "6B4A0E"), Color(hex: "160E03")]
            ]
            let idx = sub - 1
            return LevelTheme(
                name: names[idx],
                snacks: snackPacks[idx],
                bgColors: bgSets[idx],
                boardFill: SKColor(red: 0.28, green: 0.20, blue: 0.10, alpha: 1.0),
                boardStroke: SKColor(red: 1.00, green: 0.80, blue: 0.35, alpha: 1.0),
                backdropColor: SKColor(red: 0.16, green: 0.10, blue: 0.05, alpha: 1.0),
                plateAsset: "bg_gameplay_popcorn"
            )
        default:
            let sub = n - 20
            let names = ["Candy Cotton Sunset", "Fizzy Soda Splash", "Neon Gummy Grove", "Marshmallow Meadow", "Rainbow Swirl Peak", "Sugar Crystal Cove", "Jellybean Jackpot", "Bubblegum Realm", "Sweet Tooth Symphony", "Master Snack Nirvana"]
            let snackPacks: [[SnackType]] = [
                [.candy, .lollipop, .donut, .cupcake, .cookie],
                [.candy, .popcorn, .cookie, .lollipop, .donut],
                [.candy, .cupcake, .lollipop, .donut, .popcorn],
                [.candy, .donut, .cookie, .cupcake, .lollipop],
                [.candy, .lollipop, .popcorn, .donut, .cupcake],
                [.candy, .cookie, .donut, .popcorn, .lollipop],
                [.candy, .cupcake, .popcorn, .cookie, .donut],
                [.candy, .donut, .lollipop, .cookie, .cupcake],
                [.candy, .popcorn, .cupcake, .lollipop, .donut],
                [.cookie, .donut, .candy, .popcorn, .lollipop, .cupcake]
            ]
            let bgSets: [[Color]] = [
                [Color(hex: "38102B"), Color(hex: "661C4E"), Color(hex: "15050F")],
                [Color(hex: "0B2738"), Color(hex: "154969"), Color(hex: "040E14")],
                [Color(hex: "0F3224"), Color(hex: "1B5940"), Color(hex: "05140C")],
                [Color(hex: "2B1238"), Color(hex: "54206B"), Color(hex: "100616")],
                [Color(hex: "381A10"), Color(hex: "662E1C"), Color(hex: "150A05")],
                [Color(hex: "1A1B38"), Color(hex: "323569"), Color(hex: "080914")],
                [Color(hex: "382A0B"), Color(hex: "694F15"), Color(hex: "140F04")],
                [Color(hex: "381024"), Color(hex: "691B44"), Color(hex: "14050D")],
                [Color(hex: "281038"), Color(hex: "4D1B69"), Color(hex: "0F0516")],
                [Color(hex: "3B123B"), Color(hex: "6B1D6B"), Color(hex: "160616")]
            ]
            let idx = max(0, min(9, sub - 1))
            return LevelTheme(
                name: names[idx],
                snacks: snackPacks[idx],
                bgColors: bgSets[idx],
                boardFill: SKColor(red: 0.24, green: 0.12, blue: 0.30, alpha: 1.0),
                boardStroke: SKColor(red: 0.95, green: 0.50, blue: 0.90, alpha: 1.0),
                backdropColor: SKColor(red: 0.14, green: 0.06, blue: 0.18, alpha: 1.0),
                plateAsset: "bg_gameplay_candy"
            )
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
    let themeName: String

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
        let theme = LevelTheme.forLevel(n)
        
        let boardSize: Int
        switch n {
        case 1...5:
            boardSize = 6
        case 6...12:
            boardSize = 7
        case 13...22:
            boardSize = 8
        default:
            boardSize = 9
        }
        
        let snacks = theme.snacks
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
            worldEmoji: world.emoji,
            themeName: theme.name
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
