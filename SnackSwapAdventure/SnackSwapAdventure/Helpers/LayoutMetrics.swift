import UIKit

/// Centralized layout constants that adapt between iPhone and iPad.
/// Usage: `LayoutMetrics.shared.overlayMaxWidth`
@MainActor
struct LayoutMetrics {
    static let shared = LayoutMetrics()

    let isPad: Bool

    // MARK: - HUD
    let hudSpacing: CGFloat
    let hudPillPaddingH: CGFloat
    let hudPillPaddingV: CGFloat
    let hudPillFont: CGFloat         // caption-level font size
    let hudTimerSize: CGFloat
    let hudTimerStroke: CGFloat
    let hudTimerFont: CGFloat
    let hudMaxWidth: CGFloat
    let hudHorizontalPadding: CGFloat
    let progressBarHeight: CGFloat

    // MARK: - Overlays
    let overlayMaxWidth: CGFloat
    let overlayPadding: CGFloat
    let overlayCornerRadius: CGFloat
    let overlayEmojiSize: CGFloat
    let overlayTitleFont: CGFloat
    let overlayButtonPaddingV: CGFloat

    // MARK: - Title
    let titleFontPrimary: CGFloat
    let titleFontSecondary: CGFloat
    let titleButtonMaxWidth: CGFloat
    let titleTopSpacer: CGFloat

    // MARK: - Sub-screens
    let contentMaxWidth: CGFloat
    let headerHeight: CGFloat

    // MARK: - SpriteKit Board
    let boardTopReserved: CGFloat
    let boardBottomReserved: CGFloat
    let maxTileSize: CGFloat

    private init() {
        isPad = UIDevice.current.userInterfaceIdiom == .pad

        if isPad {
            // iPad scaled values
            hudSpacing = 14
            hudPillPaddingH = 14
            hudPillPaddingV = 10
            hudPillFont = 15
            hudTimerSize = 52
            hudTimerStroke = 5
            hudTimerFont = 16
            hudMaxWidth = 620
            hudHorizontalPadding = 24
            progressBarHeight = 18

            overlayMaxWidth = 420
            overlayPadding = 36
            overlayCornerRadius = 32
            overlayEmojiSize = 64
            overlayTitleFont = 34
            overlayButtonPaddingV = 16

            titleFontPrimary = 52
            titleFontSecondary = 38
            titleButtonMaxWidth = 440
            titleTopSpacer = 180

            contentMaxWidth = 600
            headerHeight = 52

            boardTopReserved = 340
            boardBottomReserved = 150
            maxTileSize = 72
        } else {
            // iPhone original values
            hudSpacing = 8
            hudPillPaddingH = 8
            hudPillPaddingV = 6
            hudPillFont = 12
            hudTimerSize = 38
            hudTimerStroke = 3.5
            hudTimerFont = 12
            hudMaxWidth = .infinity
            hudHorizontalPadding = 16
            progressBarHeight = 14

            overlayMaxWidth = .infinity
            overlayPadding = 28
            overlayCornerRadius = 28
            overlayEmojiSize = 54
            overlayTitleFont = 28
            overlayButtonPaddingV = 14

            titleFontPrimary = 38
            titleFontSecondary = 28
            titleButtonMaxWidth = .infinity
            titleTopSpacer = 120

            contentMaxWidth = .infinity
            headerHeight = 44

            boardTopReserved = 155
            boardBottomReserved = 90
            maxTileSize = 56
        }
    }
}
