import SpriteKit
import SwiftUI

/// Special power-ups created by big matches.
enum SpecialKind: String, Equatable, Hashable, Codable {
    case rowBlaster   // 4 in a row → clear whole row
    case colBlaster   // 4 in a column → clear whole column
    case bomb         // L/T or 5 mixed → 3×3 blast
    case rainbow      // 5+ in a line → clear one snack type

    var emoji: String {
        switch self {
        case .rowBlaster: return "➡️"
        case .colBlaster: return "⬇️"
        case .bomb: return "💣"
        case .rainbow: return "🌈"
        }
    }

    var label: String {
        switch self {
        case .rowBlaster: return "Row Blaster"
        case .colBlaster: return "Col Blaster"
        case .bomb: return "Popcorn Bomb"
        case .rainbow: return "Rainbow Donut"
        }
    }

    var accent: SKColor {
        switch self {
        case .rowBlaster: return SKColor(red: 1, green: 0.55, blue: 0.2, alpha: 1)
        case .colBlaster: return SKColor(red: 0.3, green: 0.75, blue: 1, alpha: 1)
        case .bomb: return SKColor(red: 1, green: 0.25, blue: 0.35, alpha: 1)
        case .rainbow: return SKColor(red: 0.85, green: 0.45, blue: 1, alpha: 1)
        }
    }
}

/// Board cell: regular snack and optional special overlay.
struct BoardCell: Equatable {
    var snack: SnackType
    var special: SpecialKind?

    init(snack: SnackType, special: SpecialKind? = nil) {
        self.snack = snack
        self.special = special
    }
}
