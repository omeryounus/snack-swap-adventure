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
        let contentH = max(1, height - pad * 2)
        let hudH = min(isPad ? 136 : 120, max(88, contentH * 0.17))
        let dockH = min(isPad ? 88 : 76, max(64, contentH * 0.13))
        let boardBudget = max(Self.minimumBoardSide, contentH - hudH - dockH - gap * 2)
        let boardSide = min(contentW, boardBudget)

        let hud = CGRect(x: pad, y: pad, width: contentW, height: hudH)
        let boardX = pad + (contentW - boardSide) / 2
        let boardY = hud.maxY + gap
        let board = CGRect(x: boardX, y: boardY, width: boardSide, height: boardSide)
        let dockY = min(height - pad - dockH, board.maxY + gap)
        let dock = CGRect(x: pad, y: dockY, width: contentW, height: dockH)
        return PlayfieldGeometry(hud: hud, board: board, dock: dock, isLandscape: false)
    }

    private static func landscape(width: CGFloat, height: CGFloat, gap: CGFloat, pad: CGFloat, isPad: Bool) -> PlayfieldGeometry {
        let contentW = max(1, width - pad * 2)
        let contentH = max(1, height - pad * 2)
        let boardSide = min(contentH, max(Self.minimumBoardSide, contentW * 0.62))
        let sidebarW = max(132, contentW - boardSide - gap)
        let hudH = min(isPad ? 168 : 132, max(96, contentH * 0.42))
        let dockH = max(64, contentH - hudH - gap)

        let hud = CGRect(x: pad, y: pad, width: sidebarW, height: hudH)
        let dock = CGRect(x: pad, y: hud.maxY + gap, width: sidebarW, height: dockH)
        let boardX = pad + sidebarW + gap
        let boardY = pad + max(0, (contentH - boardSide) / 2)
        let board = CGRect(x: boardX, y: boardY, width: boardSide, height: boardSide)
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
