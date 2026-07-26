import SwiftUI

/// Modal displaying 7-day reward streak calendar and claim button.
struct DailyRewardModalView: View {
    @Environment(\.dismiss) private var dismiss
    var onDismiss: (() -> Void)? = nil

    @StateObject private var rewardsManager = DailyRewardsManager.shared
    @State private var claimedRewardMessage: String?

    private func handleDismiss() {
        SoundManager.shared.playUITap()
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    handleDismiss()
                }

            VStack(spacing: 20) {
                headerView
                subtitleView
                rewardGrid
                rewardToast
                claimButton
            }
            .padding(24)
            .background(modalBackground)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Header
    private var headerView: some View {
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

            Button(action: { handleDismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var subtitleView: some View {
        Text("Log in every day to claim bonus Stars & Boosters!")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.8))
            .multilineTextAlignment(.center)
    }

    // MARK: - Reward Grid
    private var rewardGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(rewardsManager.rewardSchedule) { item in
                DayCardView(item: item, currentStreak: rewardsManager.currentStreak, isAvailable: rewardsManager.isRewardAvailable)
            }
        }
    }

    // MARK: - Toast
    @ViewBuilder
    private var rewardToast: some View {
        if let msg = claimedRewardMessage {
            Text(msg)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
                .padding(.vertical, 6)
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Claim Button
    private var claimButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                let reward = rewardsManager.rewardSchedule[(rewardsManager.currentStreak - 1) % 7]
                rewardsManager.claimDailyReward()
                claimedRewardMessage = "Claimed \(reward.title): +\(reward.stars) ⭐!"
            }
        }) {
            Text(rewardsManager.isRewardAvailable ? "CLAIM REWARD! 🎁" : "GREAT JOB! ⏳")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(rewardsManager.isRewardAvailable ? .black : .white.opacity(0.6))
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(claimGradient)
                .clipShape(Capsule())
        }
        .disabled(!rewardsManager.isRewardAvailable)
    }

    private var claimGradient: LinearGradient {
        if rewardsManager.isRewardAvailable {
            return LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
        } else {
            return LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
        }
    }

    private var modalBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(LinearGradient(colors: [Color(hex: "2D1854"), Color(hex: "180C34")], startPoint: .top, endPoint: .bottom))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(LinearGradient(colors: [.purple.opacity(0.6), .yellow.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
            )
    }
}

private struct DayCardView: View {
    let item: DailyRewardItem
    let currentStreak: Int
    let isAvailable: Bool

    var isCurrentDay: Bool { item.day == currentStreak }
    var isPastDay: Bool { item.day < currentStreak }

    var body: some View {
        VStack(spacing: 6) {
            Text(item.title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
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
            } else if isCurrentDay && isAvailable {
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
