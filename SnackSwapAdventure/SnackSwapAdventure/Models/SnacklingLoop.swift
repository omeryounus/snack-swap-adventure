import Foundation
import SwiftUI

// MARK: - Rules (pure, so the economy can be tuned and tested without the UI)

/// How a Snackling grows. Thresholds are cumulative feeds.
enum SnacklingRules {
    /// Feeds needed to *reach* stage 1, 2 and 3.
    static let stageThresholds = [6, 18, 40]
    static let maxStage = 3

    /// Snacks a cleared level pays out. Replaying a finished level still pays,
    /// which is the point: it keeps 30 levels farmable.
    static func snackReward(stars: Int) -> Int {
        2 + max(0, min(3, stars))
    }

    static func stage(forFeeds feeds: Int) -> Int {
        var stage = 0
        for threshold in stageThresholds where feeds >= threshold {
            stage += 1
        }
        return min(stage, maxStage)
    }

    /// Progress within the current stage: (fed, needed). Needed is 0 at max.
    static func stageProgress(forFeeds feeds: Int) -> (fed: Int, needed: Int) {
        let stage = stage(forFeeds: feeds)
        guard stage < maxStage else { return (0, 0) }
        let floorValue = stage == 0 ? 0 : stageThresholds[stage - 1]
        let target = stageThresholds[stage]
        return (max(0, feeds - floorValue), max(1, target - floorValue))
    }

    static func stageName(_ stage: Int) -> String {
        switch stage {
        case 0: return "Hungry"
        case 1: return "Hatchling"
        case 2: return "Grown"
        default: return "Radiant"
        }
    }
}

/// What an evolved collection is worth in play. Kept mechanical rather than
/// cosmetic so the collection is a real progression track, not a sticker book.
struct SnacklingPerks: Equatable {
    var bonusMoves: Int
    var bonusMaxLives: Int

    static let none = SnacklingPerks(bonusMoves: 0, bonusMaxLives: 0)

    static let maxBonusMoves = 5
    static let maxBonusLives = 2

    /// - Parameter stages: current stage of every Snackling the player owns.
    static func from(stages: [Int]) -> SnacklingPerks {
        let grown = stages.filter { $0 >= 2 }.count
        let radiant = stages.filter { $0 >= SnacklingRules.maxStage }.count

        var lives = 0
        if radiant >= 3 { lives += 1 }
        if radiant >= 6 { lives += 1 }

        return SnacklingPerks(
            bonusMoves: min(maxBonusMoves, grown),
            bonusMaxLives: min(maxBonusLives, lives)
        )
    }
}

// MARK: - Species

extension MonsterDef {
    /// The snack this Snackling eats. Several share a favourite, which is what
    /// makes a level's drop useful to more than one of them.
    var favouriteSnack: SnackType {
        switch id {
        case "crumb": return .cookie
        case "cookie": return .cookie
        case "donut": return .donut
        case "candy": return .candy
        case "popcorn": return .popcorn
        case "lolli": return .lollipop
        case "cupcake": return .cupcake
        case "star": return .candy
        case "rainbow": return .lollipop
        default: return .cookie
        }
    }
}

// MARK: - Store

/// The snack pantry and every Snackling's feed count.
///
/// This is the second progression track: levels pay snacks, snacks feed
/// Snacklings, evolved Snacklings pay back into play. It deliberately does not
/// depend on beating harder levels, so a player stuck on a spike still moves
/// forward instead of churning.
@MainActor
final class SnacklingKeeper: ObservableObject {
    static let shared = SnacklingKeeper()

    private enum Keys {
        static let pantry = "ssa.snackPantry"
        static let feeds = "ssa.snacklingFeeds"
    }

    /// Snack counts keyed by SnackType.rawValue.
    @Published private(set) var pantry: [Int: Int] = [:]
    /// Feed totals keyed by MonsterDef.id.
    @Published private(set) var feeds: [String: Int] = [:]

    private let defaults = UserDefaults.standard

    private init() {
        if let stored = defaults.dictionary(forKey: Keys.pantry) as? [String: Int] {
            pantry = stored.reduce(into: [:]) { result, entry in
                if let key = Int(entry.key) { result[key] = max(0, entry.value) }
            }
        }
        feeds = (defaults.dictionary(forKey: Keys.feeds) as? [String: Int])?
            .mapValues { max(0, $0) } ?? [:]
    }

    // MARK: Pantry

    func count(of snack: SnackType) -> Int {
        pantry[snack.rawValue] ?? 0
    }

    var totalSnacks: Int { pantry.values.reduce(0, +) }

    /// Pays out a cleared level. Returns what was granted so the UI can show it.
    @discardableResult
    func awardLevelReward(level: Int, stars: Int) -> (snack: SnackType, amount: Int) {
        let theme = LevelTheme.forLevel(level)
        let snack = theme.snacks.first ?? .cookie
        let amount = SnacklingRules.snackReward(stars: stars)
        pantry[snack.rawValue, default: 0] += amount
        persistPantry()
        return (snack, amount)
    }

    // MARK: Feeding

    func feedCount(for monster: MonsterDef) -> Int {
        feeds[monster.id] ?? 0
    }

    func stage(for monster: MonsterDef) -> Int {
        SnacklingRules.stage(forFeeds: feedCount(for: monster))
    }

    func canFeed(_ monster: MonsterDef) -> Bool {
        stage(for: monster) < SnacklingRules.maxStage
            && count(of: monster.favouriteSnack) > 0
    }

    /// Spends one favourite snack. Returns the new stage if it evolved.
    @discardableResult
    func feed(_ monster: MonsterDef) -> Int? {
        guard canFeed(monster) else { return nil }
        let before = stage(for: monster)

        pantry[monster.favouriteSnack.rawValue, default: 0] -= 1
        feeds[monster.id, default: 0] += 1
        persistPantry()
        persistFeeds()

        let after = stage(for: monster)
        if after > before {
            applyPerks()
            return after
        }
        return nil
    }

    // MARK: Perks

    /// Perks for every Snackling the player has unlocked.
    func perks(unlocked: [MonsterDef]) -> SnacklingPerks {
        SnacklingPerks.from(stages: unlocked.map { stage(for: $0) })
    }

    var currentPerks: SnacklingPerks {
        let unlocked = MetaProgress.monsters.filter {
            MetaProgress.shared.isMonsterUnlocked($0.id)
        }
        return perks(unlocked: unlocked)
    }

    /// Pushes the max-lives perk into LivesManager. Called on change and launch.
    func applyPerks() {
        LivesManager.shared.setBonusMaxLives(currentPerks.bonusMaxLives)
    }

    private func persistPantry() {
        let encoded = pantry.reduce(into: [String: Int]()) { $0["\($1.key)"] = $1.value }
        defaults.set(encoded, forKey: Keys.pantry)
    }

    private func persistFeeds() {
        defaults.set(feeds, forKey: Keys.feeds)
    }
}
