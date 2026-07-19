import SwiftUI

struct ShopView: View {
    let onBack: () -> Void
    @StateObject private var meta = MetaProgress.shared
    @State private var toast: String?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.16, green: 0.1, blue: 0.24), Color(red: 0.35, green: 0.18, blue: 0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        SoundManager.shared.playUITap()
                        onBack()
                    } label: {
                        Label("Back", systemImage: "chevron.left").font(.headline).foregroundStyle(.white)
                    }
                    Spacer()
                    Text("🛒 Shop").font(.title3.bold()).foregroundStyle(.white)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(meta.coins) 🪙")
                            .font(.subheadline.bold())
                            .foregroundStyle(.yellow)
                        Text("\(meta.stars) ⭐")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }
                }
                .padding()

                ScrollView {
                    VStack(spacing: 12) {
                        Text("Spend snack coins on boosters for your next level.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(.horizontal)

                        ForEach(MetaProgress.shopCatalog) { item in
                            shopRow(item)
                        }

                        if !meta.pendingBoosters.isEmpty {
                            Text("Queued for next level: \(meta.pendingBoosters.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(.mint)
                                .padding(.top, 8)
                        }
                    }
                    .padding(16)
                }

                if let toast {
                    Text(toast)
                        .font(.footnote.bold())
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                }
            }
        }
    }

    private func shopRow(_ item: ShopItem) -> some View {
        HStack(spacing: 12) {
            Text(item.emoji).font(.largeTitle)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.headline).foregroundStyle(.white)
                Text(item.description).font(.caption).foregroundStyle(.white.opacity(0.7))
                Text("Owned: \(meta.inventory[item.id, default: 0])")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            VStack(spacing: 8) {
                Button {
                    SoundManager.shared.playUITap()
                    if meta.buy(item) {
                        toast = "Bought \(item.name)!"
                    } else {
                        toast = "Not enough coins"
                    }
                } label: {
                    Text("\(item.cost) 🪙")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                Button {
                    SoundManager.shared.playUITap()
                    if meta.queueBooster(item.id) {
                        toast = "\(item.name) ready for next level"
                    } else {
                        toast = "Buy one first"
                    }
                } label: {
                    Text("Use next")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
