import SwiftUI

/// Screen 12: Settings screen with audio, haptics, profile editor, Game Center link, and Restore Purchases.
struct SettingsView: View {
    let onBack: () -> Void

    @StateObject private var profile = PlayerProfile.shared
    @StateObject private var meta = MetaProgress.shared
    @StateObject private var gameCenter = GameCenterManager.shared

    @State private var editedName: String = ""
    @State private var hapticsEnabled: Bool = true
    @State private var showSavedToast: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            ScreenScaffold(
                title: "Settings",
                themeColor: SSATheme.candyPurple,
                onBack: onBack
            ) {
                    VStack(spacing: 20) {
                        // Profile Section
                        SSAGlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Player Profile", systemImage: "person.crop.circle.fill")
                                    .font(.headline.bold())
                                    .foregroundStyle(SSATheme.candyYellow)

                                HStack(spacing: 12) {
                                    Text(profile.avatarEmoji)
                                        .font(.system(size: 36))
                                        .padding(8)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        TextField("Player Name", text: $editedName)
                                            .font(.title3.bold())
                                            .foregroundStyle(.white)
                                            .textFieldStyle(PlainTextFieldStyle())

                                        Text("User ID: \(profile.playerId.prefix(8))...")
                                            .font(.caption)
                                            .foregroundStyle(SSATheme.textMuted)
                                    }

                                    Spacer()

                                    Button {
                                        SoundManager.shared.playUITap()
                                        profile.setDisplayName(editedName)
                                        withAnimation { showSavedToast = true }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            withAnimation { showSavedToast = false }
                                        }
                                    } label: {
                                        Text("Save")
                                            .font(.subheadline.bold())
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(SSATheme.primaryGradient)
                                            .foregroundStyle(.white)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Game Center Integration Card
                        SSAGlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Apple Game Center", systemImage: "trophy.fill")
                                    .font(.headline.bold())
                                    .foregroundStyle(SSATheme.candyYellow)

                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(gameCenter.isAuthenticated ? "Connected as \(gameCenter.localPlayerName)" : "Game Center Sign In")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)

                                        Text("Global Leaderboards & Achievements")
                                            .font(.caption)
                                            .foregroundStyle(SSATheme.textSecondary)
                                    }

                                    Spacer()

                                    Button {
                                        SoundManager.shared.playUITap()
                                        gameCenter.showDashboard()
                                    } label: {
                                        Text("Open 🏆")
                                            .font(.subheadline.bold())
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(SSATheme.goldGradient)
                                            .foregroundStyle(.black)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Audio Settings Section
                        SSAGlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Label("Audio & Sound", systemImage: "speaker.wave.2.fill")
                                    .font(.headline.bold())
                                    .foregroundStyle(SSATheme.candyCyan)

                                ToggleRow(
                                    title: "Music Loop",
                                    icon: "music.note",
                                    isOn: Binding(
                                        get: { meta.musicEnabled },
                                        set: { newValue in
                                            meta.setMusicEnabled(newValue)
                                            if newValue { MusicPlayer.shared.play() } else { MusicPlayer.shared.stop() }
                                        }
                                    )
                                )

                                Divider().background(Color.white.opacity(0.1))

                                ToggleRow(
                                    title: "Sound Effects",
                                    icon: "speaker.wave.2",
                                    isOn: Binding(
                                        get: { meta.soundEnabled },
                                        set: { newValue in
                                            meta.setSoundEnabled(newValue)
                                            SoundManager.shared.setEnabled(newValue)
                                        }
                                    )
                                )

                                Divider().background(Color.white.opacity(0.1))

                                ToggleRow(
                                    title: "Haptic Feedback",
                                    icon: "iphone.radiowaves.left.and.right",
                                    isOn: $hapticsEnabled
                                )
                            }
                        }

                        // Game Info & Support Section
                        SSAGlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Label("Game & Support", systemImage: "gearshape.fill")
                                    .font(.headline.bold())
                                    .foregroundStyle(SSATheme.candyGreen)

                                SettingsLinkRow(title: "Restore Purchases", icon: "arrow.triangle.2.circlepath") {
                                    Task { await StoreManager.shared.restorePurchases() }
                                }

                                Divider().background(Color.white.opacity(0.1))

                                SettingsLinkRow(title: "Privacy Policy", icon: "lock.shield.fill") {
                                    if let url = URL(string: "https://apple.com") {
                                        UIApplication.shared.open(url)
                                    }
                                }

                                Divider().background(Color.white.opacity(0.1))

                                SettingsLinkRow(title: "Terms of Service", icon: "doc.text.fill") {
                                    if let url = URL(string: "https://apple.com") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        }

                        // App Version Footer
                        VStack(spacing: 4) {
                            Text("Snack Swap Adventure v2.0.0")
                                .font(.caption.bold())
                                .foregroundStyle(SSATheme.textSecondary)
                            Text("Game Center & iCloud Connected • All Rights Reserved")
                                .font(.caption2)
                                .foregroundStyle(SSATheme.textMuted)
                        }
                        .padding(.top, 8)
                    }
            }

            // Toast overlay
            if showSavedToast {
                VStack {
                    Spacer()
                    Text("Profile Name Saved!")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(SSATheme.candyGreen))
                        .shadow(radius: 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            editedName = profile.displayName
        }
    }
}

private struct ToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SSATheme.textSecondary)
                .frame(width: 24)

            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(SSATheme.candyPink)
        }
    }
}

private struct SettingsLinkRow: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button {
            SoundManager.shared.playUITap()
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SSATheme.textSecondary)
                    .frame(width: 24)

                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(SSATheme.textMuted)
            }
        }
    }
}
