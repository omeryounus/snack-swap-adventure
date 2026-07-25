import SwiftUI

enum Theme {
    // Colors
    static let bgVoid = Color(hex: "0B0614")
    static let bgElevated = Color(hex: "1A0F2E")
    static let bgGlass = Color.white.opacity(0.08)
    
    static let accentPrimary = LinearGradient(
        colors: [Color(hex: "FF6B4A"), Color(hex: "FF3D8A")],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let accentGold = Color(hex: "FFC24A")
    static let accentCyan = Color(hex: "5CE1FF")
    
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.56)
    static let textTertiary = Color.white.opacity(0.36)
    
    // World Colors
    static let worldCookie = Color(hex: "E8A87C")
    static let worldPopcorn = Color(hex: "F5D547")
    static let worldCandy = Color(hex: "FF4FD8")
    static let worldSoda = Color(hex: "3DDCFF")
    
    // Shadows
    static let shadowColor = Color.black.opacity(0.35)
    static let shadowRadius: CGFloat = 24
    static let shadowY: CGFloat = 8
    
    // Spacing
    static let gridUnit: CGFloat = 8
    static let screenMargin: CGFloat = 20
    
    // Corners
    static let cardCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 16
    
    // Typography
    static func fontDisplay() -> Font {
        .system(size: 34, weight: .bold, design: .rounded)
    }
    
    static func fontTitle() -> Font {
        .system(size: 22, weight: .semibold, design: .rounded)
    }
    
    static func fontBody() -> Font {
        .system(size: 17, weight: .regular, design: .default)
    }
    
    static func fontCaption() -> Font {
        .system(size: 13, weight: .medium, design: .default)
    }
    
    static func fontTabular() -> Font {
        .system(size: 17, weight: .semibold, design: .rounded).monospacedDigit()
    }
}

// Helper color hex initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Glassmorphism modifier
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = Theme.cardCornerRadius
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.bgGlass)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = Theme.cardCornerRadius) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
