import SwiftUI
import AVFoundation

// MARK: - SSA Design Tokens & Colors

struct SSATheme {
    static let bgVoid = Color(hex: "0B0614")
    static let bgElevated = Color(hex: "1A0F2E")
    static let glassBg = Color.white.opacity(0.08)
    static let glassBorder = Color.white.opacity(0.18)

    static let candyPink = Color(hex: "FF3D8A")
    static let candyOrange = Color(hex: "FF6B4A")
    static let candyYellow = Color(hex: "FFC24A")
    static let candyCyan = Color(hex: "5CE1FF")
    static let candyPurple = Color(hex: "A855F7")
    static let candyGreen = Color(hex: "34D399")

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.70)
    static let textMuted = Color.white.opacity(0.45)

    static let primaryGradient = LinearGradient(
        colors: [candyPink, candyOrange],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let goldGradient = LinearGradient(
        colors: [candyYellow, candyOrange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cyanGradient = LinearGradient(
        colors: [candyCyan, Color(hex: "3B82F6")],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - SSAGlassCard Component

struct SSAGlassCard<Content: View>: View {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 20
    var borderColor: Color = SSATheme.glassBorder
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(SSATheme.glassBg)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(SSATheme.bgElevated.opacity(0.4))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
    }
}

// MARK: - SSAPrimaryButton Component

struct SSAPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var gradient: LinearGradient = SSATheme.primaryGradient
    var isFullWidth: Bool = true
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            SoundManager.shared.playUITap()
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .padding(.horizontal, 24)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(gradient)
                    .shadow(color: SSATheme.candyPink.opacity(0.45), radius: isPressed ? 3 : 10, y: isPressed ? 2 : 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - LoopingVideoPlayerView Component

struct LoopingVideoPlayerView: UIViewRepresentable {
    let videoName: String
    let videoExtension: String

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        guard let url = Bundle.main.url(forResource: videoName, withExtension: videoExtension)
                ?? Bundle.main.url(forResource: videoName, withExtension: videoExtension, subdirectory: "Resources/splash")
                ?? Bundle.main.url(forResource: videoName, withExtension: videoExtension, subdirectory: "splash")
        else {
            return view
        }

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true
        context.coordinator.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        context.coordinator.player = queuePlayer

        let layer = AVPlayerLayer(player: queuePlayer)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        context.coordinator.playerLayer = layer

        queuePlayer.play()

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.playerLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var looper: AVPlayerLooper?
        var player: AVQueuePlayer?
        var playerLayer: AVPlayerLayer?
    }
}

// MARK: - WorldBackgroundPlate Component

struct WorldBackgroundPlate: View {
    var themeColor: Color = SSATheme.candyPurple
    var useVideo: Bool = true

    private let driftingSnacks = ["🍿", "🍪", "🍩", "🍭", "🍬", "🧁", "⭐"]

    var body: some View {
        ZStack {
            SSATheme.bgVoid.ignoresSafeArea()

            // 1. Menu Video Loop (at 15% opacity)
            if useVideo {
                LoopingVideoPlayerView(videoName: "splash", videoExtension: "mp4")
                    .ignoresSafeArea()
                    .opacity(0.15)
            }

            // 2. Cosmic Ambient Gradient Glows
            RadialGradient(
                colors: [themeColor.opacity(0.25), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [SSATheme.candyPink.opacity(0.18), .clear],
                center: .bottomTrailing,
                startRadius: 40,
                endRadius: 520
            )
            .ignoresSafeArea()

            // 3. Subtle Drifting Snacks at 15% opacity
            GeometryReader { geo in
                ForEach(0..<14, id: \.self) { i in
                    Text(driftingSnacks[i % driftingSnacks.count])
                        .font(.system(size: CGFloat((i * 7 + 16) % 24 + 18)))
                        .opacity(0.15)
                        .rotationEffect(.degrees(Double(i * 37 % 360)))
                        .position(
                            x: CGFloat((i * 83 + 31) % Int(max(1, geo.size.width))),
                            y: CGFloat((i * 127 + 43) % Int(max(1, geo.size.height)))
                        )
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - GameplayBackgroundView Component

struct GameplayBackgroundView: View {
    let level: Int

    private var plateAsset: String {
        switch level {
        case 1...10: return "bg_gameplay_cookie"
        case 11...20: return "bg_gameplay_popcorn"
        case 21...30: return "bg_gameplay_candy"
        default: return "bg_gameplay_soda"
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.04, green: 0.02, blue: 0.08)
                Image(plateAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(0.85)

                RadialGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    center: .center,
                    startRadius: min(geo.size.width, geo.size.height) * 0.18,
                    endRadius: max(geo.size.width, geo.size.height) * 0.72
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Custom Snackling Ghost Mascot Components

private enum SnacklingColors {
    static let bodyTop = Color(red: 0.72, green: 0.42, blue: 0.95)
    static let bodyBottom = Color(red: 0.48, green: 0.22, blue: 0.78)
    static let rim = Color(red: 0.85, green: 0.55, blue: 1.0)
    static let blush = Color.pink.opacity(0.45)
    static let eyeGalaxy = Color(red: 0.25, green: 0.15, blue: 0.55)
}

enum SnacklingPresentation { case homeHero, dock }

enum SnacklingExpression {
    case happy
    case cheer
    case sad
    case thinking
    case eating

    var emoji: String {
        switch self {
        case .happy: return "👻"
        case .cheer: return "🥳"
        case .sad: return "😿"
        case .thinking: return "🤔"
        case .eating: return "😋"
        }
    }

    var defaultMessage: String {
        switch self {
        case .happy: return "Ready to swap some snacks!"
        case .cheer: return "YAY! Amazing moves!"
        case .sad: return "Aww... try one more time!"
        case .thinking: return "Hmm... try a special match!"
        case .eating: return "YUMMY! Tasty snacks!"
        }
    }
}

/// Rounded ghost blob shape with 3-wave bottom tail
struct SnacklingBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Top dome
        path.move(to: CGPoint(x: 0.2 * w, y: 0.4 * h))
        path.addCurve(to: CGPoint(x: 0.8 * w, y: 0.4 * h),
                      control1: CGPoint(x: 0.2 * w, y: 0.05 * h),
                      control2: CGPoint(x: 0.8 * w, y: 0.05 * h))

        // Right side down to bottom tail
        path.addCurve(to: CGPoint(x: 0.85 * w, y: 0.85 * h),
                      control1: CGPoint(x: 0.95 * w, y: 0.55 * h),
                      control2: CGPoint(x: 0.95 * w, y: 0.75 * h))

        // Wavy bottom ghost tail scallops (3 waves)
        path.addQuadCurve(to: CGPoint(x: 0.6 * w, y: 0.85 * h), control: CGPoint(x: 0.725 * w, y: 0.98 * h))
        path.addQuadCurve(to: CGPoint(x: 0.35 * w, y: 0.85 * h), control: CGPoint(x: 0.475 * w, y: 0.98 * h))
        path.addQuadCurve(to: CGPoint(x: 0.15 * w, y: 0.85 * h), control: CGPoint(x: 0.25 * w, y: 0.98 * h))

        // Left side up to top dome
        path.addCurve(to: CGPoint(x: 0.2 * w, y: 0.4 * h),
                      control1: CGPoint(x: 0.05 * w, y: 0.75 * h),
                      control2: CGPoint(x: 0.05 * w, y: 0.55 * h))

        path.closeSubpath()
        return path
    }
}

struct SnacklingMascotView: View {
    var presentation: SnacklingPresentation = .homeHero
    var expression: SnacklingExpression = .happy
    var customSize: CGFloat? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var floatUp = false

    private var size: CGFloat { customSize ?? (presentation == .homeHero ? 120 : 64) }

    var body: some View {
        ZStack {
            // Borderless Mascot Image
            Image("mascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .shadow(color: SnacklingColors.bodyBottom.opacity(0.4), radius: 8, y: 3)
        }
        .frame(width: size * 1.2, height: size * 1.2 + 16)
        .offset(y: !reduceMotion ? (floatUp ? -4 : 4) : 0)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { floatUp = true }
        }
        .accessibilityLabel("Snackling")
    }
}

struct TitleHeroSnacklingSection: View {
    let playerName: String
    var speechText: String? = nil
    var mascotSize: CGFloat? = nil

    var body: some View {
        VStack(spacing: 16) {
            Text(speechText ?? "Ready to match snacks, \(playerName)?")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(SSATheme.bgElevated.opacity(0.9))
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                )
                .shadow(color: .black.opacity(0.3), radius: 6, y: 3)

            SnacklingMascotView(
                presentation: .homeHero,
                expression: .happy,
                customSize: mascotSize
            )
        }
    }
}

/// Backwards-compatible bridging wrapper for existing view callers
struct SnacklingMascot: View {
    var expression: SnacklingExpression = .happy
    var size: CGFloat = 80
    var speechBubbleText: String? = nil
    var animateFloat: Bool = true

    var body: some View {
        VStack(spacing: 8) {
            let text = speechBubbleText ?? expression.defaultMessage
            if !text.isEmpty {
                Text(text)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(SSATheme.bgElevated.opacity(0.9))
                            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    )
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
            }

            SnacklingMascotView(
                presentation: size >= 90 ? .homeHero : .dock,
                expression: expression,
                customSize: size
            )
        }
    }
}
