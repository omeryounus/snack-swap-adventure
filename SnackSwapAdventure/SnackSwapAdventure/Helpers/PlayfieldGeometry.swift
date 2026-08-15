import CoreGraphics
import SwiftUI

/// Exclusive, non-overlapping frames for the play HUD, board, and booster dock.
/// Used by GameContainerView and unit-tested against SE through iPad Pro sizes.
struct PlayfieldGeometry: Equatable {
    var hud: CGRect
    var board: CGRect
    var dock: CGRect
    var isLandscape: Bool

    static let minimumBoardSide: CGFloat = 168
    /// Portrait breathing room above the HUD.
    static let portraitTopRatio: CGFloat = 0.10
    /// Landscape split: gameplay column is 70% of the content width.
    static let landscapeGameplayRatio: CGFloat = 0.70
    static let landscapeMinSidebar: CGFloat = 140
    /// Vertical gap between the moves/progress HUD and the booster dock.
    static let landscapeSectionGapRatio: CGFloat = 0.10

    static func make(container: CGSize, isLandscape: Bool, isPad: Bool) -> PlayfieldGeometry {
        let width = max(container.width, 1)
        let height = max(container.height, 1)
        let gap: CGFloat = isPad ? 12 : 8
        let pad: CGFloat = isPad ? 12 : 8

        if isLandscape && width >= 520 {
            return landscape(width: width, height: height, gap: gap, pad: pad, isPad: isPad)
        }
        return portrait(width: width, height: height, gap: gap, pad: pad, isPad: isPad)
    }

    private static func portrait(width: CGFloat, height: CGFloat, gap: CGFloat, pad: CGFloat, isPad: Bool) -> PlayfieldGeometry {
        let contentW = max(1, width - pad * 2)
        let topSpace = max(pad, height * Self.portraitTopRatio)
        let hudH = min(isPad ? 92 : 76, max(60, height * 0.09))
        let dockH = min(isPad ? 80 : 68, max(56, height * 0.08))

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

    private static func landscape(width: CGFloat, height: CGFloat, gap: CGFloat, pad: CGFloat, isPad: Bool) -> PlayfieldGeometry {
        let contentW = max(1, width - pad * 2)
        let contentH = max(1, height - pad * 2)
        var playW = contentW * Self.landscapeGameplayRatio
        var sidebarW = contentW - playW - gap
        if sidebarW < Self.landscapeMinSidebar {
            sidebarW = min(Self.landscapeMinSidebar, contentW * 0.38)
            playW = max(Self.minimumBoardSide, contentW - sidebarW - gap)
        }

        // Keep a 10% band between moves/progress and the booster dock so the
        // goal row is not clipped against the next section.
        let sectionGap = max(gap, contentH * Self.landscapeSectionGapRatio)
        let minDock: CGFloat = isPad ? 80 : 68
        let minHud: CGFloat = isPad ? 200 : 184
        let maxHud = max(minHud, contentH - sectionGap - minDock)
        let hudH = min(maxHud, max(minHud, contentH * 0.56))
        let dockH = max(minDock, contentH - hudH - sectionGap)

        let hud = CGRect(x: pad, y: pad, width: sidebarW, height: hudH)
        let dock = CGRect(x: pad, y: hud.maxY + sectionGap, width: sidebarW, height: dockH)
        let board = CGRect(x: pad + sidebarW + gap, y: pad, width: playW, height: contentH)
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
}
