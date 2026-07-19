import SpriteKit
import SwiftUI

/// The six snack flavors that appear on the board.
enum SnackType: Int, CaseIterable, Equatable, Hashable, Codable {
    case cookie
    case donut
    case candy
    case popcorn
    case lollipop
    case cupcake

    var displayName: String {
        switch self {
        case .cookie: return "Cookie"
        case .donut: return "Donut"
        case .candy: return "Candy"
        case .popcorn: return "Popcorn"
        case .lollipop: return "Lollipop"
        case .cupcake: return "Cupcake"
        }
    }

    /// Bright, appetizing colors for prototype tiles.
    var color: SKColor {
        switch self {
        case .cookie: return SKColor(red: 0.85, green: 0.55, blue: 0.25, alpha: 1)
        case .donut: return SKColor(red: 1.00, green: 0.45, blue: 0.65, alpha: 1)
        case .candy: return SKColor(red: 0.35, green: 0.75, blue: 1.00, alpha: 1)
        case .popcorn: return SKColor(red: 1.00, green: 0.90, blue: 0.35, alpha: 1)
        case .lollipop: return SKColor(red: 0.70, green: 0.40, blue: 0.95, alpha: 1)
        case .cupcake: return SKColor(red: 0.40, green: 0.90, blue: 0.55, alpha: 1)
        }
    }

    var uiColor: Color {
        Color(color)
    }

    /// Simple emoji stand-ins until art assets land.
    var emoji: String {
        switch self {
        case .cookie: return "🍪"
        case .donut: return "🍩"
        case .candy: return "🍬"
        case .popcorn: return "🍿"
        case .lollipop: return "🍭"
        case .cupcake: return "🧁"
        }
    }

    static func random(excluding: Set<SnackType> = []) -> SnackType {
        let pool = allCases.filter { !excluding.contains($0) }
        return pool.randomElement() ?? .cookie
    }
}
