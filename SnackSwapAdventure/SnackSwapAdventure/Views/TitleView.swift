import SwiftUI

/// Screen 01: Home / Main Menu — Profile (Omer), floating ghost mascot, title, Play CTA, glass World Map chip, nav cards, Settings.
struct TitleView: View {
    let onPlay: () -> Void
    let onWorldMap: () -> Void
    let onLeaderboard: () -> Void
    let onStats: () -> Void
    var onMonsters: () -> Void = {}
    var onShop: () -> Void = {}
    var onInvite: () -> Void = {}
    var onSettings: () -> Void = {}

    @StateObject private var profile = PlayerProfile.shared
    @StateObject private var meta = MetaProgress.shared
    @StateObject private var rewardsManager = DailyRewardsManager.shared
    @State private var showDailyRewardsModal = false

    var currentLevelConfig: LevelConfig {
        LevelConfig.level(min(profile.maxUnlockedLevel, LevelConfig.totalLevels))
    }

    var body: some View {
        ZStack(alignment: .top) {
            WorldBackgroundPlate(themeColor: SSATheme.candyPurple)

            VStack(spacing: 0) {
                // Top Header Bar: Profile Chip + Daily Rewards + Settings Gear
                HStack {
                    // Player Profile Chip
                    Button {
                        SoundManager.shared.playUITap()
                        onStats()
                    } label: {
                        HStack(spacing: 8) {
                            Text(profile.avatarEmoji)
                                .font(.system(size: 22))

                            VStack(alignment: .leading, spacing: 1) {
                                Text(profile.displayName)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text("\(profile.stars) ⭐")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(SSATheme.candyYellow)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }

                    Spacer()

                    // Daily Rewards Button with Notification Badge
                    Button {
                        SoundManager.shared.playUITap()
                        showDailyRewardsModal = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Text("🎁")
                                .font(.system(size: 22))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))

                            if rewardsManager.isRewardAvailable {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 12, height: 12)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }

                    // Settings Button
                    Button {
                        SoundManager.shared.playUITap()
                        onSettings()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Spacer(minLength: 16)

                        // Hero Ghost Mascot Section
                        TitleHeroSnacklingSection(playerName: profile.displayName)

                        // Title Block & Refined Tagline
                        VStack(spacing: 6) {
                            Text("SNACK SWAP")
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .foregroundStyle(SSATheme.goldGradient)
                                .shadow(color: SSATheme.candyPink.opacity(0.4), radius: 8, x: 0, y: 3)

                            Text("ADVENTURE")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .tracking(4)
                                .shadow(color: .black.opacity(0.55), radius: 4, y: 2)

                            Text("Match snacks. Feed your Snackling. Beat the clock.")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(SSATheme.textSecondary)
                        }

                        // Primary Play CTA + Glass World Map Chip
                        VStack(spacing: 12) {
                            SSAPrimaryButton(
                                title: "PLAY",
                                icon: "play.fill",
                                gradient: SSATheme.primaryGradient
                            ) {
                                onPlay()
                            }

                            Text(profile.maxUnlockedLevel > 1 ? "Continue Level \(currentLevelConfig.levelNumber) • \(currentLevelConfig.worldName)" : "Start Level 1 • \(currentLevelConfig.worldName)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(SSATheme.candyYellow)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                                .padding(.horizontal, 4)

                            Button {
                                SoundManager.shared.playUITap()
                                onWorldMap()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("WORLD MAP")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 4)

                        // Bottom Navigation Cards Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            NavCard(title: "Ranks", subtitle: "Global Top 10", icon: "trophy.fill", color: SSATheme.candyYellow) {
                                onLeaderboard()
                            }

                            NavCard(title: "Snackling Dex", subtitle: "Feed Monsters", icon: "pawprint.fill", color: SSATheme.candyPink) {
                                onMonsters()
                            }

                            NavCard(title: "Stats", subtitle: "Your Progress", icon: "chart.bar.fill", color: SSATheme.candyCyan) {
                                onStats()
                            }

                            NavCard(title: "Shop", subtitle: "Boosters & Stars", icon: "bag.fill", color: SSATheme.candyGreen) {
                                onShop()
                            }
                        }
                        .padding(.top, 6)

                        // Invite Friends Banner
                        Button {
                            SoundManager.shared.playUITap()
                            onInvite()
                        } label: {
                            SSAGlassCard(padding: 14, cornerRadius: 18) {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.2.fill")
                                        .font(.title2)
                                        .foregroundStyle(SSATheme.candyPink)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Invite Friends")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)

                                        Text("Earn +50 free stars for each friend!")
                                            .font(.caption)
                                            .foregroundStyle(SSATheme.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                        .foregroundStyle(SSATheme.textMuted)
                                }
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 20)
                }
            }

            if showDailyRewardsModal {
                DailyRewardModalView(onDismiss: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showDailyRewardsModal = false
                    }
                })
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

private struct NavCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            SoundManager.shared.playUITap()
            action()
        } label: {
            SSAGlassCard(padding: 14, cornerRadius: 18, borderColor: Color.white.opacity(0.12)) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(color)
                        .frame(width: 38, height: 38)
                        .background(color.opacity(0.18))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(SSATheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}
