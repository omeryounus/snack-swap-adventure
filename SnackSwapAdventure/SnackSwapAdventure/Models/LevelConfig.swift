import SwiftUI
import SpriteKit

extension SKColor {
    convenience init(hex: String) {
        self.init(Color(hex: hex))
    }
}

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
    let plateAsset: String

    static func forLevel(_ level: Int) -> LevelTheme {
        let n = max(1, min(30, level))
        switch n {
        case 1:
            return LevelTheme(
                name: "Warm Cookie Bakery",
                snacks: [.cookie, .donut, .popcorn],
                bgColors: [Color(hex: "663311"), Color(hex: "D97724"), Color(hex: "261004")],
                boardFill: SKColor(red: 0.28, green: 0.14, blue: 0.08, alpha: 0.92),
                boardStroke: SKColor(Color(hex: "FF9E44")),
                plateAsset: "bg_gameplay_cookie"
            )
        case 2:
            return LevelTheme(
                name: "Donut Dreamland",
                snacks: [.donut, .lollipop, .cupcake],
                bgColors: [Color(hex: "6B1348"), Color(hex: "F04D9E"), Color(hex: "29051B")],
                boardFill: SKColor(red: 0.32, green: 0.10, blue: 0.24, alpha: 0.92),
                boardStroke: SKColor(hex: "FF73BE"),
                plateAsset: "bg_gameplay_cookie"
            )
        case 3:
            return LevelTheme(
                name: "Cinema Popcorn Party",
                snacks: [.popcorn, .candy, .cookie],
                bgColors: [Color(hex: "735606"), Color(hex: "F5C724"), Color(hex: "291D02")],
                boardFill: SKColor(red: 0.32, green: 0.24, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "FFE066"),
                plateAsset: "bg_gameplay_popcorn"
            )
        case 4:
            return LevelTheme(
                name: "Ocean Candy Breeze",
                snacks: [.candy, .cupcake, .lollipop],
                bgColors: [Color(hex: "0F446B"), Color(hex: "29A6FF"), Color(hex: "041A2B")],
                boardFill: SKColor(red: 0.08, green: 0.22, blue: 0.35, alpha: 0.92),
                boardStroke: SKColor(hex: "66C2FF"),
                plateAsset: "bg_gameplay_candy"
            )
        case 5:
            return LevelTheme(
                name: "Emerald Mint Creamery",
                snacks: [.cupcake, .cookie, .donut],
                bgColors: [Color(hex: "095730"), Color(hex: "2BE88A"), Color(hex: "032413")],
                boardFill: SKColor(red: 0.06, green: 0.28, blue: 0.18, alpha: 0.92),
                boardStroke: SKColor(hex: "66FFB3"),
                plateAsset: "bg_gameplay_cookie"
            )
        case 6:
            return LevelTheme(
                name: "Electric Purple Lagoon",
                snacks: [.lollipop, .donut, .popcorn],
                bgColors: [Color(hex: "4C0F6E"), Color(hex: "BA3BFF"), Color(hex: "1B042B")],
                boardFill: SKColor(red: 0.24, green: 0.08, blue: 0.36, alpha: 0.92),
                boardStroke: SKColor(hex: "D880FF"),
                plateAsset: "bg_gameplay_candy"
            )
        case 7:
            return LevelTheme(
                name: "Choco Caramel Crunch",
                snacks: [.cookie, .candy, .cupcake, .popcorn],
                bgColors: [Color(hex: "612B05"), Color(hex: "FF7014"), Color(hex: "240D01")],
                boardFill: SKColor(red: 0.32, green: 0.16, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "FFA057"),
                plateAsset: "bg_gameplay_cookie"
            )
        case 8:
            return LevelTheme(
                name: "Berry Blast Oasis",
                snacks: [.donut, .lollipop, .candy, .cookie],
                bgColors: [Color(hex: "700B20"), Color(hex: "FF2E5B"), Color(hex: "290209")],
                boardFill: SKColor(red: 0.36, green: 0.06, blue: 0.14, alpha: 0.92),
                boardStroke: SKColor(hex: "FF708F"),
                plateAsset: "bg_gameplay_candy"
            )
        case 9:
            return LevelTheme(
                name: "Golden Honeycomb",
                snacks: [.popcorn, .cupcake, .cookie, .lollipop],
                bgColors: [Color(hex: "466105"), Color(hex: "A0E82B"), Color(hex: "172401")],
                boardFill: SKColor(red: 0.24, green: 0.32, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "C4FF57"),
                plateAsset: "bg_gameplay_popcorn"
            )
        case 10:
            return LevelTheme(
                name: "Carnival Grand Fiesta",
                snacks: [.cookie, .donut, .candy, .popcorn, .lollipop],
                bgColors: [Color(hex: "310E63"), Color(hex: "8C47FF"), Color(hex: "110229")],
                boardFill: SKColor(red: 0.20, green: 0.08, blue: 0.38, alpha: 0.92),
                boardStroke: SKColor(hex: "B880FF"),
                plateAsset: "bg_gameplay_cookie"
            )
        case 11:
            return LevelTheme(
                name: "Coral Sunrise",
                snacks: [.popcorn, .cookie, .cupcake],
                bgColors: [Color(hex: "75280F"), Color(hex: "FF6238"), Color(hex: "2E0A02")],
                boardFill: SKColor(red: 0.38, green: 0.14, blue: 0.08, alpha: 0.92),
                boardStroke: SKColor(hex: "FF9070"),
                plateAsset: "bg_gameplay_popcorn"
            )
        case 12:
            return LevelTheme(
                name: "Sky Cyan Paradise",
                snacks: [.candy, .lollipop, .donut],
                bgColors: [Color(hex: "095B6E"), Color(hex: "34D5F8"), Color(hex: "03242C")],
                boardFill: SKColor(red: 0.06, green: 0.30, blue: 0.38, alpha: 0.92),
                boardStroke: SKColor(hex: "70E6FF"),
                plateAsset: "bg_gameplay_candy"
            )
        case 13:
            return LevelTheme(
                name: "Neon Magenta Festival",
                snacks: [.donut, .candy, .popcorn],
                bgColors: [Color(hex: "6E0959"), Color(hex: "FF26D4"), Color(hex: "2B0222")],
                boardFill: SKColor(red: 0.36, green: 0.06, blue: 0.30, alpha: 0.92),
                boardStroke: SKColor(hex: "FF70E5"),
                plateAsset: "bg_gameplay_cookie"
            )
        case 14:
            return LevelTheme(
                name: "Tropical Lime Groove",
                snacks: [.cupcake, .popcorn, .cookie],
                bgColors: [Color(hex: "316E0A"), Color(hex: "75FF26"), Color(hex: "112B02")],
                boardFill: SKColor(red: 0.18, green: 0.36, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "A0FF66"),
                plateAsset: "bg_gameplay_popcorn"
            )
        case 15:
            return LevelTheme(
                name: "Deep Cosmic Sapphire",
                snacks: [.lollipop, .cupcake, .candy],
                bgColors: [Color(hex: "0D226B"), Color(hex: "4776FF"), Color(hex: "030A2B")],
                boardFill: SKColor(red: 0.08, green: 0.14, blue: 0.38, alpha: 0.92),
                boardStroke: SKColor(hex: "80A3FF"),
                plateAsset: "bg_gameplay_candy"
            )
        case 16:
            return LevelTheme(
                name: "Rose Gold Bakery",
                snacks: [.cookie, .donut, .cupcake, .lollipop],
                bgColors: [Color(hex: "6B2130"), Color(hex: "FF6B86"), Color(hex: "2B080F")],
                boardFill: SKColor(red: 0.36, green: 0.12, blue: 0.18, alpha: 0.92),
                boardStroke: SKColor(hex: "FFA6B7"),
                plateAsset: "bg_gameplay_cookie"
            )
        case 17:
            return LevelTheme(
                name: "Sunset Amber Peak",
                snacks: [.popcorn, .candy, .cookie, .donut],
                bgColors: [Color(hex: "6B4408"), Color(hex: "FFAC1C"), Color(hex: "2B1902")],
                boardFill: SKColor(red: 0.36, green: 0.24, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "FFC966"),
                plateAsset: "bg_gameplay_popcorn"
            )
        case 18:
            return LevelTheme(
                name: "Lavender Moonlight",
                snacks: [.lollipop, .cupcake, .candy, .popcorn],
                bgColors: [Color(hex: "41266B"), Color(hex: "9B6BFF"), Color(hex: "160B2B")],
                boardFill: SKColor(red: 0.22, green: 0.14, blue: 0.38, alpha: 0.92),
                boardStroke: SKColor(hex: "C2A3FF"),
                plateAsset: "bg_gameplay_candy"
            )
        case 19:
            return LevelTheme(
                name: "Turquoise Ocean Splash",
                snacks: [.candy, .donut, .cookie, .lollipop],
                bgColors: [Color(hex: "0A6B5F"), Color(hex: "26FFE6"), Color(hex: "022B26")],
                boardFill: SKColor(red: 0.06, green: 0.36, blue: 0.32, alpha: 0.92),
                boardStroke: SKColor(hex: "70FFF0"),
                plateAsset: "bg_gameplay_candy"
            )
        case 20:
            return LevelTheme(
                name: "Strawberry Shortcake",
                snacks: [.cupcake, .cookie, .donut, .candy],
                bgColors: [Color(hex: "750F36"), Color(hex: "FF3B7B"), Color(hex: "2E0212")],
                boardFill: SKColor(red: 0.38, green: 0.08, blue: 0.20, alpha: 0.92),
                boardStroke: SKColor(hex: "FF85AB"),
                plateAsset: "bg_gameplay_cookie"
            )
        case 21:
            return LevelTheme(
                name: "Fiery Vulcan Sugar",
                snacks: [.candy, .popcorn, .cookie, .lollipop, .cupcake],
                bgColors: [Color(hex: "7A1B0D"), Color(hex: "FF4526"), Color(hex: "300803")],
                boardFill: SKColor(red: 0.40, green: 0.10, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "FF8370"),
                plateAsset: "bg_gameplay_candy"
            )
        case 22:
            return LevelTheme(
                name: "Glacier Ice Candy",
                snacks: [.lollipop, .candy, .donut, .cupcake, .popcorn],
                bgColors: [Color(hex: "0F6078"), Color(hex: "47EAFF"), Color(hex: "03242E")],
                boardFill: SKColor(red: 0.08, green: 0.32, blue: 0.40, alpha: 0.92),
                boardStroke: SKColor(hex: "8CFAFF"),
                plateAsset: "bg_gameplay_candy"
            )
        case 23:
            return LevelTheme(
                name: "Mystic Velvet Forest",
                snacks: [.cupcake, .cookie, .popcorn, .donut, .candy],
                bgColors: [Color(hex: "135E2A"), Color(hex: "3DF775"), Color(hex: "04260D")],
                boardFill: SKColor(red: 0.08, green: 0.32, blue: 0.16, alpha: 0.92),
                boardStroke: SKColor(hex: "85FFAC"),
                plateAsset: "bg_gameplay_cookie"
            )
        case 24:
            return LevelTheme(
                name: "Solar Flare Caramel",
                snacks: [.cookie, .popcorn, .lollipop, .candy, .donut],
                bgColors: [Color(hex: "7A550D"), Color(hex: "FFBC26"), Color(hex: "302003")],
                boardFill: SKColor(red: 0.40, green: 0.28, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "FFD570"),
                plateAsset: "bg_gameplay_popcorn"
            )
        case 25:
            return LevelTheme(
                name: "Crystal Quartz Cove",
                snacks: [.donut, .cupcake, .lollipop, .cookie, .popcorn],
                bgColors: [Color(hex: "471B78"), Color(hex: "AE47FF"), Color(hex: "1B0630")],
                boardFill: SKColor(red: 0.26, green: 0.10, blue: 0.40, alpha: 0.92),
                boardStroke: SKColor(hex: "D18CFF"),
                plateAsset: "bg_gameplay_candy"
            )
        case 26:
            return LevelTheme(
                name: "Neon Cyber Gummy",
                snacks: [.candy, .lollipop, .donut, .popcorn, .cookie],
                bgColors: [Color(hex: "0D6E66"), Color(hex: "26FFAE"), Color(hex: "032B27")],
                boardFill: SKColor(red: 0.06, green: 0.36, blue: 0.34, alpha: 0.92),
                boardStroke: SKColor(hex: "70FFCE"),
                plateAsset: "bg_gameplay_candy"
            )
        case 27:
            return LevelTheme(
                name: "Midnight Galaxy Crunch",
                snacks: [.popcorn, .cookie, .cupcake, .candy, .lollipop],
                bgColors: [Color(hex: "181152"), Color(hex: "5947FF"), Color(hex: "080424")],
                boardFill: SKColor(red: 0.10, green: 0.08, blue: 0.32, alpha: 0.92),
                boardStroke: SKColor(hex: "968CFF"),
                plateAsset: "bg_gameplay_popcorn"
            )
        case 28:
            return LevelTheme(
                name: "Sweet Blossom Meadow",
                snacks: [.cupcake, .donut, .cookie, .lollipop, .candy],
                bgColors: [Color(hex: "781B55"), Color(hex: "FF47B5"), Color(hex: "300620")],
                boardFill: SKColor(red: 0.40, green: 0.10, blue: 0.28, alpha: 0.92),
                boardStroke: SKColor(hex: "FF8CE0"),
                plateAsset: "bg_gameplay_cookie"
            )
        case 29:
            return LevelTheme(
                name: "Supernova Candy Blast",
                snacks: [.lollipop, .candy, .popcorn, .cupcake, .donut],
                bgColors: [Color(hex: "78440B"), Color(hex: "FF9D26"), Color(hex: "301A03")],
                boardFill: SKColor(red: 0.40, green: 0.24, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "FFC270"),
                plateAsset: "bg_gameplay_candy"
            )
        default:
            return LevelTheme(
                name: "Ultimate Master Snack Nirvana",
                snacks: [.cookie, .donut, .candy, .popcorn, .lollipop, .cupcake],
                bgColors: [Color(hex: "521152"), Color(hex: "FF3DF7"), Color(hex: "240424")],
                boardFill: SKColor(red: 0.30, green: 0.08, blue: 0.30, alpha: 0.92),
                boardStroke: SKColor(hex: "FF8CFA"),
                plateAsset: "bg_gameplay_cookie"
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
