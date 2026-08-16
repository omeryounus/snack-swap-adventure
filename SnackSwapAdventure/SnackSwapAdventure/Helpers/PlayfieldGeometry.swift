import CoreGraphics
import SwiftUI

/// Exclusive, non-overlapping frames for the play HUD, board, and booster dock.
/// Used by GameContainerView and unit-tested against SE through iPad Pro sizes.
///
/// Every branch partitions the container by *subtraction*: the HUD and dock take
/// what they need, the board takes what is left. Nothing is sized independently
/// and hoped to fit, so the three rects can never intersect or leave the screen.
struct PlayfieldGeometry: Equatable {
    var hud: CGRect
    /// Square the board actually draws into — in landscape it is centered in the
    /// gameplay column rather than stretched across it.
    var board: CGRect
    var dock: CGRect
    var isLandscape: Bool

    static let minimumBoardSide: CGFloat = 168
    /// Portrait breathing room above the HUD.
    static let portraitTopRatio: CGFloat = 0.10
    static let landscapeMinSidebar: CGFloat = 140
    /// The sidebar stops growing here so wide screens spend their extra width on
    /// the board instead of on an increasingly empty chrome column.
    static let landscapeMaxSidebarPhone: CGFloat = 260
    static let landscapeMaxSidebarPad: CGFloat = 320
    /// Vertical gap between the moves/progress HUD and the booster dock.
    static let landscapeSectionGapRatio: CGFloat = 0.10
    /// Height reserved for each optional HUD row (Sugar Rush banner, hammer
    /// prompt). Without this the rows render outside the HUD rect and land on
    /// top of the board.
    static let hudAccessoryRowHeight: CGFloat = 32

    /// - Parameter hudAccessoryRows: transient HUD rows currently on screen.
    static func make(
        container: CGSize,
        isLandscape: Bool,
        isPad: Bool,
        hudAccessoryRows: Int = 0
    ) -> PlayfieldGeometry {
        let width = max(container.width, 1)
        let height = max(container.height, 1)
        let gap: CGFloat = isPad ? 12 : 8
        let pad: CGFloat = isPad ? 12 : 8
        let accessories = max(0, CGFloat(hudAccessoryRows)) * Self.hudAccessoryRowHeight

        if isLandscape && width >= 520 {
            return landscape(
                width: width, height: height, gap: gap, pad: pad,
                isPad: isPad, accessories: accessories
            )
        }
        return portrait(
            width: width, height: height, gap: gap, pad: pad,
            isPad: isPad, accessories: accessories
        )
    }

    private static func portrait(
        width: CGFloat, height: CGFloat, gap: CGFloat, pad: CGFloat,
        isPad: Bool, accessories: CGFloat
    ) -> PlayfieldGeometry {
        let contentW = max(1, width - pad * 2)
        // Floor raised to what the stat row + goal row actually measure; the old
        // 60pt floor was shorter than its own contents on SE-sized screens.
        let baseHud = min(isPad ? 92 : 76, max(isPad ? 84 : 68, height * 0.09))
        let hudH = baseHud + accessories
        let dockH = min(isPad ? 80 : 68, max(56, height * 0.08))

        // The 10% top band is a luxury: give it back before letting the board
        // drop under its minimum on short screens.
        let idealTop = max(pad, height * Self.portraitTopRatio)
        let fixed = hudH + dockH + gap * 2 + pad
        let wanted = min(contentW, Self.minimumBoardSide)
        let topSpace = max(pad, min(idealTop, height - fixed - wanted))

        let hud = CGRect(x: pad, y: topSpace, width: contentW, height: hudH)
        let dock = CGRect(x: pad, y: height - pad - dockH, width: contentW, height: dockH)

        let midTop = hud.maxY + gap
        let midBottom = max(midTop + 1, dock.minY - gap)
        let available = max(1, midBottom - midTop)
        let boardSide = min(contentW, available)
        let boardX = pad + (contentW - boardSide) / 2
        let boardY = midTop + max(0, (available - boardSide) / 2)
        let board = CGRect(x: boardX, y: boardY, width: boardSide, height: boardSide)
        return PlayfieldGeometry(hud: hud, board: board, dock: dock, isLandscape: false)
    }

    private static func landscape(
        width: CGFloat, height: CGFloat, gap: CGFloat, pad: CGFloat,
        isPad: Bool, accessories: CGFloat
    ) -> PlayfieldGeometry {
        let contentW = max(1, width - pad * 2)
        let contentH = max(1, height - pad * 2)

        // The board is square, so height caps it. Size the gameplay column from
        // that square and hand the leftover to the sidebar (clamped), instead of
        // a fixed 70/30 split that starved the HUD on small phones while leaving
        // dead space beside the board.
        let maxSidebar = isPad ? Self.landscapeMaxSidebarPad : Self.landscapeMaxSidebarPhone
        let squareBudget = max(
            Self.minimumBoardSide,
            min(contentH, contentW - Self.landscapeMinSidebar - gap)
        )
        let sidebarW = min(
            max(Self.landscapeMinSidebar, contentW - squareBudget - gap),
            max(Self.landscapeMinSidebar, min(maxSidebar, contentW - Self.minimumBoardSide - gap))
        )
        let columnW = max(Self.minimumBoardSide, contentW - sidebarW - gap)

        // Split the sidebar into HUD / gap / dock so the three always sum to
        // contentH exactly. The dock is pinned to the bottom at the height a
        // 3-up booster row actually needs — deriving it from leftover space
        // squeezed it to ~130pt and clipped two of the three boosters. The 10%
        // band is ideal, not mandatory: it collapses toward `gap` before the
        // HUD would be pushed under its own content height.
        let minDock: CGFloat = isPad ? 80 : 68
        let dockH = max(minDock, min(contentH * 0.22, isPad ? 96 : 84))
        let minHud = (isPad ? 200 : 184) + accessories
        let idealGap = max(gap, contentH * Self.landscapeSectionGapRatio)

        var sectionGap = idealGap
        var hudH = max(1, contentH - dockH - sectionGap)
        if hudH < minHud {
            sectionGap = max(gap, contentH - minHud - dockH)
            hudH = max(1, contentH - dockH - sectionGap)
        }

        let hud = CGRect(x: pad, y: pad, width: sidebarW, height: hudH)
        let dock = CGRect(x: pad, y: hud.maxY + sectionGap, width: sidebarW, height: dockH)

        // Center the square in its column so the board card hugs the board.
        let boardSide = max(1, min(columnW, contentH))
        let board = CGRect(
            x: pad + sidebarW + gap + (columnW - boardSide) / 2,
            y: pad + (contentH - boardSide) / 2,
            width: boardSide,
            height: boardSide
        )
        return PlayfieldGeometry(hud: hud, board: board, dock: dock, isLandscape: true)
    }

    /// Shared edges are allowed; interiors must not overlap.
    func overlappingPairs() -> [(String, String)] {
        var pairs: [(String, String)] = []
        let items: [(String, CGRect)] = [
            ("hud", hud.insetBy(dx: 0.5, dy: 0.5)),
            ("board", board.insetBy(dx: 0.5, dy: 0.5)),
            ("dock", dock.insetBy(dx: 0.5, dy: 0.5))
        ]
        for i in 0..<items.count {
            for j in (i + 1)..<items.count where items[i].1.intersects(items[j].1) {
                pairs.append((items[i].0, items[j].0))
            }
        }
        return pairs
    }

    func isFullyContained(in container: CGSize, tolerance: CGFloat = 0.5) -> Bool {
        let bounds = CGRect(
            x: -tolerance,
            y: -tolerance,
            width: container.width + tolerance * 2,
            height: container.height + tolerance * 2
        )
        return bounds.contains(hud) && bounds.contains(board) && bounds.contains(dock)
    }
}

extension PlayfieldGeometry {
    static let referenceDevices: [(name: String, size: CGSize, isPad: Bool)] = [
        ("iPhone SE 1 portrait", CGSize(width: 320, height: 568), false),
        ("iPhone SE 1 landscape", CGSize(width: 568, height: 320), false),
        ("iPhone SE 3 portrait", CGSize(width: 375, height: 667), false),
        ("iPhone SE 3 landscape", CGSize(width: 667, height: 375), false),
        ("iPhone 14 portrait", CGSize(width: 390, height: 844), false),
        ("iPhone 14 landscape", CGSize(width: 844, height: 390), false),
        ("iPhone 16 Pro portrait", CGSize(width: 402, height: 874), false),
        ("iPhone 16 Pro landscape", CGSize(width: 874, height: 402), false),
        ("iPhone 16 Pro Max portrait", CGSize(width: 440, height: 956), false),
        ("iPhone 16 Pro Max landscape", CGSize(width: 956, height: 440), false),
        ("iPhone 17 Pro Max portrait", CGSize(width: 440, height: 956), false),
        ("iPhone 17 Pro Max landscape", CGSize(width: 956, height: 440), false),
        ("iPad mini portrait", CGSize(width: 744, height: 1133), true),
        ("iPad mini landscape", CGSize(width: 1133, height: 744), true),
        ("iPad 11 portrait", CGSize(width: 834, height: 1194), true),
        ("iPad 11 landscape", CGSize(width: 1194, height: 834), true),
        ("iPad Pro 12.9 portrait", CGSize(width: 1024, height: 1366), true),
        ("iPad Pro 12.9 landscape", CGSize(width: 1366, height: 1024), true),
        ("iPad Split 1/3", CGSize(width: 320, height: 834), true),
        ("iPad Split 1/2 landscape", CGSize(width: 694, height: 834), true)
    ]

    /// Transient HUD rows are part of the layout contract, so they are swept in
    /// the tests exactly like the device sizes are.
    static let accessoryRowCases: [Int] = [0, 1, 2]
}
