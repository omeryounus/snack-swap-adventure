import SwiftUI

struct StatsView: View {
    let onBack: () -> Void
    @StateObject private var profile = PlayerProfile.shared
    @State private var nameDraft = ""
    @State private var showNameEditor = false

    private let avatars = ["👾", "🍪", "🍩", "🍬", "🍿", "🍭", "🧁", "⭐", "🌟", "🎮"]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.14, green: 0.10, blue: 0.26),
                    Color(red: 0.30, green: 0.14, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        SoundManager.shared.playUITap()
                        onBack()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("📊 My Stats")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 54)
                }
                .padding()

                ScrollView {
                    VStack(spacing: 18) {
                        profileCard
                        localStatsGrid
                        remoteStatsCard
                        if let err = profile.lastSyncError {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(.orange.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .task {
            nameDraft = profile.displayName
            await profile.refreshRemoteStats()
        }
        .alert("Display Name", isPresented: $showNameEditor) {
            TextField("Name", text: $nameDraft)
            Button("Save") {
                profile.setDisplayName(nameDraft)
                Task { await profile.syncProfileToServer() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This name appears on the global leaderboard.")
        }
    }

    private var profileCard: some View {
        VStack(spacing: 14) {
            Text(profile.avatarEmoji)
                .font(.system(size: 64))

            Text(profile.displayName)
                .font(.title2.bold())
                .foregroundStyle(.white)

            if let rank = profile.remoteRank {
                Text("Global Rank #\(rank)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.yellow)
            }

            HStack(spacing: 16) {
                Text("⭐ \(MetaProgress.shared.stars)")
                Text("🪙 \(MetaProgress.shared.coins)")
            }
            .font(.subheadline.bold())
            .foregroundStyle(.white.opacity(0.9))

            Button {
                SoundManager.shared.playUITap()
                nameDraft = profile.displayName
                showNameEditor = true
            } label: {
                Text("Edit Name")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(avatars, id: \.self) { emoji in
                        Button {
                            SoundManager.shared.playUITap()
                            profile.setAvatar(emoji)
                            Task { await profile.syncProfileToServer() }
                        } label: {
                            Text(emoji)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(
                                    profile.avatarEmoji == emoji
                                        ? Color.pink.opacity(0.35)
                                        : Color.white.opacity(0.08)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            profile.avatarEmoji == emoji ? Color.pink : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var localStatsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Device")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                statTile("High Score", profile.localHighScore.formatted(), "🏆")
                statTile("Total Score", profile.localTotalScore.formatted(), "✨")
                statTile("Wins", "\(profile.localWins)", "✅")
                statTile("Losses", "\(profile.localLosses)", "❌")
                statTile("Win Rate", String(format: "%.1f%%", profile.localWinRate), "📈")
                statTile("Games", "\(profile.localGamesPlayed)", "🎮")
                statTile("Stars", "\(profile.localStars)", "⭐")
                statTile("Max Combo", "\(profile.localMaxCombo)", "🔥")
                statTile("Best Level", "\(profile.localHighestLevel)", "🗺️")
                statTile("Win Streak", "\(profile.localBestStreak)", "💫")
                statTile("Unlocked", "Lv \(profile.maxUnlockedLevel)", "🔓")
                statTile("Current Streak", "\(profile.localCurrentStreak)", "⚡")
            }
        }
    }

    private var remoteStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Online (Vercel)")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if profile.isSyncing {
                    ProgressView().tint(.white)
                } else {
                    Button {
                        Task { await profile.refreshRemoteStats() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }

            let s = profile.remoteStats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                statTile("Cloud High", s.highScore.formatted(), "☁️")
                statTile("Cloud Total", s.totalScore.formatted(), "☁️")
                statTile("Cloud Wins", "\(s.wins)", "☁️")
                statTile("Cloud Stars", "\(s.totalStars)", "☁️")
                statTile("Cloud Combo", "\(s.maxCombo)", "☁️")
                statTile("Cloud Level", "\(s.highestLevel)", "☁️")
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func statTile(_ title: String, _ value: String, _ emoji: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(emoji) \(title)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    StatsView(onBack: {})
}
