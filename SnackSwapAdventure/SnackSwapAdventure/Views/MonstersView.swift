import SwiftUI

struct MonstersView: View {
    let onBack: () -> Void
    @StateObject private var meta = MetaProgress.shared
    @StateObject private var profile = PlayerProfile.shared

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.14, green: 0.1, blue: 0.28), Color(red: 0.3, green: 0.12, blue: 0.3)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(MetaProgress.monsters) { monster in
                            monsterCard(monster)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .onAppear {
            meta.refreshMonsterUnlocks(maxLevel: profile.maxUnlockedLevel)
        }
    }

    private var header: some View {
        HStack {
            Button {
                SoundManager.shared.playUITap()
                onBack()
            } label: {
                Label("Back", systemImage: "chevron.left").font(.headline).foregroundStyle(.white)
            }
            Spacer()
            Text("👾 Monsters").font(.title3.bold()).foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 54)
        }
        .padding()
    }

    private func monsterCard(_ m: MonsterDef) -> some View {
        let unlocked = meta.isMonsterUnlocked(m.id)
        return VStack(spacing: 8) {
            Text(unlocked ? m.emoji : "🔒")
                .font(.system(size: 44))
                .grayscale(unlocked ? 0 : 1)
            Text(unlocked ? m.name : "???")
                .font(.headline)
                .foregroundStyle(.white)
            Text(unlocked ? m.blurb : "Unlock at level \(m.unlockLevel)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(minHeight: 36)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(unlocked ? 0.12 : 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(unlocked ? Color.pink.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
