import SwiftUI

@main
struct SnackSwapAdventureApp: App {
    init() {
        // Warm up audio + ads + store so first interactions feel instant.
        _ = SoundManager.shared
        RewardedAdService.shared.start()
        Task {
            await StoreManager.shared.loadProducts()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(StoreManager.shared)
                .environmentObject(RewardedAdService.shared)
        }
    }
}
