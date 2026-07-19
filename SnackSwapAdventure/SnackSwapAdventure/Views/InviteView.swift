import SwiftUI

struct InviteView: View {
    let onBack: () -> Void
    @StateObject private var meta = MetaProgress.shared
    @State private var toast: String?
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.08, blue: 0.32),
                    Color(red: 0.4, green: 0.15, blue: 0.35),
                    Color(red: 0.55, green: 0.25, blue: 0.2)
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
                    Text("🎁 Invite Friends")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 54)
                }
                .padding()

                ScrollView {
                    VStack(spacing: 22) {
                        Text("⭐")
                            .font(.system(size: 72))
                            .scaleEffect(pulse ? 1.12 : 0.95)
                            .shadow(color: .yellow.opacity(0.5), radius: pulse ? 20 : 8)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)

                        Text("Share & earn free stars")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("Invite friends to Snack Swap Adventure. Each share gives you **\(MetaProgress.inviteRewardStars) ⭐** (up to \(MetaProgress.maxInviteRewardsPerDay)/day).")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)

                        VStack(spacing: 10) {
                            Text("Your invite code")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                            Text(meta.inviteCode)
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                                )
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .onTapGesture {
                                    UIPasteboard.general.string = meta.inviteCode
                                    toast = "Code copied!"
                                    SoundManager.shared.playUITap()
                                }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

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
                                .font(.headline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [.pink, .orange, .yellow], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(color: .orange.opacity(0.4), radius: 12, y: 6)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            claimReward()
                        })

                        Button {
                            claimReward()
                            // Also open system share if needed
                        } label: {
                            Text("I already shared — claim ⭐")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        Text("Friends can enter your code in Stats (coming soon) or just play — you still earn stars for sharing.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                }

                if let toast {
                    Text(toast)
                        .font(.footnote.bold())
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear { pulse = true }
    }

    private func statChip(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline.bold()).foregroundStyle(.white)
            Text(title).font(.caption2).foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func claimReward() {
        SoundManager.shared.playUITap()
        let gained = meta.claimInviteReward()
        if gained > 0 {
            toast = "+\(gained) ⭐ thanks for sharing!"
            SoundManager.shared.playExtend()
        } else {
            toast = "Daily invite limit reached — come back tomorrow!"
        }
    }
}

#Preview {
    InviteView(onBack: {})
}
