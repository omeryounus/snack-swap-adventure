import SwiftUI

/// Screen 01: Home / Main Menu — adapts to iPhone SE through iPad Pro, portrait and landscape.
struct TitleView: View {
    let onPlay: () -> Void
    let onWorldMap: () -> Void
    let onLeaderboard: () -> Void
    let onStats: () -> Void
    var onMonsters: () -> Void = {}
    var onShop: () -> Void = {}
    var onInvite: () -> Void = {}
    var onSettings: () -> Void = {}

    @Environment(\.adaptiveLayout) private var layout
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
                topBar
                    .padding(.horizontal, layout.screenPadding)
                    .padding(.top, layout.topBarTopPadding)
                    .padding(.bottom, layout.topBarBottomPadding)

                if layout.titleUsesSplitLayout {
                    landscapeBody
                } else {
                    portraitBody
                }
            }
            .adaptiveSafeAreaPadding(layout)

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

    /// Single row when there is width for it; two rows below ~400pt, where the
    /// pill, the profile chip and both controls cannot share a line without
    /// squeezing the player's name down to nothing.
    private var topBar: some View {
        Group {
            if layout.topBarUsesTwoRows {
                VStack(alignment: .leading, spacing: layout.topBarRowSpacing) {
                    HStack(spacing: layout.topBarSpacing) {
                        profileChip
                        Spacer(minLength: 8)
                        dailyRewardButton
                        settingsButton
                    }
                    HStack(spacing: layout.topBarSpacing) {
                        LivesPill()
                        Spacer(minLength: 0)
                    }
                }
            } else {
                HStack(spacing: layout.topBarSpacing) {
                    LivesPill()
                    profileChip
                    Spacer(minLength: 8)
                    dailyRewardButton
                    settingsButton
                }
            }
        }
    }

    private var profileChip: some View {
        Button {
            SoundManager.shared.playUITap()
            onStats()
        } label: {
            HStack(spacing: 10) {
                Text(profile.avatarEmoji)
                    .font(.system(size: layout.topBarAvatarFont))

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.displayName)
                        .font(.system(size: layout.topBarNameFont, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("\(profile.stars) ⭐")
                        .font(.system(size: layout.topBarDetailFont, weight: .bold, design: .rounded))
                        .foregroundStyle(SSATheme.candyYellow)
                        .lineLimit(1)
                }
                .layoutPriority(1)
            }
            .padding(.horizontal, layout.topBarChipPaddingH)
            .padding(.vertical, layout.topBarChipPaddingV)
            .background(Color.white.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
        }
    }

    private var dailyRewardButton: some View {
        Button {
            SoundManager.shared.playUITap()
            showDailyRewardsModal = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Text("🎁")
                    .font(.system(size: layout.isPad ? 28 : 24))
                    .frame(width: layout.topBarControlSize, height: layout.topBarControlSize)
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
        .accessibilityLabel("Daily Rewards")
    }

    private var settingsButton: some View {
        Button {
            SoundManager.shared.playUITap()
            onSettings()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: layout.isPad ? 22 : 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: layout.topBarControlSize, height: layout.topBarControlSize)
                .background(Color.white.opacity(0.12))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
        }
        .accessibilityLabel("Settings")
    }

    private var portraitBody: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: layout.sectionSpacing) {
                Spacer(minLength: layout.isCompactHeight ? 8 : 16)
                heroBlock
                playBlock
                navGrid
                inviteBanner
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: layout.contentMaxWidth == .infinity ? .infinity : layout.contentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, layout.screenPadding)
            .padding(.bottom, layout.scrollBottomPadding)
        }
    }

    private var landscapeBody: some View {
        HStack(alignment: .center, spacing: layout.isPad ? 36 : 24) {
            ScrollView(showsIndicators: false) {
                heroBlock
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    playBlock
                    navGrid
                    inviteBanner
                }
                .padding(.vertical, 8)
                .padding(.trailing, 4)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, layout.screenPadding)
        .padding(.bottom, 8)
    }

    private var heroBlock: some View {
        VStack(spacing: layout.isCompactHeight ? 8 : 14) {
            TitleHeroSnacklingSection(
                playerName: profile.displayName,
                mascotSize: layout.titleMascotSize
            )

            VStack(spacing: 6) {
                Text("SNACK SWAP")
                    .font(.system(size: layout.titleHeroFont, weight: .black, design: .rounded))
                    .foregroundStyle(SSATheme.goldGradient)
                    .shadow(color: SSATheme.candyPink.opacity(0.4), radius: 8, x: 0, y: 3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("ADVENTURE")
                    .font(.system(size: layout.titleSecondaryFont, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(4)
                    .shadow(color: .black.opacity(0.55), radius: 4, y: 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("Match snacks. Feed your Snackling. Beat the clock.")
                    .font(.system(size: layout.captionFont, weight: .semibold, design: .rounded))
                    .foregroundStyle(SSATheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    private var playBlock: some View {
        VStack(spacing: 12) {
            SSAPrimaryButton(
                title: "PLAY",
                icon: "play.fill",
                gradient: SSATheme.primaryGradient
            ) {
                onPlay()
            }
            .frame(maxWidth: layout.titleButtonMaxWidth)

            Text(profile.maxUnlockedLevel > 1
                 ? "Continue Level \(currentLevelConfig.levelNumber) • \(currentLevelConfig.worldName)"
                 : "Start Level 1 • \(currentLevelConfig.worldName)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(SSATheme.candyYellow)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
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
        .padding(.horizontal, 6)
        .padding(.top, 2)
    }

    private var navGrid: some View {
        // Adaptive, not a fixed column count: in landscape this grid sits in a
        // half-width column, where 4 fixed columns squeezed each card to ~97pt
        // and clipped "Ranks" down to "R".
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
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
        .padding(.top, 4)
    }

    private var inviteBanner: some View {
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
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(SSATheme.textMuted)
                }
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
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(subtitle)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(SSATheme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}
