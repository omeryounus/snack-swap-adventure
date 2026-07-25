import Foundation
import Combine

/// Daily reward calendar state and 24-hour persistence logic.
@MainActor
final class DailyRewardManager: ObservableObject {
    static let shared = DailyRewardManager()

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let lastClaimDate = "ssa.daily.lastClaimDate"
        static let currentDayIndex = "ssa.daily.currentDayIndex"
    }

    @Published var canClaimToday: Bool = false
    @Published var currentDayIndex: Int = 0

    let rewards: [DailyReward] = [
        DailyReward(day: 1, title: "Day 1", stars: 20, boosterName: nil, iconName: "star.fill"),
        DailyReward(day: 2, title: "Day 2", stars: 30, boosterName: nil, iconName: "star.fill"),
        DailyReward(day: 3, title: "Day 3", stars: 40, boosterName: "Snack Hammer", iconName: "hammer.fill"),
        DailyReward(day: 4, title: "Day 4", stars: 50, boosterName: nil, iconName: "star.fill"),
        DailyReward(day: 5, title: "Day 5", stars: 60, boosterName: "Color Bomb", iconName: "sparkles"),
        DailyReward(day: 6, title: "Day 6", stars: 80, boosterName: nil, iconName: "star.fill"),
        DailyReward(day: 7, title: "Day 7", stars: 150, boosterName: "Jackpot Bundle", iconName: "gift.fill")
    ]

    private init() {
        checkClaimStatus()
    }

    func checkClaimStatus() {
        let lastDate = defaults.object(forKey: Keys.lastClaimDate) as? Date ?? .distantPast
        currentDayIndex = defaults.integer(forKey: Keys.currentDayIndex)
        
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastDate) {
            canClaimToday = true
        } else {
            canClaimToday = false
        }
    }

    func claimToday() -> DailyReward? {
        guard canClaimToday else { return nil }
        
        let reward = rewards[currentDayIndex % rewards.count]
        
        // Award stars and boosters
        PlayerProfile.shared.addStars(reward.stars)
        if reward.boosterName == "Snack Hammer" {
            PlayerProfile.shared.hammerCount += 1
        } else if reward.boosterName == "Color Bomb" {
            PlayerProfile.shared.colorBombCount += 1
        } else if reward.boosterName == "Jackpot Bundle" {
            PlayerProfile.shared.hammerCount += 2
            PlayerProfile.shared.colorBombCount += 2
            PlayerProfile.shared.extraMovesCount += 2
        }

        defaults.set(Date(), forKey: Keys.lastClaimDate)
        currentDayIndex = (currentDayIndex + 1) % rewards.count
        defaults.set(currentDayIndex, forKey: Keys.currentDayIndex)
        canClaimToday = false

        Task { @MainActor in
            SoundManager.shared.playWin()
            VoiceAnnouncer.shared.announceHighScore()
        }
        return reward
    }
}

struct DailyReward: Identifiable {
    var id: Int { day }
    let day: Int
    let title: String
    let stars: Int
    let boosterName: String?
    let iconName: String
}
