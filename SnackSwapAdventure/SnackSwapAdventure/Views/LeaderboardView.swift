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
    @StateObject private var gameCenter = GameCenterManager.shared
    @State private var friendsBoard: GameCenterManager.FriendsBoard = .highScore
    @State private var challengeFailed = false

    @Environment(\.adaptiveLayout) private var layout

    var body: some View {
        ScreenScaffold(
            title: "RANKS",
            subtitle: "Global Leaderboard",
            accent: SSATheme.candyYellow,
            themeColor: SSATheme.candyYellow,
            onBack: onBack
        ) {
                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            TabChip(title: "Global", isSelected: selectedTab == 0) { selectedTab = 0 }
                            TabChip(title: "Friends", isSelected: selectedTab == 1) { selectedTab = 1 }
                            TabChip(title: "Weekly", isSelected: selectedTab == 2) { selectedTab = 2 }
                        }
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

                        if selectedTab == 1 {
                            friendsSection
                        } else {
                            placeholderBoard
                        }
                    }
        }
        .task(id: selectedTab) {
            guard selectedTab == 1 else { return }
            await gameCenter.loadFriendsLeaderboard(friendsBoard)
        }
        .task(id: friendsBoard) {
            guard selectedTab == 1 else { return }
            await gameCenter.loadFriendsLeaderboard(friendsBoard)
        }
    }

    // MARK: - Friends (real data, straight from Game Center)

    private var friendsSection: some View {
        VStack(spacing: 14) {
            Picker("Board", selection: $friendsBoard) {
                ForEach(GameCenterManager.FriendsBoard.allCases) { board in
                    Text(board.title).tag(board)
                }
            }
            .pickerStyle(.segmented)

            if gameCenter.isLoadingFriends {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if let message = gameCenter.friendsMessage {
                VStack(spacing: 12) {
                    Text("👋")
                        .font(.system(size: 40))
                    Text(message)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(SSATheme.textSecondary)
                        .multilineTextAlignment(.center)

                    if !gameCenter.isAuthenticated {
                        Button("Open Game Center") { gameCenter.showDashboard() }
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(SSATheme.candyYellow)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 10) {
                    ForEach(gameCenter.friendEntries) { entry in
                        LeaderRow(
                            rank: entry.rank,
                            name: entry.displayName,
                            score: entry.score,
                            emoji: entry.isLocalPlayer ? profile.avatarEmoji : "🎮",
                            isSelf: entry.isLocalPlayer
                        )
                    }
                }

                Button {
                    SoundManager.shared.playUITap()
                    Task {
                        let shown = await gameCenter.presentChallenge(
                            for: friendsBoard,
                            message: "Think you can beat my \(friendsBoard.title.lowercased()) in Snack Swap Adventure? 🍪"
                        )
                        if !shown { challengeFailed = true }
                    }
                } label: {
                    Label("Challenge a Friend", systemImage: "flag.checkered.2.crossed")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SSATheme.primaryGradient)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .alert("Nothing to Challenge With", isPresented: $challengeFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Play a level first so there's a score for your friends to beat.")
        }
    }

    /// Global and Weekly are still illustrative placeholders — they need the
    /// backend leaderboard, which is parked. Only Friends is live.
    private var placeholderBoard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: layout.isPad ? 16 : 8) {
                PodiumCard(rank: 2, name: "SnackPro", score: 14200, emoji: "🦊", color: Color.gray)
                PodiumCard(rank: 1, name: "Omer", score: 18450, emoji: "👑", color: SSATheme.candyYellow)
                PodiumCard(rank: 3, name: "CandyQueen", score: 12100, emoji: "🦄", color: SSATheme.candyOrange)
            }
            .padding(.vertical, 8)

            VStack(spacing: 10) {
                LeaderRow(rank: 4, name: "PixelMonster", score: 11400, emoji: "👾")
                LeaderRow(rank: 5, name: "DonutMaster", score: 10850, emoji: "🍩")
                LeaderRow(rank: 6, name: "PopcornKing", score: 9950, emoji: "🍿")
                LeaderRow(rank: 7, name: "SweetTooth", score: 9200, emoji: "🧁")
                LeaderRow(rank: 8, name: "LollipopLover", score: 8600, emoji: "🍭")
                LeaderRow(rank: 9, name: profile.displayName, score: max(profile.localHighScore, 3845), emoji: "👻", isSelf: true)
                LeaderRow(rank: 10, name: "CookieNinja", score: 3200, emoji: "🍪")
            }

            Text("Tap **Friends** for live Game Center rankings.")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SSATheme.textMuted)
                .padding(.top, 4)
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
