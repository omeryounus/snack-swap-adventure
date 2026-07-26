import Foundation
import Combine

struct DailyRewardItem: Identifiable {
    let id = UUID()
    let day: Int
    let title: String
    let stars: Int
    let hammers: Int
    let colorBombs: Int
    let extraMoves: Int
    let icon: String
}

/// Manages 7-day login streak rewards and claim state.
@MainActor
final class DailyRewardsManager: ObservableObject {
    static let shared = DailyRewardsManager()

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let lastClaimDate = "ssa.dailyReward.lastClaimDate"
        static let currentStreak = "ssa.dailyReward.currentStreak"
    }

    @Published var currentStreak: Int = 1
    @Published var isRewardAvailable: Bool = false

    let rewardSchedule: [DailyRewardItem] = [
        DailyRewardItem(day: 1, title: "Day 1", stars: 50, hammers: 0, colorBombs: 0, extraMoves: 0, icon: "⭐"),
        DailyRewardItem(day: 2, title: "Day 2", stars: 100, hammers: 1, colorBombs: 0, extraMoves: 0, icon: "🔨"),
        DailyRewardItem(day: 3, title: "Day 3", stars: 150, hammers: 0, colorBombs: 0, extraMoves: 0, icon: "🌟"),
        DailyRewardItem(day: 4, title: "Day 4", stars: 200, hammers: 0, colorBombs: 2, extraMoves: 0, icon: "🚀"),
        DailyRewardItem(day: 5, title: "Day 5", stars: 300, hammers: 0, colorBombs: 0, extraMoves: 0, icon: "💎"),
        DailyRewardItem(day: 6, title: "Day 6", stars: 400, hammers: 0, colorBombs: 0, extraMoves: 3, icon: "➕"),
        DailyRewardItem(day: 7, title: "Day 7", stars: 1000, hammers: 3, colorBombs: 3, extraMoves: 0, icon: "🎁")
    ]

    private init() {
        checkRewardAvailability()
    }

    func checkRewardAvailability() {
        let streak = max(1, defaults.integer(forKey: Keys.currentStreak) == 0 ? 1 : defaults.integer(forKey: Keys.currentStreak))
        currentStreak = min(streak, 7)

        guard let lastDate = defaults.object(forKey: Keys.lastClaimDate) as? Date else {
            // First time launching - reward available!
            isRewardAvailable = true
            return
        }

        let calendar = Calendar.current
        if calendar.isDateInToday(lastDate) {
            // Already claimed today
            isRewardAvailable = false
        } else if calendar.isDateInYesterday(lastDate) {
            // Consecutive day login - reward available!
            isRewardAvailable = true
        } else {
            // Missed a day - reset streak to Day 1
            currentStreak = 1
            defaults.set(1, forKey: Keys.currentStreak)
            isRewardAvailable = true
        }
    }

    func claimDailyReward() {
        guard isRewardAvailable else { return }

        let reward = rewardSchedule[(currentStreak - 1) % 7]

        // Grant rewards to PlayerProfile
        PlayerProfile.shared.addStars(reward.stars)
        if reward.hammers > 0 {
            PlayerProfile.shared.hammerCount += reward.hammers
        }
        if reward.colorBombs > 0 {
            PlayerProfile.shared.colorBombCount += reward.colorBombs
        }
        if reward.extraMoves > 0 {
            PlayerProfile.shared.extraMovesCount += reward.extraMoves
        }

        // Persist claim
        defaults.set(Date(), forKey: Keys.lastClaimDate)

        let nextStreak = currentStreak >= 7 ? 1 : currentStreak + 1
        defaults.set(nextStreak, forKey: Keys.currentStreak)
        currentStreak = nextStreak
        isRewardAvailable = false
    }
}
