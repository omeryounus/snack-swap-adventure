import SwiftUI

struct LeaderboardView: View {
    let onBack: () -> Void
    @StateObject private var profile = PlayerProfile.shared
    @StateObject private var meta = MetaProgress.shared

    @State private var sort: LeaderboardSort = .highScore
    @State private var entries: [LeaderboardEntryDTO] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var global: GlobalStatsDTO?
    @State private var appear = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.10, blue: 0.24),
                    Color(red: 0.28, green: 0.12, blue: 0.32)
                ],
                startPoint: .top,
                endPoint: .bottom
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
                    Text("🏆 Leaderboard")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    if isLoading {
                        ProgressView().tint(.white).frame(width: 54)
                    } else {
                        Color.clear.frame(width: 54)
                    }
                }
                .padding()

                // You card
                playerCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                if let global {
                    HStack(spacing: 10) {
                        miniStat("Players", "\(global.totalPlayers)")
                        miniStat("Games", "\(global.totalGamesPlayed)")
                        miniStat("Top", global.topScore.formatted())
                        miniStat("Champ", global.topPlayerName ?? "—")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(LeaderboardSort.allCases) { option in
                            Button {
                                SoundManager.shared.playUITap()
                                sort = option
                                Task { await loadLeaderboardOnly() }
                            } label: {
                                Text(option.title)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        sort == option
                                            ? AnyShapeStyle(
                                                LinearGradient(
                                                    colors: [.pink, .orange],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            : AnyShapeStyle(Color.white.opacity(0.1))
                                    )
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 10)

                if isLoading && entries.isEmpty {
                    Spacer()
                    ProgressView().tint(.white)
                    Text("Loading leaderboard…")
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 12)
                    Spacer()
                } else if let errorMessage, entries.isEmpty {
                    Spacer()
                    Text("⚠️").font(.system(size: 44))
                    Text(errorMessage)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") { Task { await load() } }
                        .buttonStyle(PrimaryChipStyle())
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            // Podium for top 3
                            if entries.count >= 3 && sort == .highScore {
                                podium
                                    .padding(.bottom, 6)
                            }
                            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                                row(entry)
                                    .opacity(appear ? 1 : 0)
                                    .offset(y: appear ? 0 : 12)
                                    .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(Double(index) * 0.03), value: appear)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)
                    }
                    .refreshable { await load() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .task {
            await load()
            appear = true
        }
    }

    private var playerCard: some View {
        HStack(spacing: 12) {
            Text(profile.avatarEmoji)
                .font(.system(size: 36))
                .frame(width: 52, height: 52)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Text("⭐ \(meta.stars)   🪙 \(meta.coins)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            if let rank = profile.remoteRank {
                VStack(spacing: 2) {
                    Text("#\(rank)")
                        .font(.title3.bold())
                        .foregroundStyle(.yellow)
                    Text("YOU")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.6))
                }
            } else {
                Text("Unranked")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(14)
        .background(
            LinearGradient(colors: [Color.pink.opacity(0.25), Color.purple.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.pink.opacity(0.45), lineWidth: 1)
        )
    }

    private var podium: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if entries.count > 1 {
                podiumCard(entries[1], height: 90, place: 2)
            }
            if !entries.isEmpty {
                podiumCard(entries[0], height: 118, place: 1)
            }
            if entries.count > 2 {
                podiumCard(entries[2], height: 78, place: 3)
            }
        }
        .padding(.horizontal, 4)
    }

    private func podiumCard(_ e: LeaderboardEntryDTO, height: CGFloat, place: Int) -> some View {
        VStack(spacing: 6) {
            Text(place == 1 ? "🥇" : place == 2 ? "🥈" : "🥉")
                .font(.title2)
            Text(e.avatarEmoji).font(.title)
            Text(e.displayName)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(e.highScore.formatted())
                .font(.caption2.bold())
                .foregroundStyle(.yellow)
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: place == 1
                            ? [.yellow.opacity(0.5), .orange.opacity(0.35)]
                            : [.white.opacity(0.15), .white.opacity(0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: height)
        }
        .frame(maxWidth: .infinity)
    }

    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func row(_ entry: LeaderboardEntryDTO) -> some View {
        let isMe = entry.playerId == profile.playerId
        return HStack(spacing: 12) {
            Text(rankLabel(entry.rank))
                .font(.headline.bold())
                .foregroundStyle(entry.rank <= 3 ? Color.yellow : Color.white.opacity(0.7))
                .frame(width: 36)

            Text(entry.avatarEmoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if isMe {
                        Text("YOU")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.pink.opacity(0.8))
                            .clipShape(Capsule())
                    }
                }
                Text("Lv \(entry.highestLevel) · ★\(entry.totalStars) · \(entry.wins) wins · \(String(format: "%.0f", entry.winRate))%")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(value(for: entry).formatted())
                    .font(.headline.bold())
                    .foregroundStyle(Color(red: 1, green: 0.85, blue: 0.4))
                Text(sort.title)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isMe ? Color.pink.opacity(0.18) : Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isMe ? Color.pink.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func value(for entry: LeaderboardEntryDTO) -> Int {
        switch sort {
        case .highScore: return entry.highScore
        case .totalScore: return entry.totalScore
        case .highestLevel: return entry.highestLevel
        case .totalStars: return entry.totalStars
        case .wins: return entry.wins
        case .maxCombo: return entry.maxCombo
        }
    }

    private func rankLabel(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let board = APIClient.shared.leaderboard(sort: sort, limit: 50)
            async let stats = APIClient.shared.globalStats()
            entries = try await board
            global = try await stats.global
            await profile.refreshRemoteStats()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadLeaderboardOnly() async {
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await APIClient.shared.leaderboard(sort: sort, limit: 50)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct PrimaryChipStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(LinearGradient(colors: [.pink, .orange], startPoint: .leading, endPoint: .trailing))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

#Preview {
    LeaderboardView(onBack: {})
}
