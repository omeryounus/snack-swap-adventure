import SwiftUI

/// Modal displaying 7-day reward streak calendar and claim button.
struct DailyRewardModalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var rewardsManager = DailyRewardsManager.shared
    @State private var claimedRewardMessage: String?

    var body: some View {
        ZStack {
            // Dark Backdrop
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack {
                    Spacer()
                    Text("DAILY REWARDS 🎁")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                Text("Log in every day to claim bonus Stars & Boosters!")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                // 7-Day Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 12) {
                    ForEach(rewardsManager.rewardSchedule) { item in
                        dayCard(for: item)
                    }
                }

                if let msg = claimedRewardMessage {
                    Text(msg)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                        .padding(.vertical, 6)
                        .transition(.scale.combined(with: .opacity))
                }

                // Claim Button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        let reward = rewardsManager.rewardSchedule[(rewardsManager.currentStreak - 1) % 7]
                        rewardsManager.claimDailyReward()
                        claimedRewardMessage = "Claimed \(reward.title): +\(reward.stars) ⭐!"
                    }
                }) {
                    Text(rewardsManager.isRewardAvailable ? "CLAIM REWARD! 🎁" : "COME BACK TOMORROW! ⏳")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(rewardsManager.isRewardAvailable ? .black : .white.opacity(0.6))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            rewardsManager.isRewardAvailable ?
                                LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom) :
                                LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(Capsule())
                        .shadow(color: rewardsManager.isRewardAvailable ? .orange.opacity(0.5) : .clear, radius: 8, y: 4)
                }
                .disabled(!rewardsManager.isRewardAvailable)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(colors: [Color(hex: "2D1854"), Color(hex: "180C34")], startPoint: .top, endPoint: .bottom))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(LinearGradient(colors: [.purple.opacity(0.6), .yellow.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                    )
            )
            .padding(.horizontal, 20)
        }
    }

    private func dayCard(for item: DailyRewardItem) -> some View {
        let isCurrentDay = item.day == rewardsManager.currentStreak
        let isPastDay = item.day < rewardsManager.currentStreak

        return VStack(spacing: 6) {
            Text(item.title)
                .font(.system(size: 11, weight: .extrabold, design: .rounded))
                .foregroundStyle(isCurrentDay ? .yellow : (isPastDay ? .green : .white.opacity(0.7)))

            Text(item.icon)
                .font(.system(size: 28))

            Text("+\(item.stars) ⭐")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if isPastDay {
                Text("CLAIMED ✅")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(.green)
            } else if isCurrentDay && rewardsManager.isRewardAvailable {
                Text("READY! ✨")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCurrentDay ? Color.yellow.opacity(0.15) : (isPastDay ? Color.green.opacity(0.1) : Color.white.opacity(0.05)))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isCurrentDay ? Color.yellow : (isPastDay ? Color.green.opacity(0.4) : Color.white.opacity(0.1)), lineWidth: isCurrentDay ? 2 : 1)
                )
        )
    }
}
