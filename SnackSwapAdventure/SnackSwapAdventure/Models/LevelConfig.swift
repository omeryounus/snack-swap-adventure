import SwiftUI
import SpriteKit

extension SKColor {
    convenience init(hex: String) {
        self.init(Color(hex: hex))
    }

    /// Spins the hue while holding saturation and brightness, so a rotated
    /// palette keeps the contrast the original was designed with.
    func hueRotated(by degrees: Double) -> SKColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return self
        }
        let shifted = (hue + CGFloat(degrees / 360.0)).truncatingRemainder(dividingBy: 1)
        return SKColor(
            hue: shifted < 0 ? shifted + 1 : shifted,
            saturation: saturation,
            brightness: brightness,
            alpha: alpha
        )
    }
}

extension Color {
    func hueRotated(by degrees: Double) -> Color {
        Color(SKColor(self).hueRotated(by: degrees))
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

    /// Hand-authored base palettes. Each is reworked into a fresh variant for
    /// every lap of the campaign, so 300 levels get 300 distinct looks.
    static let paletteCount = 30

    /// Ten laps x 30 bases. The prefix renames the family so a variant reads as
    /// a new place rather than a repeat.
    static let variantPrefixes = [
        "", "Frosted", "Golden", "Midnight", "Neon",
        "Crystal", "Spiced", "Royal", "Cosmic", "Eternal"
    ]

    static func forLevel(_ level: Int) -> LevelTheme {
        let zero = max(1, level) - 1
        let base = basePalette(zero % paletteCount + 1)
        let lap = (zero / paletteCount) % variantPrefixes.count
        guard lap > 0 else { return base }

        // 37 degrees per lap never repeats within ten laps and keeps
        // neighbouring laps clearly apart.
        let shift = Double(lap) * 37.0
        return LevelTheme(
            name: "\(variantPrefixes[lap]) \(base.name)",
            snacks: base.snacks,
            bgColors: base.bgColors.map { $0.hueRotated(by: shift) },
            boardFill: base.boardFill.hueRotated(by: shift),
            boardStroke: base.boardStroke.hueRotated(by: shift)
        )
    }

    private static func basePalette(_ n: Int) -> LevelTheme {
        switch n {
        case 1:
            return LevelTheme(
                name: "Warm Cookie Bakery",
                snacks: [.cookie, .donut, .popcorn],
                bgColors: [Color(hex: "663311"), Color(hex: "D97724"), Color(hex: "261004")],
                boardFill: SKColor(red: 0.28, green: 0.14, blue: 0.08, alpha: 0.92),
                boardStroke: SKColor(Color(hex: "FF9E44"))
            )
        case 2:
            return LevelTheme(
                name: "Donut Dreamland",
                snacks: [.donut, .lollipop, .cupcake],
                bgColors: [Color(hex: "6B1348"), Color(hex: "F04D9E"), Color(hex: "29051B")],
                boardFill: SKColor(red: 0.32, green: 0.10, blue: 0.24, alpha: 0.92),
                boardStroke: SKColor(hex: "FF73BE")
            )
        case 3:
            return LevelTheme(
                name: "Cinema Popcorn Party",
                snacks: [.popcorn, .candy, .cookie],
                bgColors: [Color(hex: "735606"), Color(hex: "F5C724"), Color(hex: "291D02")],
                boardFill: SKColor(red: 0.32, green: 0.24, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "FFE066")
            )
        case 4:
            return LevelTheme(
                name: "Ocean Candy Breeze",
                snacks: [.candy, .cupcake, .lollipop],
                bgColors: [Color(hex: "0F446B"), Color(hex: "29A6FF"), Color(hex: "041A2B")],
                boardFill: SKColor(red: 0.08, green: 0.22, blue: 0.35, alpha: 0.92),
                boardStroke: SKColor(hex: "66C2FF")
            )
        case 5:
            return LevelTheme(
                name: "Emerald Mint Creamery",
                snacks: [.cupcake, .cookie, .donut],
                bgColors: [Color(hex: "095730"), Color(hex: "2BE88A"), Color(hex: "032413")],
                boardFill: SKColor(red: 0.06, green: 0.28, blue: 0.18, alpha: 0.92),
                boardStroke: SKColor(hex: "66FFB3")
            )
        case 6:
            return LevelTheme(
                name: "Electric Purple Lagoon",
                snacks: [.lollipop, .donut, .popcorn],
                bgColors: [Color(hex: "4C0F6E"), Color(hex: "BA3BFF"), Color(hex: "1B042B")],
                boardFill: SKColor(red: 0.24, green: 0.08, blue: 0.36, alpha: 0.92),
                boardStroke: SKColor(hex: "D880FF")
            )
        case 7:
            return LevelTheme(
                name: "Choco Caramel Crunch",
                snacks: [.cookie, .candy, .cupcake, .popcorn],
                bgColors: [Color(hex: "612B05"), Color(hex: "FF7014"), Color(hex: "240D01")],
                boardFill: SKColor(red: 0.32, green: 0.16, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "FFA057")
            )
        case 8:
            return LevelTheme(
                name: "Berry Blast Oasis",
                snacks: [.donut, .lollipop, .candy, .cookie],
                bgColors: [Color(hex: "700B20"), Color(hex: "FF2E5B"), Color(hex: "290209")],
                boardFill: SKColor(red: 0.36, green: 0.06, blue: 0.14, alpha: 0.92),
                boardStroke: SKColor(hex: "FF708F")
            )
        case 9:
            return LevelTheme(
                name: "Golden Honeycomb",
                snacks: [.popcorn, .cupcake, .cookie, .lollipop],
                bgColors: [Color(hex: "466105"), Color(hex: "A0E82B"), Color(hex: "172401")],
                boardFill: SKColor(red: 0.24, green: 0.32, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "C4FF57")
            )
        case 10:
            return LevelTheme(
                name: "Carnival Grand Fiesta",
                snacks: [.cookie, .donut, .candy, .popcorn, .lollipop],
                bgColors: [Color(hex: "310E63"), Color(hex: "8C47FF"), Color(hex: "110229")],
                boardFill: SKColor(red: 0.20, green: 0.08, blue: 0.38, alpha: 0.92),
                boardStroke: SKColor(hex: "B880FF")
            )
        case 11:
            return LevelTheme(
                name: "Coral Sunrise",
                snacks: [.popcorn, .cookie, .cupcake],
                bgColors: [Color(hex: "75280F"), Color(hex: "FF6238"), Color(hex: "2E0A02")],
                boardFill: SKColor(red: 0.38, green: 0.14, blue: 0.08, alpha: 0.92),
                boardStroke: SKColor(hex: "FF9070")
            )
        case 12:
            return LevelTheme(
                name: "Sky Cyan Paradise",
                snacks: [.candy, .lollipop, .donut],
                bgColors: [Color(hex: "095B6E"), Color(hex: "34D5F8"), Color(hex: "03242C")],
                boardFill: SKColor(red: 0.06, green: 0.30, blue: 0.38, alpha: 0.92),
                boardStroke: SKColor(hex: "70E6FF")
            )
        case 13:
            return LevelTheme(
                name: "Neon Magenta Festival",
                snacks: [.donut, .candy, .popcorn],
                bgColors: [Color(hex: "6E0959"), Color(hex: "FF26D4"), Color(hex: "2B0222")],
                boardFill: SKColor(red: 0.36, green: 0.06, blue: 0.30, alpha: 0.92),
                boardStroke: SKColor(hex: "FF70E5")
            )
        case 14:
            return LevelTheme(
                name: "Tropical Lime Groove",
                snacks: [.cupcake, .popcorn, .cookie],
                bgColors: [Color(hex: "316E0A"), Color(hex: "75FF26"), Color(hex: "112B02")],
                boardFill: SKColor(red: 0.18, green: 0.36, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "A0FF66")
            )
        case 15:
            return LevelTheme(
                name: "Deep Cosmic Sapphire",
                snacks: [.lollipop, .cupcake, .candy],
                bgColors: [Color(hex: "0D226B"), Color(hex: "4776FF"), Color(hex: "030A2B")],
                boardFill: SKColor(red: 0.08, green: 0.14, blue: 0.38, alpha: 0.92),
                boardStroke: SKColor(hex: "80A3FF")
            )
        case 16:
            return LevelTheme(
                name: "Rose Gold Bakery",
                snacks: [.cookie, .donut, .cupcake, .lollipop],
                bgColors: [Color(hex: "6B2130"), Color(hex: "FF6B86"), Color(hex: "2B080F")],
                boardFill: SKColor(red: 0.36, green: 0.12, blue: 0.18, alpha: 0.92),
                boardStroke: SKColor(hex: "FFA6B7")
            )
        case 17:
            return LevelTheme(
                name: "Sunset Amber Peak",
                snacks: [.popcorn, .candy, .cookie, .donut],
                bgColors: [Color(hex: "6B4408"), Color(hex: "FFAC1C"), Color(hex: "2B1902")],
                boardFill: SKColor(red: 0.36, green: 0.24, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "FFC966")
            )
        case 18:
            return LevelTheme(
                name: "Lavender Moonlight",
                snacks: [.lollipop, .cupcake, .candy, .popcorn],
                bgColors: [Color(hex: "41266B"), Color(hex: "9B6BFF"), Color(hex: "160B2B")],
                boardFill: SKColor(red: 0.22, green: 0.14, blue: 0.38, alpha: 0.92),
                boardStroke: SKColor(hex: "C2A3FF")
            )
        case 19:
            return LevelTheme(
                name: "Turquoise Ocean Splash",
                snacks: [.candy, .donut, .cookie, .lollipop],
                bgColors: [Color(hex: "0A6B5F"), Color(hex: "26FFE6"), Color(hex: "022B26")],
                boardFill: SKColor(red: 0.06, green: 0.36, blue: 0.32, alpha: 0.92),
                boardStroke: SKColor(hex: "70FFF0")
            )
        case 20:
            return LevelTheme(
                name: "Strawberry Shortcake",
                snacks: [.cupcake, .cookie, .donut, .candy],
                bgColors: [Color(hex: "750F36"), Color(hex: "FF3B7B"), Color(hex: "2E0212")],
                boardFill: SKColor(red: 0.38, green: 0.08, blue: 0.20, alpha: 0.92),
                boardStroke: SKColor(hex: "FF85AB")
            )
        case 21:
            return LevelTheme(
                name: "Fiery Vulcan Sugar",
                snacks: [.candy, .popcorn, .cookie, .lollipop, .cupcake],
                bgColors: [Color(hex: "7A1B0D"), Color(hex: "FF4526"), Color(hex: "300803")],
                boardFill: SKColor(red: 0.40, green: 0.10, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "FF8370")
            )
        case 22:
            return LevelTheme(
                name: "Glacier Ice Candy",
                snacks: [.lollipop, .candy, .donut, .cupcake, .popcorn],
                bgColors: [Color(hex: "0F6078"), Color(hex: "47EAFF"), Color(hex: "03242E")],
                boardFill: SKColor(red: 0.08, green: 0.32, blue: 0.40, alpha: 0.92),
                boardStroke: SKColor(hex: "8CFAFF")
            )
        case 23:
            return LevelTheme(
                name: "Mystic Velvet Forest",
                snacks: [.cupcake, .cookie, .popcorn, .donut, .candy],
                bgColors: [Color(hex: "135E2A"), Color(hex: "3DF775"), Color(hex: "04260D")],
                boardFill: SKColor(red: 0.08, green: 0.32, blue: 0.16, alpha: 0.92),
                boardStroke: SKColor(hex: "85FFAC")
            )
        case 24:
            return LevelTheme(
                name: "Solar Flare Caramel",
                snacks: [.cookie, .popcorn, .lollipop, .candy, .donut],
                bgColors: [Color(hex: "7A550D"), Color(hex: "FFBC26"), Color(hex: "302003")],
                boardFill: SKColor(red: 0.40, green: 0.28, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "FFD570")
            )
        case 25:
            return LevelTheme(
                name: "Crystal Quartz Cove",
                snacks: [.donut, .cupcake, .lollipop, .cookie, .popcorn],
                bgColors: [Color(hex: "471B78"), Color(hex: "AE47FF"), Color(hex: "1B0630")],
                boardFill: SKColor(red: 0.26, green: 0.10, blue: 0.40, alpha: 0.92),
                boardStroke: SKColor(hex: "D18CFF")
            )
        case 26:
            return LevelTheme(
                name: "Neon Cyber Gummy",
                snacks: [.candy, .lollipop, .donut, .popcorn, .cookie],
                bgColors: [Color(hex: "0D6E66"), Color(hex: "26FFAE"), Color(hex: "032B27")],
                boardFill: SKColor(red: 0.06, green: 0.36, blue: 0.34, alpha: 0.92),
                boardStroke: SKColor(hex: "70FFCE")
            )
        case 27:
            return LevelTheme(
                name: "Midnight Galaxy Crunch",
                snacks: [.popcorn, .cookie, .cupcake, .candy, .lollipop],
                bgColors: [Color(hex: "181152"), Color(hex: "5947FF"), Color(hex: "080424")],
                boardFill: SKColor(red: 0.10, green: 0.08, blue: 0.32, alpha: 0.92),
                boardStroke: SKColor(hex: "968CFF")
            )
        case 28:
            return LevelTheme(
                name: "Sweet Blossom Meadow",
                snacks: [.cupcake, .donut, .cookie, .lollipop, .candy],
                bgColors: [Color(hex: "781B55"), Color(hex: "FF47B5"), Color(hex: "300620")],
                boardFill: SKColor(red: 0.40, green: 0.10, blue: 0.28, alpha: 0.92),
                boardStroke: SKColor(hex: "FF8CE0")
            )
        case 29:
            return LevelTheme(
                name: "Supernova Candy Blast",
                snacks: [.lollipop, .candy, .popcorn, .cupcake, .donut],
                bgColors: [Color(hex: "78440B"), Color(hex: "FF9D26"), Color(hex: "301A03")],
                boardFill: SKColor(red: 0.40, green: 0.24, blue: 0.06, alpha: 0.92),
                boardStroke: SKColor(hex: "FFC270")
            )
        default:
            return LevelTheme(
                name: "Ultimate Master Snack Nirvana",
                snacks: [.cookie, .donut, .candy, .popcorn, .lollipop, .cupcake],
                bgColors: [Color(hex: "521152"), Color(hex: "FF3DF7"), Color(hex: "240424")],
                boardFill: SKColor(red: 0.30, green: 0.08, blue: 0.30, alpha: 0.92),
                boardStroke: SKColor(hex: "FF8CFA")
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
        let act = Act.containing(level: level)
        return (act.name, act.emoji)
    }

    /// Three acts of 100. Each act is a deliberate step up rather than a
    /// continuation of the same curve: more snack types on the board, a bigger
    /// grid, a tighter budget and steeper targets.
    struct Act {
        let index: Int
        let name: String
        let emoji: String
        let scoreMultiplier: Double

        static func containing(level: Int) -> Act {
            switch (max(1, level) - 1) / levelsPerAct {
            case 0: return Act(index: 0, name: "Snack Kingdom", emoji: "🍪", scoreMultiplier: 1.0)
            case 1: return Act(index: 1, name: "Sugar Frontier", emoji: "🍭", scoreMultiplier: 1.45)
            default: return Act(index: 2, name: "Master Bakery", emoji: "👑", scoreMultiplier: 2.0)
            }
        }
    }

    static let levelsPerAct = 100

    /// How far through its own act a level sits, 0..<100.
    static func stepWithinAct(_ level: Int) -> Int {
        (max(1, level) - 1) % levelsPerAct
    }

    static func boardSize(for level: Int) -> Int {
        let step = stepWithinAct(level)
        switch Act.containing(level: level).index {
        case 0: return step < 10 ? 6 : (step < 35 ? 7 : 8)
        case 1: return step < 20 ? 7 : (step < 60 ? 8 : 9)
        default: return step < 30 ? 8 : 9
        }
    }

    /// Fewer colours make matches easier to find, so this is the single
    /// strongest difficulty lever — it steps up once per act.
    static func snackVariety(for level: Int) -> Int {
        let step = stepWithinAct(level)
        switch Act.containing(level: level).index {
        case 0: return step < 20 ? 4 : 5
        case 1: return step < 30 ? 5 : 6
        default: return 6
        }
    }

    /// The level's palette first, topped up from the full set when the act
    /// calls for more colours than the theme names.
    static func snackTypes(for level: Int) -> [SnackType] {
        let theme = LevelTheme.forLevel(level)
        var chosen: [SnackType] = []
        for snack in theme.snacks where !chosen.contains(snack) {
            chosen.append(snack)
        }
        for snack in SnackType.allCases where !chosen.contains(snack) {
            chosen.append(snack)
        }
        let variety = min(max(3, snackVariety(for: level)), SnackType.allCases.count)
        return Array(chosen.prefix(variety))
    }

    static func level(_ number: Int) -> LevelConfig {
        let n = max(1, min(totalLevels, number))
        let act = Act.containing(level: n)
        let step = stepWithinAct(n)
        let world = world(for: n)
        let theme = LevelTheme.forLevel(n)

        let boardSize = boardSize(for: n)
        let snacks = snackTypes(for: n)

        // Budgets reset a little at each act boundary so a new act opens with
        // room to learn its board, then tighten across the hundred.
        let moveBase = [30, 26, 22][act.index]
        let moves = max(10, moveBase - step / 8)
        let timeBase = [125, 108, 96][act.index]
        let timeLimit = max(40, timeBase - step / 2)

        let totalCells = boardSize * boardSize
        let cellScale = Double(totalCells) / 64.0
        let baseScore = Double(400 + n * 180) * cellScale * act.scoreMultiplier
        // Rounded to a readable multiple of 50.
        let scoreTarget = max(300, Int((baseScore / 50).rounded()) * 50)

        let goal: LevelGoal
        switch n {
        case 1:
            goal = .clearSnacks(6)
        case 2:
            goal = .makeCombos(1)
        case 3:
            goal = .collect(.popcorn, count: 8)
        default:
            switch n % 4 {
            case 1:
                goal = .score(scoreTarget)
            case 2:
                let snack = snacks[n % snacks.count]
                let count = Int(Double(8 + step / 3) * cellScale * act.scoreMultiplier)
                goal = .collect(snack, count: max(8, count))
            case 3:
                let count = Int(Double(20 + step / 2) * cellScale * act.scoreMultiplier)
                goal = .clearSnacks(max(15, count))
            default:
                let combos = 2 + step / 12 + act.index * 2
                goal = .makeCombos(max(2, combos))
            }
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

    static let totalLevels = 300
}

enum GameOutcome: Equatable {
    case playing
    /// Timer hit zero — offer ad / stars before final fail.
    case timedOut
    case won(stars: Int, score: Int)
    case lost(score: Int)
}
