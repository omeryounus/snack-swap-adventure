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

    /// Phone landscape, SE 1st gen, or a short Split View slice.
    var isCompactHeight: Bool { height < 560 }
    /// SE / Mini / iPad 1/3 Split View.
    var isCompactWidth: Bool { width < 400 }
    /// Too tight for a side column + 8×8 board.
    var isVeryNarrow: Bool { width < 360 }

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

    /// Side column only when the leftover rectangle can still hold an 8×8 board.
    var usesSidebarGameplay: Bool {
        guard isLandscape else { return false }
        return width >= 520
    }

    /// Chrome column width, taken from the same partition `PlayfieldGeometry`
    /// uses so callers never disagree with the real layout.
    var gameplaySidebarWidth: CGFloat {
        PlayfieldGeometry.make(container: size, isLandscape: isLandscape, isPad: isPad).hud.width
    }

    /// Cap is high on phones so the board fills its SpriteView; iPad stays readable.
    var maxTileSize: CGFloat {
        let playable = min(width, height)
        let fromWindow = floor((playable - 24) / 6)
        switch deviceClass {
        case .compactPhone: return min(64, fromWindow)
        case .regularPhone: return min(96, fromWindow)
        case .largePhone: return min(120, fromWindow)
        case .compactPad: return min(88, fromWindow)
        case .regularPad: return min(96, fromWindow)
        case .largePad: return min(108, fromWindow)
        }
    }

    var boardMargin: CGFloat {
        isVeryNarrow || isCompactHeight ? 6 : (isPad ? 12 : 8)
    }

    /// Reserved space *inside* a full-screen SpriteView (portrait overlay mode).
    var portraitBoardTopReserved: CGFloat {
        let topSpace = height * PlayfieldGeometry.portraitTopRatio
        let hud: CGFloat = isPad ? 92 : 76
        return topSpace + hud + max(safeArea.top, 4)
    }

    var portraitBoardBottomReserved: CGFloat {
        let mascot: CGFloat = showsGameplaySpeech ? gameplayMascotSize + 46 : gameplayMascotSize + 10
        let boosters: CGFloat = isCompactHeight ? 64 : 78
        return boosters + mascot + max(safeArea.bottom, 6)
    }

    var gameplayMascotSize: CGFloat {
        if usesSidebarGameplay { return isPad ? 44 : 28 }
        switch deviceClass {
        case .compactPhone: return 32
        case .regularPhone: return 40
        case .largePhone: return 42
        case .compactPad: return 48
        case .regularPad, .largePad: return 56
        }
    }

    var showsGameplaySpeech: Bool {
        if usesSidebarGameplay { return isPad && height >= 700 }
        return !isCompactHeight && deviceClass != .compactPhone
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
        let gutter: CGFloat = isVeryNarrow ? 16 : 28
        if isPad { return min(520, width - 48) }
        if isLandscape { return min(460, max(240, width - gutter)) }
        return min(400, max(240, width - gutter))
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
        if isCompactHeight { return isPad ? 44 : 30 }
        if usesSidebarGameplay { return isPad ? 56 : 40 }
        if isPad { return 52 }
        return isCompactWidth ? 32 : 36
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
        isLandscape && width >= 640 && height >= 340
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
///
/// `.ignoresSafeArea()` is what lets this measure the whole window, but it also
/// zeroes `GeometryProxy.safeAreaInsets`, so the insets are read from the window
/// itself. Without that, every screen believed it had no notch, status bar, or
/// home indicator to avoid.
struct AdaptiveRoot<Content: View>: View {
    @ViewBuilder var content: () -> Content

    @State private var safeArea = EdgeInsets()

    var body: some View {
        GeometryReader { geo in
            let layout = AdaptiveLayout(
                size: CGSize(width: max(geo.size.width, 1), height: max(geo.size.height, 1)),
                safeArea: safeArea
            )
            content()
                .environment(\.adaptiveLayout, layout)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    refreshSafeArea()
                    LayoutMetrics.sync(from: layout)
                }
                .onChange(of: geo.size) { _, _ in
                    // Rotation: UIKit settles the new insets after the resize.
                    refreshSafeArea()
                    DispatchQueue.main.async { refreshSafeArea() }
                }
                .onChange(of: layout) { _, newValue in
                    LayoutMetrics.sync(from: newValue)
                }
        }
        .ignoresSafeArea()
    }

    private func refreshSafeArea() {
        let insets = AdaptiveRoot.windowSafeAreaInsets()
        if insets != safeArea { safeArea = insets }
    }

    static func windowSafeAreaInsets() -> EdgeInsets {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        guard let insets = window?.safeAreaInsets else { return EdgeInsets() }
        return EdgeInsets(
            top: insets.top,
            leading: insets.left,
            bottom: insets.bottom,
            trailing: insets.right
        )
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

    /// `AdaptiveRoot` consumes the safe area with `.ignoresSafeArea()` so it can
    /// measure the full window, which makes every descendant `.safeAreaPadding`
    /// a silent no-op. Screens must re-apply the insets captured in the layout —
    /// otherwise content slides under the status bar and, in landscape, under
    /// the Dynamic Island.
    func adaptiveSafeAreaPadding(
        _ layout: AdaptiveLayout,
        edges: Edge.Set = .all
    ) -> some View {
        padding(.top, edges.contains(.top) ? layout.safeArea.top : 0)
            .padding(.bottom, edges.contains(.bottom) ? layout.safeArea.bottom : 0)
            .padding(.leading, edges.contains(.leading) ? layout.safeArea.leading : 0)
            .padding(.trailing, edges.contains(.trailing) ? layout.safeArea.trailing : 0)
    }
}
