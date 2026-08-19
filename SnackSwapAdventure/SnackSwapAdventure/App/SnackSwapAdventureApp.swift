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
                .task {
                    // ATT must be requested while the app is active, and before
                    // anything that could collect data used for tracking.
                    await TrackingConsent.shared.requestIfNeeded()
                    RewardedAdService.shared.start()
                    // No-ops when Remove Ads is owned.
                    InterstitialAdService.shared.start()
                }
                .onAppear {
                    GameCenterManager.shared.authenticateLocalPlayer()
                    Task {
                        await StoreManager.shared.loadProducts()
                    }
                }
        }
    }
}
