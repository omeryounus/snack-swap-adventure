import SwiftUI

/// Shared chrome for menu screens: live-safe-area header, centered iPad width,
/// and a scroll view that stays usable in landscape / Split View.
struct ScreenScaffold<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var accent: Color = SSATheme.candyYellow
    var themeColor: Color = SSATheme.candyPurple
    var onBack: (() -> Void)? = nil
    var trailing: AnyView? = nil
    @ViewBuilder var content: () -> Content

    @Environment(\.adaptiveLayout) private var layout

    var body: some View {
        ZStack(alignment: .top) {
            WorldBackgroundPlate(themeColor: themeColor)

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, layout.screenPadding)
                    .padding(.top, 8)
                    .padding(.bottom, layout.isCompactHeight ? 8 : 14)

                ScrollView(showsIndicators: false) {
                    content()
                        .frame(maxWidth: layout.contentMaxWidth == .infinity ? .infinity : layout.contentMaxWidth)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, layout.screenPadding)
                        .padding(.bottom, layout.scrollBottomPadding)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .adaptiveSafeAreaPadding(layout)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button {
                    SoundManager.shared.playUITap()
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: layout.isPad ? 20 : 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: layout.controlSize, height: layout.controlSize)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .accessibilityLabel("Back")
            }

            Spacer(minLength: 4)

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: layout.screenTitleFont, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: layout.screenSubtitleFont, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }

            Spacer(minLength: 4)

            if let trailing {
                trailing
            } else {
                Color.clear.frame(width: layout.controlSize, height: layout.controlSize)
            }
        }
        .frame(minHeight: layout.headerHeight)
    }
}

/// Modal card that shrinks and scrolls on compact-height (phone landscape) windows.
struct AdaptiveModalCard<Content: View>: View {
    @Environment(\.adaptiveLayout) private var layout
    var maxWidth: CGFloat? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        let cardWidth = maxWidth ?? layout.overlayMaxWidth
        let maxCardHeight = max(160, layout.height - max(layout.safeArea.top + layout.safeArea.bottom, 16) - 12)

        // A bare ScrollView takes every point it is offered, which left short
        // modals stretched down the whole screen. Render unscrolled when the
        // content fits and only fall back to scrolling when it genuinely
        // overflows.
        ViewThatFits(in: .vertical) {
            content()
                .padding(layout.overlayPadding)

            // Only the scrolling fallback gets a height cap. `.frame(maxHeight:)`
            // accepts the parent's proposal up to its limit, so applying it to
            // the whole card stretched even short modals down the screen.
            ScrollView(showsIndicators: false) {
                content()
                    .padding(layout.overlayPadding)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: maxCardHeight)
        }
        .frame(maxWidth: cardWidth)
        .background(
            RoundedRectangle(cornerRadius: layout.overlayCornerRadius, style: .continuous)
                .fill(SSATheme.bgElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: layout.overlayCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.45), radius: 30, y: 12)
        .padding(.horizontal, layout.isCompactWidth ? 12 : 20)
        .padding(.vertical, layout.isCompactHeight ? 8 : 16)
    }
}
