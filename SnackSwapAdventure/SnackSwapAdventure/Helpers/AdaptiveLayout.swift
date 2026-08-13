import SwiftUI
import UIKit

/// Device + orientation-aware layout tokens derived from the live window size.
/// Injected via `EnvironmentValues.adaptiveLayout` so every screen reacts to
/// iPhone SE through iPad Pro, portrait, landscape, and Split View.
struct AdaptiveLayout: Equatable {
    var width: CGFloat
    var height: CGFloat
    var safeArea: EdgeInsets

    static let fallback = AdaptiveLayout(
        width: 390,
        height: 844,
        safeArea: EdgeInsets(top: 47, leading: 0, bottom: 34, trailing: 0)
    )

    init(width: CGFloat, height: CGFloat, safeArea: EdgeInsets) {
        self.width = width
        self.height = height
        self.safeArea = safeArea
    }

    init(size: CGSize, safeArea: EdgeInsets) {
        self.init(width: size.width, height: size.height, safeArea: safeArea)
    }

    var size: CGSize { CGSize(width: width, height: height) }
    var isLandscape: Bool { width > height + 12 }
    var isPortrait: Bool { !isLandscape }
    var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    var isPhone: Bool { !isPad }
    var shortestSide: CGFloat { min(width, height) }
    var longestSide: CGFloat { max(width, height) }

    /// True when vertical space is tight (phone landscape, Split View, SE).
    var isCompactHeight: Bool { height < 560 }
    /// True when the window is phone-narrow (SE, Mini, iPad 1/3 Split View).
    var isCompactWidth: Bool { width < 400 }

    enum DeviceClass: String, Equatable {
        case compactPhone
        case regularPhone
        case largePhone
        case compactPad
        case regularPad
        case largePad
    }

    var deviceClass: DeviceClass {
        if isPad {
            if shortestSide < 700 { return .compactPad }
            if shortestSide >= 1000 { return .largePad }
            return .regularPad
        }
        if shortestSide <= 375 { return .compactPhone }
        if shortestSide >= 428 { return .largePhone }
        return .regularPhone
    }

    // MARK: - Gameplay chrome

    /// Landscape (any device) uses a side column so the 8×8 board stays tappable.
    var usesSidebarGameplay: Bool { isLandscape }

    var gameplaySidebarWidth: CGFloat {
        if isPad {
            return min(340, max(248, width * 0.26))
        }
        if isCompactHeight {
            return min(232, max(176, width * 0.32))
        }
        return min(250, max(196, width * 0.34))
    }

    var maxTileSize: CGFloat {
        switch deviceClass {
        case .compactPhone: return 48
        case .regularPhone: return 56
        case .largePhone: return 62
        case .compactPad: return 68
        case .regularPad: return 78
        case .largePad: return 88
        }
    }

    var boardMargin: CGFloat {
        isPad ? 20 : (isCompactWidth ? 10 : 14)
    }

    /// Reserved space *inside* a full-screen SpriteView (portrait overlay mode).
    var portraitBoardTopReserved: CGFloat {
        let hud = 12 + hudControlSize + 10 + progressBarHeight + 36
        return hud + max(safeArea.top, 8)
    }

    var portraitBoardBottomReserved: CGFloat {
        let mascot: CGFloat = showsGameplaySpeech ? gameplayMascotSize + 46 : gameplayMascotSize + 10
        let boosters: CGFloat = isCompactHeight ? 64 : 78
        return boosters + mascot + max(safeArea.bottom, 6)
    }

    var gameplayMascotSize: CGFloat {
        if usesSidebarGameplay { return isPad ? 52 : 34 }
        switch deviceClass {
        case .compactPhone: return 34
        case .regularPhone, .largePhone: return 44
        case .compactPad: return 52
        case .regularPad, .largePad: return 60
        }
    }

    var showsGameplaySpeech: Bool {
        if usesSidebarGameplay { return isPad || height >= 390 }
        return deviceClass != .compactPhone
    }

    // MARK: - Spacing

    var screenPadding: CGFloat {
        switch deviceClass {
        case .compactPhone: return 14
        case .regularPhone: return 18
        case .largePhone: return 22
        case .compactPad: return 24
        case .regularPad: return 32
        case .largePad: return 40
        }
    }

    var contentMaxWidth: CGFloat {
        if isPad {
            return isLandscape ? 920 : 740
        }
        if isLandscape && width >= 700 {
            return 680
        }
        return .infinity
    }

    var overlayMaxWidth: CGFloat {
        if isPad { return min(500, width - 48) }
        if isLandscape { return min(460, width - 48) }
        return min(400, width - 28)
    }

    var overlayPadding: CGFloat {
        if isCompactHeight { return 16 }
        return isPad ? 32 : 24
    }

    var overlayCornerRadius: CGFloat { isPad ? 32 : 26 }

    var sectionSpacing: CGFloat {
        if isCompactHeight { return 12 }
        return isPad ? 22 : 18
    }

    var headerHeight: CGFloat { isPad ? 56 : 48 }

    var scrollBottomPadding: CGFloat {
        max(24, safeArea.bottom + 16)
    }

    var controlSize: CGFloat {
        if isPad { return 48 }
        return isCompactWidth ? 40 : 44
    }

    // MARK: - HUD

    var hudSpacing: CGFloat { isPad ? 14 : (isCompactWidth ? 6 : 8) }
    var hudPillPaddingH: CGFloat { isPad ? 14 : (isCompactWidth ? 6 : 8) }
    var hudPillPaddingV: CGFloat { isPad ? 10 : (isCompactHeight ? 4 : 6) }
    var hudPillFont: CGFloat { isPad ? 15 : (isCompactWidth ? 11 : 12) }
    var hudTimerSize: CGFloat {
        if usesSidebarGameplay { return isPad ? 64 : 46 }
        if isPad { return 52 }
        return isCompactWidth ? 34 : 38
    }
    var hudTimerStroke: CGFloat { isPad ? 5 : 3.5 }
    var hudTimerFont: CGFloat { isPad ? 18 : 12 }
    var hudMaxWidth: CGFloat { isPad ? 680 : .infinity }
    var hudHorizontalPadding: CGFloat { isPad ? 24 : (isCompactWidth ? 10 : 16) }
    var hudControlSize: CGFloat { isPad ? 46 : (isCompactWidth ? 32 : 36) }
    var progressBarHeight: CGFloat { isPad ? 18 : (isCompactHeight ? 10 : 14) }

    // MARK: - Type

    var titleHeroFont: CGFloat {
        switch deviceClass {
        case .compactPhone: return isLandscape ? 30 : 34
        case .regularPhone: return isLandscape ? 34 : 40
        case .largePhone: return isLandscape ? 36 : 44
        case .compactPad: return 48
        case .regularPad: return isLandscape ? 50 : 54
        case .largePad: return 60
        }
    }

    var titleSecondaryFont: CGFloat {
        max(20, titleHeroFont * 0.68)
    }

    var screenTitleFont: CGFloat { isPad ? 26 : (isCompactWidth ? 18 : 22) }
    var screenSubtitleFont: CGFloat { isPad ? 13 : 11 }
    var bodyFont: CGFloat { isPad ? 18 : 16 }
    var captionFont: CGFloat { isPad ? 14 : 12 }

    var overlayEmojiSize: CGFloat {
        if isCompactHeight { return 40 }
        return isPad ? 64 : 54
    }

    var overlayTitleFont: CGFloat {
        if isCompactHeight { return 22 }
        return isPad ? 34 : 28
    }

    // MARK: - Grids

    var navGridColumns: Int {
        if isPad && isLandscape { return 4 }
        if isPad { return 2 }
        if isLandscape && width >= 700 { return 4 }
        return 2
    }

    var shopGridColumns: Int {
        if isPad && isLandscape { return 3 }
        if isPad { return 3 }
        if isLandscape && !isCompactWidth { return 3 }
        return 2
    }

    var monsterGridColumns: Int {
        if isPad && isLandscape { return 4 }
        if isPad { return 3 }
        if isLandscape && !isCompactWidth { return 3 }
        return 2
    }

    var statsGridColumns: Int {
        if isPad && isLandscape { return 4 }
        return 2
    }

    var worldMapColumns: Int {
        if isPad { return isLandscape ? 2 : 1 }
        if isLandscape && width >= 740 { return 2 }
        return 1
    }

    var dailyRewardColumns: Int {
        if isCompactWidth && isPortrait { return 4 }
        if isLandscape || isPad { return 7 }
        return 4
    }

    func gridItems(count: Int, spacing: CGFloat = 14) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: max(1, count))
    }

    // MARK: - Title screen

    var titleMascotSize: CGFloat {
        if isLandscape && isPhone { return 72 }
        switch deviceClass {
        case .compactPhone: return 88
        case .regularPhone: return 120
        case .largePhone: return 128
        case .compactPad: return 140
        case .regularPad, .largePad: return 160
        }
    }

    var titleUsesSplitLayout: Bool {
        isLandscape && width >= 640
    }

    var titleButtonMaxWidth: CGFloat {
        if isPad { return 440 }
        if titleUsesSplitLayout { return 360 }
        return .infinity
    }

    var splashMascotSize: CGFloat {
        if isCompactHeight { return 72 }
        return isPad ? 140 : 110
    }
}

// MARK: - Environment

private struct AdaptiveLayoutKey: EnvironmentKey {
    static let defaultValue = AdaptiveLayout.fallback
}

extension EnvironmentValues {
    var adaptiveLayout: AdaptiveLayout {
        get { self[AdaptiveLayoutKey.self] }
        set { self[AdaptiveLayoutKey.self] = newValue }
    }
}

/// Root reader that publishes a live `AdaptiveLayout` into the environment.
struct AdaptiveRoot<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let layout = AdaptiveLayout(size: geo.size, safeArea: geo.safeAreaInsets)
            content()
                .environment(\.adaptiveLayout, layout)
                .frame(width: geo.size.width, height: geo.size.height)
                .onAppear { LayoutMetrics.sync(from: layout) }
                .onChange(of: layout) { _, newValue in
                    LayoutMetrics.sync(from: newValue)
                }
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Centers content and caps width on iPad / wide landscape.
    func adaptiveContentWidth(_ layout: AdaptiveLayout) -> some View {
        frame(maxWidth: layout.contentMaxWidth == .infinity ? .infinity : layout.contentMaxWidth)
            .frame(maxWidth: .infinity)
    }

    func adaptiveHorizontalPadding(_ layout: AdaptiveLayout) -> some View {
        padding(.horizontal, layout.screenPadding)
    }
}
