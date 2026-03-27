import SwiftUI

struct LaunchScreen: View {
    @State private var isAnimating = false
    @State private var showText = false

    var body: some View {
        ZStack {
            // Background gradient
            AppColor.gradientBlue
                .ignoresSafeArea()

            // Decorative elements
            if isAnimating {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .opacity(isAnimating ? 0 : 0.5)
                    .animation(.easeOut(duration: 1.2), value: isAnimating)
                    .accessibilityHidden(true)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 150, height: 150)
                    .scaleEffect(isAnimating ? 1.8 : 1.0)
                    .opacity(isAnimating ? 0 : 0.3)
                    .animation(.easeOut(duration: 1.0).delay(0.2), value: isAnimating)
                    .accessibilityHidden(true)
            }

            // Main content
            VStack(spacing: 24) {
                // App icon/illustration
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .accessibilityHidden(true)

                    Image(systemName: "gift.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isAnimating)
                        .accessibilityHidden(true)

                    // Confetti elements
                    if isAnimating {
                        ForEach(0..<5, id: \.self) { index in
                            Image(systemName: ["sparkle", "star.fill", "heart.fill"][index % 3])
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.8))
                                .offset(x: CGFloat.random(in: -50...50), y: CGFloat.random(in: -50...50))
                                .rotationEffect(.degrees(Double.random(in: 0...360)))
                                .scaleEffect(isAnimating ? 1.0 : 0)
                                .animation(
                                    .spring(response: 0.8, dampingFraction: 0.6)
                                        .delay(Double(index) * 0.1 + 0.6),
                                    value: isAnimating
                                )
                                .accessibilityHidden(true)
                        }
                    }
                }

                // App name
                VStack(spacing: 8) {
                    Text("Geschenke AI")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(showText ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: showText)

                    Text("Geburtstage & Geschenkideen")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(showText ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: showText)
                }
            }
        }
        .onAppear {
            // Start animations
            withAnimation {
                isAnimating = true
            }

            // Show text after delay
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.4))
                withAnimation {
                    showText = true
                }
            }
        }
    }
}

#Preview {
    LaunchScreen()
}
