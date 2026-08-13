import SwiftUI
import UIKit

/// Compatibility facade over `AdaptiveLayout`.
/// Prefer `@Environment(\.adaptiveLayout)` in SwiftUI views.
/// SpriteKit still reads `LayoutMetrics.shared` as a last-known snapshot.
@MainActor
struct LayoutMetrics {
    static var shared = LayoutMetrics(layout: .fallback)

    let isPad: Bool
    let isLandscape: Bool

    let hudSpacing: CGFloat
    let hudPillPaddingH: CGFloat
    let hudPillPaddingV: CGFloat
    let hudPillFont: CGFloat
    let hudTimerSize: CGFloat
    let hudTimerStroke: CGFloat
    let hudTimerFont: CGFloat
    let hudMaxWidth: CGFloat
    let hudHorizontalPadding: CGFloat
    let progressBarHeight: CGFloat

    let overlayMaxWidth: CGFloat
    let overlayPadding: CGFloat
    let overlayCornerRadius: CGFloat
    let overlayEmojiSize: CGFloat
    let overlayTitleFont: CGFloat
    let overlayButtonPaddingV: CGFloat

    let titleFontPrimary: CGFloat
    let titleFontSecondary: CGFloat
    let titleButtonMaxWidth: CGFloat
    let titleTopSpacer: CGFloat

    let contentMaxWidth: CGFloat
    let headerHeight: CGFloat

    let boardTopReserved: CGFloat
    let boardBottomReserved: CGFloat
    let maxTileSize: CGFloat

    init(layout: AdaptiveLayout) {
        isPad = layout.isPad
        isLandscape = layout.isLandscape

        hudSpacing = layout.hudSpacing
        hudPillPaddingH = layout.hudPillPaddingH
        hudPillPaddingV = layout.hudPillPaddingV
        hudPillFont = layout.hudPillFont
        hudTimerSize = layout.hudTimerSize
        hudTimerStroke = layout.hudTimerStroke
        hudTimerFont = layout.hudTimerFont
        hudMaxWidth = layout.hudMaxWidth
        hudHorizontalPadding = layout.hudHorizontalPadding
        progressBarHeight = layout.progressBarHeight

        overlayMaxWidth = layout.overlayMaxWidth
        overlayPadding = layout.overlayPadding
        overlayCornerRadius = layout.overlayCornerRadius
        overlayEmojiSize = layout.overlayEmojiSize
        overlayTitleFont = layout.overlayTitleFont
        overlayButtonPaddingV = layout.isPad ? 16 : 14

        titleFontPrimary = layout.titleHeroFont
        titleFontSecondary = layout.titleSecondaryFont
        titleButtonMaxWidth = layout.titleButtonMaxWidth
        titleTopSpacer = layout.isLandscape ? 24 : (layout.isPad ? 80 : 40)

        contentMaxWidth = layout.contentMaxWidth
        headerHeight = layout.headerHeight

        boardTopReserved = layout.usesSidebarGameplay ? layout.boardMargin : layout.portraitBoardTopReserved
        boardBottomReserved = layout.usesSidebarGameplay ? layout.boardMargin : layout.portraitBoardBottomReserved
        maxTileSize = layout.maxTileSize
    }

    /// Refresh the shared snapshot when the window size changes.
    static func sync(from layout: AdaptiveLayout) {
        shared = LayoutMetrics(layout: layout)
    }
}
