import Foundation

struct PlayerStatsDTO: Codable, Equatable {
    var highScore: Int
    var totalScore: Int
    var levelsCompleted: Int
    var levelsPlayed: Int
    var highestLevel: Int
    var totalStars: Int
    var maxCombo: Int
    var wins: Int
    var losses: Int
    var gamesPlayed: Int
    var bestSingleLevelScore: Int
    var currentWinStreak: Int
    var bestWinStreak: Int
    var winRate: Double?
    var averageScore: Int?

    static let empty = PlayerStatsDTO(
        highScore: 0,
        totalScore: 0,
        levelsCompleted: 0,
        levelsPlayed: 0,
        highestLevel: 0,
        totalStars: 0,
        maxCombo: 0,
        wins: 0,
        losses: 0,
        gamesPlayed: 0,
        bestSingleLevelScore: 0,
        currentWinStreak: 0,
        bestWinStreak: 0,
        winRate: 0,
        averageScore: 0
    )
}

struct PlayerDTO: Codable, Equatable, Identifiable {
    let id: String
    var displayName: String
    var avatarEmoji: String
    var createdAt: String?
    var updatedAt: String?
    var lastPlayedAt: String?
    var stats: PlayerStatsDTO
    var winRate: Double?
    var averageScore: Int?
    var rank: Int?
}

struct LeaderboardEntryDTO: Codable, Equatable, Identifiable {
    var id: String { playerId }
    let rank: Int
    let playerId: String
    let displayName: String
    let avatarEmoji: String
    let highScore: Int
    let totalScore: Int
    let highestLevel: Int
    let totalStars: Int
    let wins: Int
    let gamesPlayed: Int
    let winRate: Double
    let maxCombo: Int
    let lastPlayedAt: String
}

struct LeaderboardResponse: Codable {
    let sort: String
    let count: Int
    let entries: [LeaderboardEntryDTO]
}

struct PlayerResponse: Codable {
    let player: PlayerDTO
}

struct PlayersResponse: Codable {
    let count: Int
    let players: [PlayerDTO]
}

struct ScoreSubmitRequest: Codable {
    let playerId: String
    let displayName: String
    let level: Int
    let score: Int
    let stars: Int
    let won: Bool
    let movesLeft: Int
    let maxCombo: Int
}

struct ScoreSubmitResponse: Codable {
    let rank: Int
    let player: PlayerDTO
}

struct GlobalStatsDTO: Codable {
    let totalPlayers: Int
    let totalGamesPlayed: Int
    let totalWins: Int
    let totalScoreAllTime: Int
    let averageHighScore: Int
    let topScore: Int
    let topPlayerName: String?
    let levelsCompleted: Int
}

struct GlobalStatsResponse: Codable {
    let global: GlobalStatsDTO
    let top3: [LeaderboardEntryDTO]
}

struct PlayerStatsResponse: Codable {
    let playerId: String
    let displayName: String
    let avatarEmoji: String
    let rank: Int?
    let stats: PlayerStatsDTO
    let lastPlayedAt: String?
    let createdAt: String?
}

enum LeaderboardSort: String, CaseIterable, Identifiable {
    case highScore
    case totalScore
    case highestLevel
    case totalStars
    case wins
    case maxCombo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .highScore: return "High Score"
        case .totalScore: return "Total"
        case .highestLevel: return "Level"
        case .totalStars: return "Stars"
        case .wins: return "Wins"
        case .maxCombo: return "Combo"
        }
    }
}
