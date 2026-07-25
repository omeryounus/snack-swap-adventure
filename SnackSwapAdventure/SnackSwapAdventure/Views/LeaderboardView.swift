import SwiftUI

/// Screen 04: Ranks / Leaderboard — High scores tabs, top 3 podium, and sticky YOU row.
struct LeaderboardView: View {
    let onBack: () -> Void

    @StateObject private var profile = PlayerProfile.shared
    @StateObject private var meta = MetaProgress.shared
    @State private var entries: [LeaderboardEntryDTO] = []
    @State private var global: GlobalStatsDTO?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab: Int = 0 // 0 = Global, 1 = Friends, 2 = Weekly

    var body: some View {
        ZStack(alignment: .top) {
            WorldBackgroundPlate(themeColor: SSATheme.candyYellow)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        SoundManager.shared.playUITap()
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("RANKS")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Global Leaderboard")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(SSATheme.candyYellow)
                    }

                    Spacer()

                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 12)

                // Tab selector (Global, Friends, Weekly)
                HStack(spacing: 8) {
                    TabChip(title: "Global", isSelected: selectedTab == 0) { selectedTab = 0 }
                    TabChip(title: "Friends", isSelected: selectedTab == 1) { selectedTab = 1 }
                    TabChip(title: "Weekly", isSelected: selectedTab == 2) { selectedTab = 2 }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // User's Own Rank Card
                        SSAGlassCard(padding: 14) {
                            HStack(spacing: 14) {
                                Text("#\(profile.lastSubmittedRank ?? 9)")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundStyle(SSATheme.candyYellow)

                                Text(profile.avatarEmoji)
                                    .font(.title2)
                                    .padding(6)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(profile.displayName)
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)

                                        Text("YOU")
                                            .font(.system(size: 10, weight: .black))
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(SSATheme.candyYellow))
                                    }

                                    Text("High Score: \(profile.localHighScore) pts")
                                        .font(.caption.bold())
                                        .foregroundStyle(SSATheme.textSecondary)
                                }

                                Spacer()
                            }
                        }

                        // Top 3 Podium Cards
                        HStack(alignment: .bottom, spacing: 10) {
                            PodiumCard(rank: 2, name: "SnackPro", score: 14200, emoji: "🦊", color: Color.gray)
                            PodiumCard(rank: 1, name: "Omer", score: 18450, emoji: "👑", color: SSATheme.candyYellow)
                            PodiumCard(rank: 3, name: "CandyQueen", score: 12100, emoji: "🦄", color: SSATheme.candyOrange)
                        }
                        .padding(.vertical, 8)

                        // Leaderboard Rows
                        VStack(spacing: 10) {
                            LeaderRow(rank: 4, name: "PixelMonster", score: 11400, emoji: "👾")
                            LeaderRow(rank: 5, name: "DonutMaster", score: 10850, emoji: "🍩")
                            LeaderRow(rank: 6, name: "PopcornKing", score: 9950, emoji: "🍿")
                            LeaderRow(rank: 7, name: "SweetTooth", score: 9200, emoji: "🧁")
                            LeaderRow(rank: 8, name: "LollipopLover", score: 8600, emoji: "🍭")
                            LeaderRow(rank: 9, name: profile.displayName, score: max(profile.localHighScore, 3845), emoji: "👻", isSelf: true)
                            LeaderRow(rank: 10, name: "CookieNinja", score: 3200, emoji: "🍪")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

private struct TabChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            SoundManager.shared.playUITap()
            action()
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : SSATheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? SSATheme.candyPink : Color.white.opacity(0.08))
                )
        }
    }
}

private struct PodiumCard: View {
    let rank: Int
    let name: String
    let score: Int
    let emoji: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: rank == 1 ? 32 : 26))

            Text(name)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("\(score)")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(color)

            Text("#\(rank)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 8).fill(color))
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.5), lineWidth: 1.5))
        )
        .offset(y: rank == 1 ? -10 : 0)
    }
}

private struct LeaderRow: View {
    let rank: Int
    let name: String
    let score: Int
    let emoji: String
    var isSelf: Bool = false

    var body: some View {
        SSAGlassCard(padding: 12, cornerRadius: 14, borderColor: isSelf ? SSATheme.candyYellow : Color.white.opacity(0.12)) {
            HStack(spacing: 12) {
                Text("#\(rank)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelf ? SSATheme.candyYellow : SSATheme.textSecondary)
                    .frame(width: 30, alignment: .leading)

                Text(emoji)
                    .font(.title3)

                Text(name)
                    .font(.system(size: 15, weight: isSelf ? .black : .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(score) pts")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(SSATheme.candyYellow)
            }
        }
    }
}
