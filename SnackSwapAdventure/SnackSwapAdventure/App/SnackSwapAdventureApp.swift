import SwiftUI

@main
struct SnackSwapAdventureApp: App {
    init() {
        // Warm up audio session + preload SFX so first taps feel instant.
        _ = SoundManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
