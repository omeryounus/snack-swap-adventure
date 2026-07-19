import SwiftUI
import StoreKit

struct ShopView: View {
    let onBack: () -> Void
    @StateObject private var meta = MetaProgress.shared
    @StateObject private var store = StoreManager.shared
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
                    VStack(spacing: 18) {
                        // IAP star packs
                        sectionHeader("⭐ Star Packs", subtitle: "Real purchases via App Store (StoreKit)")
                        if store.isLoading {
                            ProgressView().tint(.white)
                        } else if store.products.isEmpty {
                            iapFallbackCard
                        } else {
                            ForEach(store.products, id: \.id) { product in
                                iapRow(product)
                            }
                        }
                        if let err = store.lastError {
                            Text(err)
                                .font(.caption2)
                                .foregroundStyle(.orange.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }

                        sectionHeader("🪙 Coin Boosters", subtitle: "Spend snack coins for next-level power-ups")
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
        .task {
            await store.loadProducts()
        }
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline.bold())
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private func iapRow(_ product: Product) -> some View {
        let stars = StoreManager.ProductID.starAmount(for: product.id)
        let busy = store.purchaseInFlight == product.id
        return HStack(spacing: 12) {
            Text("⭐")
                .font(.system(size: 34))
                .frame(width: 48, height: 48)
                .background(
                    LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(product.description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text("+\(stars) stars")
                    .font(.caption.bold())
                    .foregroundStyle(.yellow)
            }
            Spacer()
            Button {
                SoundManager.shared.playUITap()
                Task {
                    let ok = await store.purchase(product)
                    toast = ok ? "Purchased +\(stars) ⭐!" : (store.lastError ?? "Purchase cancelled")
                }
            } label: {
                if busy {
                    ProgressView().tint(.white)
                        .frame(width: 72, height: 34)
                } else {
                    Text(product.displayPrice)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                }
            }
            .disabled(busy)
        }
        .padding(14)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var iapFallbackCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("StoreKit products not loaded")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            Text("In Xcode: Scheme → Edit Scheme → Run → Options → StoreKit Configuration → Configuration.storekit")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            #if DEBUG
            Button {
                store.grantDebugStars(60)
                toast = "Debug: +60 ⭐"
                SoundManager.shared.playExtend()
            } label: {
                Text("DEBUG: Grant 60 ⭐")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            #endif
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
