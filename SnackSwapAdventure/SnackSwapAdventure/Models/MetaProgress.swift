import Foundation
import Combine

struct MonsterDef: Identifiable, Equatable {
    let id: String
    let name: String
    let emoji: String
    let unlockLevel: Int
    let blurb: String
}

struct ShopItem: Identifiable, Equatable {
    let id: String
    let name: String
    let emoji: String
    let cost: Int
    let description: String
    let kind: ShopItemKind
}

enum ShopItemKind: String, Codable {
    case hammer
    case extraMoves
    case shuffle
}

/// Campaign monsters + shop inventory (local meta progression).
@MainActor
final class MetaProgress: ObservableObject {
    static let shared = MetaProgress()

    static let monsters: [MonsterDef] = [
        MonsterDef(id: "crumb", name: "Crumb", emoji: "👾", unlockLevel: 1, blurb: "Your first hungry friend."),
        MonsterDef(id: "cookie", name: "Chippy", emoji: "🍪", unlockLevel: 3, blurb: "Cookie Kingdom mascot."),
        MonsterDef(id: "donut", name: "Glazey", emoji: "🍩", unlockLevel: 6, blurb: "Sweet tooth supreme."),
        MonsterDef(id: "candy", name: "Sourpuss", emoji: "🍬", unlockLevel: 9, blurb: "Tangy and proud."),
        MonsterDef(id: "popcorn", name: "Popster", emoji: "🍿", unlockLevel: 12, blurb: "Always exploding with joy."),
        MonsterDef(id: "lolli", name: "Twizzle", emoji: "🍭", unlockLevel: 16, blurb: "Spiral snack sorcerer."),
        MonsterDef(id: "cupcake", name: "Frostina", emoji: "🧁", unlockLevel: 20, blurb: "Frosted royalty."),
        MonsterDef(id: "star", name: "Starbite", emoji: "⭐", unlockLevel: 25, blurb: "Legendary snack spirit."),
        MonsterDef(id: "rainbow", name: "Prism", emoji: "🌈", unlockLevel: 30, blurb: "Master of the rainbow donut."),
    ]

    static let shopCatalog: [ShopItem] = [
        ShopItem(id: "hammer", name: "Snack Hammer", emoji: "🔨", cost: 80, description: "Smash one snack (next level start).", kind: .hammer),
        ShopItem(id: "moves", name: "+5 Moves", emoji: "➕", cost: 120, description: "Start the next level with 5 extra moves.", kind: .extraMoves),
        ShopItem(id: "shuffle", name: "Board Shuffle", emoji: "🔀", cost: 100, description: "Shuffle the board once next level.", kind: .shuffle),
        ShopItem(id: "time", name: "+30s Pack", emoji: "⏱️", cost: 90, description: "Queue +30s for next level start.", kind: .extraMoves),
    ]

    /// Stars awarded per successful friend invite share.
    static let inviteRewardStars = 25
    static let maxInviteRewardsPerDay = 5

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let coins = "ssa.coins"
        static let stars = "ssa.stars"
        static let unlockedMonsters = "ssa.unlockedMonsters"
        static let inventory = "ssa.inventory"
        static let soundEnabled = "ssa.soundEnabled"
        static let musicEnabled = "ssa.musicEnabled"
        static let pendingBoosters = "ssa.pendingBoosters"
        static let inviteCode = "ssa.inviteCode"
        static let invitesToday = "ssa.invitesToday"
        static let invitesDay = "ssa.invitesDay"
        static let totalInvites = "ssa.totalInvites"
    }

    @Published var coins: Int
    @Published var stars: Int
    @Published var unlockedMonsterIDs: Set<String>
    @Published var inventory: [String: Int]
    @Published var soundEnabled: Bool
    @Published var musicEnabled: Bool
    @Published var pendingBoosters: [String]
    @Published var inviteCode: String
    @Published var invitesToday: Int
    @Published var totalInvites: Int

    private init() {
        let savedCoins = defaults.object(forKey: Keys.coins) == nil ? 150 : defaults.integer(forKey: Keys.coins)
        if defaults.object(forKey: Keys.coins) == nil {
            defaults.set(savedCoins, forKey: Keys.coins)
        }
        coins = savedCoins

        let savedStars = defaults.object(forKey: Keys.stars) == nil ? 40 : defaults.integer(forKey: Keys.stars)
        if defaults.object(forKey: Keys.stars) == nil {
            defaults.set(savedStars, forKey: Keys.stars)
        }
        stars = savedStars

        let monsters: Set<String>
        if let arr = defaults.array(forKey: Keys.unlockedMonsters) as? [String] {
            monsters = Set(arr)
        } else {
            monsters = ["crumb"]
        }
        unlockedMonsterIDs = monsters

        let inv: [String: Int]
        if let data = defaults.data(forKey: Keys.inventory),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            inv = decoded
        } else {
            inv = [:]
        }
        inventory = inv

        soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        musicEnabled = defaults.object(forKey: Keys.musicEnabled) as? Bool ?? true
        pendingBoosters = defaults.stringArray(forKey: Keys.pendingBoosters) ?? []

        if let code = defaults.string(forKey: Keys.inviteCode), !code.isEmpty {
            inviteCode = code
        } else {
            let code = "SNACK-\(String(UUID().uuidString.prefix(6)).uppercased())"
            inviteCode = code
            defaults.set(code, forKey: Keys.inviteCode)
        }

        totalInvites = defaults.integer(forKey: Keys.totalInvites)
        let today = Self.dayStamp()
        if defaults.string(forKey: Keys.invitesDay) == today {
            invitesToday = defaults.integer(forKey: Keys.invitesToday)
        } else {
            invitesToday = 0
            defaults.set(today, forKey: Keys.invitesDay)
            defaults.set(0, forKey: Keys.invitesToday)
        }
    }

    private static func dayStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    func isMonsterUnlocked(_ id: String) -> Bool {
        unlockedMonsterIDs.contains(id)
    }

    func refreshMonsterUnlocks(maxLevel: Int) {
        for m in Self.monsters where maxLevel >= m.unlockLevel {
            unlockedMonsterIDs.insert(m.id)
        }
        defaults.set(Array(unlockedMonsterIDs), forKey: Keys.unlockedMonsters)
    }

    func addCoins(_ amount: Int) {
        coins += max(0, amount)
        defaults.set(coins, forKey: Keys.coins)
    }

    func addStars(_ amount: Int) {
        stars += max(0, amount)
        defaults.set(stars, forKey: Keys.stars)
    }

    @discardableResult
    func spendStars(_ amount: Int) -> Bool {
        guard stars >= amount else { return false }
        stars -= amount
        defaults.set(stars, forKey: Keys.stars)
        return true
    }

    /// Reward stars after sharing invite link (capped per day).
    @discardableResult
    func claimInviteReward() -> Int {
        let today = Self.dayStamp()
        if defaults.string(forKey: Keys.invitesDay) != today {
            invitesToday = 0
            defaults.set(today, forKey: Keys.invitesDay)
        }
        guard invitesToday < Self.maxInviteRewardsPerDay else { return 0 }
        invitesToday += 1
        totalInvites += 1
        defaults.set(invitesToday, forKey: Keys.invitesToday)
        defaults.set(totalInvites, forKey: Keys.totalInvites)
        addStars(Self.inviteRewardStars)
        return Self.inviteRewardStars
    }

    var inviteShareMessage: String {
        """
        🍪 Join me in Snack Swap Adventure!
        Match snacks, feed monsters, and race the clock.
        Use my invite code \(inviteCode) and we both get free ⭐!
        """
    }

    @discardableResult
    func buy(_ item: ShopItem) -> Bool {
        guard coins >= item.cost else { return false }
        coins -= item.cost
        inventory[item.id, default: 0] += 1
        defaults.set(coins, forKey: Keys.coins)
        if let data = try? JSONEncoder().encode(inventory) {
            defaults.set(data, forKey: Keys.inventory)
        }
        return true
    }

    func queueBooster(_ itemId: String) -> Bool {
        guard let count = inventory[itemId], count > 0 else { return false }
        inventory[itemId] = count - 1
        pendingBoosters.append(itemId)
        if let data = try? JSONEncoder().encode(inventory) {
            defaults.set(data, forKey: Keys.inventory)
        }
        defaults.set(pendingBoosters, forKey: Keys.pendingBoosters)
        return true
    }

    func consumePendingBoosters() -> [String] {
        let items = pendingBoosters
        pendingBoosters = []
        defaults.set(pendingBoosters, forKey: Keys.pendingBoosters)
        return items
    }

    func setSoundEnabled(_ on: Bool) {
        soundEnabled = on
        defaults.set(on, forKey: Keys.soundEnabled)
        SoundManager.shared.setEnabled(on)
    }

    func setMusicEnabled(_ on: Bool) {
        musicEnabled = on
        defaults.set(on, forKey: Keys.musicEnabled)
        if on {
            MusicPlayer.shared.play()
        } else {
            MusicPlayer.shared.stop()
        }
    }
}
