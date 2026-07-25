import SwiftUI

struct DailyRewardView: View {
    @ObservedObject private var manager = DailyRewardManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var claimedReward: DailyReward? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: 22) {
                // Header
                VStack(spacing: 6) {
                    Text("🎁 DAILY REWARDS")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(SSATheme.candyYellow)

                    Text("Log in every day for bonus stars & free boosters!")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(SSATheme.textSecondary)
                }

                // 7-day grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(manager.rewards) { reward in
                        let isCurrent = (reward.day - 1) == manager.currentDayIndex
                        let isClaimed = (reward.day - 1) < manager.currentDayIndex && !manager.canClaimToday

                        VStack(spacing: 8) {
                            Text(reward.title)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(isCurrent ? SSATheme.candyYellow : .white.opacity(0.7))

                            Image(systemName: reward.iconName)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(isCurrent ? SSATheme.candyPink : SSATheme.candyYellow)

                            Text("+\(reward.stars) ⭐")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            if isClaimed {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(SSATheme.candyGreen)
                            }
                        }
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(isCurrent ? SSATheme.candyPurple.opacity(0.8) : Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(isCurrent ? SSATheme.candyYellow : Color.white.opacity(0.15), lineWidth: isCurrent ? 2 : 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 8)

                // Claim / Close CTA
                if manager.canClaimToday {
                    SSAPrimaryButton(
                        title: "CLAIM TODAY'S REWARD!",
                        icon: "gift.fill"
                    ) {
                        claimedReward = manager.claimToday()
                    }
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Text("COME BACK TOMORROW")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.white.opacity(0.2)))
                    }
                }
            }
            .padding(24)
            .background(
                SSAGlassCard(padding: 24, cornerRadius: 28, borderColor: SSATheme.candyYellow) { EmptyView() }
            )
            .padding(.horizontal, 20)
        }
    }
}
