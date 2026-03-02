import SwiftUI

// MARK: - Animation Helper
struct AnimationHelper {
    /// Spring animation for standard interactions
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)

    /// Quick spring animation for buttons
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Slow spring animation for content transitions
    static let slowSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)

    /// Ease-out animation for list items
    static let easeOut = Animation.easeOut(duration: 0.3)

    /// Ease-in-out animation for modal presentations
    static let easeInOut = Animation.easeInOut(duration: 0.35)

    /// Bouncy animation for success states
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)

    /// Fade-in animation with scale
    static func fadeInScale(delay: Double = 0) -> Animation {
        Animation.easeOut(duration: 0.4).delay(delay)
    }

    /// Slide-in animation from bottom
    static func slideIn(from edge: Edge = .bottom, delay: Double = 0) -> Animation {
        Animation.easeOut(duration: 0.35).delay(delay)
    }

    /// Stagger animation for multiple items
    static func staggered(baseDelay: Double, index: Int, spacing: Double = 0.05) -> Animation {
        Animation.easeOut(duration: 0.4).delay(baseDelay + Double(index) * spacing)
    }
}

// MARK: - Animated View Modifier
struct AnimatedAppear: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.95)
            .animation(AnimationHelper.fadeInScale(delay: delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

// MARK: - Animated Slide In Modifier
struct AnimatedSlideIn: ViewModifier {
    let edge: Edge
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .offset(
                x: isVisible ? 0 : (edge == .leading || edge == .trailing ? (edge == .leading ? -30 : 30) : 0),
                y: isVisible ? 0 : (edge == .top || edge == .bottom ? (edge == .top ? -30 : 30) : 0)
            )
            .opacity(isVisible ? 1 : 0)
            .animation(AnimationHelper.slideIn(from: edge, delay: delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

// MARK: - Bounce Modifier
struct BounceOnAppear: ViewModifier {
    let delay: Double
    @State private var scale: CGFloat = 0.8

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(AnimationHelper.bouncy.delay(delay), value: scale)
            .onAppear {
                scale = 1.0
            }
    }
}

// MARK: - Shimmer Modifier (for loading states)
struct ShimmerEffect: ViewModifier {
    @State private var phase = 0.0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.5)
                        .offset(x: phase * geometry.size.width * 1.5)
                        .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                phase = 1
                            }
                        }
                }
            )
            .clipped()
    }
}

// MARK: - View Extensions for Animations
extension View {
    /// Adds fade-in and scale animation on appear
    func animatedAppear(delay: Double = 0) -> some View {
        self.modifier(AnimatedAppear(delay: delay))
    }

    /// Adds slide-in animation on appear
    func animatedSlideIn(from edge: Edge = .bottom, delay: Double = 0) -> some View {
        self.modifier(AnimatedSlideIn(edge: edge, delay: delay))
    }

    /// Adds bounce animation on appear
    func bounceOnAppear(delay: Double = 0) -> some View {
        self.modifier(BounceOnAppear(delay: delay))
    }

    /// Adds shimmer effect (useful for loading states)
    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
}

// MARK: - Preview
#Preview("Animation Helpers") {
    VStack(spacing: 24) {
        Text("Animated Appear")
            .font(.headline)
            .animatedAppear()

        Text("Slide from Bottom")
            .font(.headline)
            .animatedSlideIn(from: .bottom, delay: 0.1)

        Text("Slide from Leading")
            .font(.headline)
            .animatedSlideIn(from: .leading, delay: 0.2)

        Text("Bounce")
            .font(.headline)
            .bounceOnAppear(delay: 0.3)

        HStack(spacing: 16) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(AppColor.primary)
                    .frame(width: 40, height: 40)
                    .animatedAppear(delay: Double(index) * 0.1)
            }
        }

        Text("Shimmer Loading")
            .font(.headline)
            .padding()
            .background(AppColor.cardBackground)
            .cornerRadius(12)
            .shimmer()
    }
    .padding()
    .background(AppColor.background)
}
