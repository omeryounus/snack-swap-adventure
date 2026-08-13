import SwiftUI

@main
struct SnackSwapAdventureApp: App {
    init() {
        // Audio only — ads / Game Center / StoreKit wait until a window exists.
        // Starting Google Ads or Game Center from App.init() can terminate on device.
        _ = SoundManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(StoreManager.shared)
                .environmentObject(RewardedAdService.shared)
                .onAppear {
                    RewardedAdService.shared.start()
                    GameCenterManager.shared.authenticateLocalPlayer()
                    Task {
                        await StoreManager.shared.loadProducts()
                    }
                }
        }
    }
}
