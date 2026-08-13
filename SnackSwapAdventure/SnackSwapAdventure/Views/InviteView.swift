import SwiftUI

struct InviteView: View {
    let onBack: () -> Void
    @StateObject private var meta = MetaProgress.shared
    @State private var toast: String?
    @State private var pulse = false

    @Environment(\.adaptiveLayout) private var layout

    var body: some View {
        ZStack(alignment: .bottom) {
            ScreenScaffold(
                title: "Invite",
                subtitle: "Share & earn free stars",
                accent: SSATheme.candyPink,
                themeColor: SSATheme.candyPink,
                onBack: onBack
            ) {
                    VStack(spacing: layout.isCompactHeight ? 14 : 22) {
                        Text("⭐")
                            .font(.system(size: layout.isCompactHeight ? 48 : (layout.isPad ? 88 : 72)))
                            .scaleEffect(pulse ? 1.12 : 0.95)
                            .shadow(color: .yellow.opacity(0.5), radius: pulse ? 20 : 8)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)

                        Text("Share & earn free stars")
                            .font(Theme.fontTitle().bold())
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Invite friends to Snack Swap Adventure. Each share gives you **\(MetaProgress.inviteRewardStars) ⭐** (up to \(MetaProgress.maxInviteRewardsPerDay)/day).")
                            .font(Theme.fontBody())
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)

                        VStack(spacing: 10) {
                            Text("Your invite code")
                                .font(Theme.fontCaption())
                                .foregroundStyle(Theme.textSecondary)
                            
                            Text(meta.inviteCode)
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(colors: [Theme.accentGold, .orange], startPoint: .leading, endPoint: .trailing)
                                )
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .onTapGesture {
                                    UIPasteboard.general.string = meta.inviteCode
                                    toast = "Code copied!"
                                    SoundManager.shared.play(.uiTap)
                                }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity)
                        .glassCard()

                        HStack(spacing: 12) {
                            statChip("Today", "\(meta.invitesToday)/\(MetaProgress.maxInviteRewardsPerDay)")
                            statChip("Total invites", "\(meta.totalInvites)")
                            statChip("Your ⭐", "\(meta.stars)")
                        }

                        ShareLink(
                            item: meta.inviteShareMessage,
                            subject: Text("Play Snack Swap Adventure with me!"),
                            message: Text(meta.inviteShareMessage)
                        ) {
                            Label("Share invite", systemImage: "square.and.arrow.up")
                                .font(Theme.fontBody().bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.accentPrimary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous))
                                .shadow(color: .orange.opacity(0.4), radius: 12, y: 6)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            claimReward()
                        })

                        Button {
                            claimReward()
                        } label: {
                            Text("I already shared — claim ⭐")
                                .font(Theme.fontCaption().bold())
                                .foregroundStyle(Theme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        Text("Friends can enter your code in Stats (coming soon) or just play — you still earn stars for sharing.")
                            .font(Theme.fontCaption())
                            .foregroundStyle(Theme.textTertiary)
                            .multilineTextAlignment(.center)
                    }
            }

            if let toast {
                Text(toast)
                    .font(Theme.fontCaption().bold())
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { pulse = true }
    }

    private func statChip(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.fontBody().bold())
                .foregroundStyle(Theme.textPrimary)
            Text(title)
                .font(Theme.fontCaption())
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassCard()
    }

    private func claimReward() {
        SoundManager.shared.play(.uiTap)
        let gained = meta.claimInviteReward()
        if gained > 0 {
            toast = "+\(gained) ⭐ thanks for sharing!"
            SoundManager.shared.play(.extend)
        } else {
            toast = "Daily invite limit reached — come back tomorrow!"
        }
    }
}

#Preview {
    InviteView(onBack: {})
}
