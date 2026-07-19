import Foundation
import Combine

/// Local player identity + cached remote stats. Persists on device.
@MainActor
final class PlayerProfile: ObservableObject {
    static let shared = PlayerProfile()

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let playerId = "ssa.playerId"
        static let displayName = "ssa.displayName"
        static let avatarEmoji = "ssa.avatarEmoji"
        static let maxUnlockedLevel = "ssa.maxUnlockedLevel"
        static let localHighScore = "ssa.localHighScore"
        static let localTotalScore = "ssa.localTotalScore"
        static let localWins = "ssa.localWins"
        static let localLosses = "ssa.localLosses"
        static let localStars = "ssa.localStars"
        static let localMaxCombo = "ssa.localMaxCombo"
        static let localGamesPlayed = "ssa.localGamesPlayed"
        static let localHighestLevel = "ssa.localHighestLevel"
        static let localBestStreak = "ssa.localBestStreak"
        static let localCurrentStreak = "ssa.localCurrentStreak"
    }

    @Published var playerId: String
    @Published var displayName: String
    @Published var avatarEmoji: String
    @Published var maxUnlockedLevel: Int
    @Published var remoteStats: PlayerStatsDTO = .empty
    @Published var remoteRank: Int?
    @Published var isSyncing = false
    @Published var lastSyncError: String?
    @Published var lastSubmittedRank: Int?

    // Local lifetime stats (always available offline)
    @Published var localHighScore: Int
    @Published var localTotalScore: Int
    @Published var localWins: Int
    @Published var localLosses: Int
    @Published var localStars: Int
    @Published var localMaxCombo: Int
    @Published var localGamesPlayed: Int
    @Published var localHighestLevel: Int
    @Published var localBestStreak: Int
    @Published var localCurrentStreak: Int

    private init() {
        if let existing = defaults.string(forKey: Keys.playerId), !existing.isEmpty {
            playerId = existing
        } else {
            let id = UUID().uuidString.lowercased()
            defaults.set(id, forKey: Keys.playerId)
            playerId = id
        }

        displayName = defaults.string(forKey: Keys.displayName) ?? Self.randomName()
        avatarEmoji = defaults.string(forKey: Keys.avatarEmoji) ?? ["👾", "🍪", "🍩", "🍬", "🍿", "🍭", "🧁"].randomElement()!
        maxUnlockedLevel = max(1, defaults.integer(forKey: Keys.maxUnlockedLevel) == 0 ? 1 : defaults.integer(forKey: Keys.maxUnlockedLevel))

        localHighScore = defaults.integer(forKey: Keys.localHighScore)
        localTotalScore = defaults.integer(forKey: Keys.localTotalScore)
        localWins = defaults.integer(forKey: Keys.localWins)
        localLosses = defaults.integer(forKey: Keys.localLosses)
        localStars = defaults.integer(forKey: Keys.localStars)
        localMaxCombo = defaults.integer(forKey: Keys.localMaxCombo)
        localGamesPlayed = defaults.integer(forKey: Keys.localGamesPlayed)
        localHighestLevel = defaults.integer(forKey: Keys.localHighestLevel)
        localBestStreak = defaults.integer(forKey: Keys.localBestStreak)
        localCurrentStreak = defaults.integer(forKey: Keys.localCurrentStreak)

        // Persist defaults for first launch name/avatar
        defaults.set(displayName, forKey: Keys.displayName)
        defaults.set(avatarEmoji, forKey: Keys.avatarEmoji)
    }

    var localWinRate: Double {
        guard localGamesPlayed > 0 else { return 0 }
        return (Double(localWins) / Double(localGamesPlayed) * 1000).rounded() / 10
    }

    func setDisplayName(_ name: String) {
        let cleaned = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(20))
        guard !cleaned.isEmpty else { return }
        displayName = cleaned
        defaults.set(cleaned, forKey: Keys.displayName)
    }

    func setAvatar(_ emoji: String) {
        avatarEmoji = emoji
        defaults.set(emoji, forKey: Keys.avatarEmoji)
    }

    func unlockLevel(_ level: Int) {
        if level > maxUnlockedLevel {
            maxUnlockedLevel = level
            defaults.set(level, forKey: Keys.maxUnlockedLevel)
        }
    }

    /// Record a finished level locally, then push to the Vercel backend.
    func recordLevelResult(
        level: Int,
        score: Int,
        stars: Int,
        won: Bool,
        movesLeft: Int,
        maxCombo: Int
    ) async {
        localGamesPlayed += 1
        localTotalScore += score
        localHighScore = max(localHighScore, score)
        localMaxCombo = max(localMaxCombo, maxCombo)
        localHighestLevel = max(localHighestLevel, level)

        if won {
            localWins += 1
            localStars += stars
            localCurrentStreak += 1
            localBestStreak = max(localBestStreak, localCurrentStreak)
            unlockLevel(level + 1)
        } else {
            localLosses += 1
            localCurrentStreak = 0
        }

        persistLocal()

        await submitToServer(
            level: level,
            score: score,
            stars: stars,
            won: won,
            movesLeft: movesLeft,
            maxCombo: maxCombo
        )
    }

    func ensureRegistered() async {
        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }
        do {
            let player = try await APIClient.shared.registerPlayer(
                id: playerId,
                displayName: displayName,
                avatarEmoji: avatarEmoji
            )
            applyRemote(player)
        } catch {
            lastSyncError = error.localizedDescription
        }
    }

    func refreshRemoteStats() async {
        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }
        do {
            let response = try await APIClient.shared.playerStats(id: playerId)
            remoteStats = response.stats
            remoteRank = response.rank
            if !response.displayName.isEmpty {
                displayName = response.displayName
            }
        } catch {
            // First-time players may 404 — register then retry once.
            do {
                _ = try await APIClient.shared.registerPlayer(
                    id: playerId,
                    displayName: displayName,
                    avatarEmoji: avatarEmoji
                )
                let response = try await APIClient.shared.playerStats(id: playerId)
                remoteStats = response.stats
                remoteRank = response.rank
            } catch {
                lastSyncError = error.localizedDescription
            }
        }
    }

    func syncProfileToServer() async {
        do {
            let player = try await APIClient.shared.updatePlayer(
                id: playerId,
                displayName: displayName,
                avatarEmoji: avatarEmoji
            )
            applyRemote(player)
        } catch {
            // Register if patch fails (new player)
            await ensureRegistered()
        }
    }

    private func submitToServer(
        level: Int,
        score: Int,
        stars: Int,
        won: Bool,
        movesLeft: Int,
        maxCombo: Int
    ) async {
        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }
        do {
            let response = try await APIClient.shared.submitScore(
                ScoreSubmitRequest(
                    playerId: playerId,
                    displayName: displayName,
                    level: level,
                    score: score,
                    stars: stars,
                    won: won,
                    movesLeft: movesLeft,
                    maxCombo: maxCombo
                )
            )
            applyRemote(response.player)
            lastSubmittedRank = response.rank
            remoteRank = response.rank
        } catch {
            lastSyncError = error.localizedDescription
        }
    }

    private func applyRemote(_ player: PlayerDTO) {
        remoteStats = player.stats
        if let rank = player.rank {
            remoteRank = rank
        }
        if player.displayName != displayName {
            // Prefer local name unless remote is newer registration
        }
    }

    private func persistLocal() {
        defaults.set(localHighScore, forKey: Keys.localHighScore)
        defaults.set(localTotalScore, forKey: Keys.localTotalScore)
        defaults.set(localWins, forKey: Keys.localWins)
        defaults.set(localLosses, forKey: Keys.localLosses)
        defaults.set(localStars, forKey: Keys.localStars)
        defaults.set(localMaxCombo, forKey: Keys.localMaxCombo)
        defaults.set(localGamesPlayed, forKey: Keys.localGamesPlayed)
        defaults.set(localHighestLevel, forKey: Keys.localHighestLevel)
        defaults.set(localBestStreak, forKey: Keys.localBestStreak)
        defaults.set(localCurrentStreak, forKey: Keys.localCurrentStreak)
        defaults.set(maxUnlockedLevel, forKey: Keys.maxUnlockedLevel)
    }


    func awardLevelWin(level: Int, stars: Int, score: Int, coins: Int) {
        unlockLevel(level + 1)
        MetaProgress.shared.addCoins(coins)
        MetaProgress.shared.refreshMonsterUnlocks(maxLevel: max(maxUnlockedLevel, level + 1))
    }

    private static func randomName() -> String {
        let adjectives = ["Speedy", "Lucky", "Crispy", "Sweet", "Mighty", "Cosmic", "Happy", "Sneaky"]
        let nouns = ["Muncher", "Crumb", "Sprinkle", "Nibble", "Crunch", "Snack", "Bite", "Nom"]
        return "\(adjectives.randomElement()!)\(nouns.randomElement()!)\(Int.random(in: 10...99))"
    }
}
