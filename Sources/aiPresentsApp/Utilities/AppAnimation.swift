import SwiftUI

enum AppAnimation {
    // Standard transitions
    static var fadeIn: Animation {
        Animation.easeInOut(duration: 0.3)
    }

    static var fadeInFast: Animation {
        Animation.easeOut(duration: 0.2)
    }

    static var slideIn: Animation {
        Animation.spring(response: 0.4, dampingFraction: 0.8)
    }

    static var bounce: Animation {
        Animation.spring(response: 0.5, dampingFraction: 0.5)
    }

    // View modifiers
    static func fadeTransition(_ isActive: Bool) -> some View {
        Group {
            if isActive {
                EmptyView()
            }
        }
        .transition(.opacity)
    }

    static func scaleTransition(_ isActive: Bool) -> some View {
        Group {
            if isActive {
                EmptyView()
            }
        }
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }
}

extension View {
    func withFadeAnimation(_ value: Bool) -> some View {
        self
            .animation(AppAnimation.fadeIn, value: value)
    }

    func withBounceAnimation(_ value: Bool) -> some View {
        self
            .animation(AppAnimation.bounce, value: value)
    }

    func pressEffect() -> some View {
        self
            .scaleEffect(0.97)
            .animation(.easeOut(duration: 0.1), value: true)
    }
}

// Button press effect
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle {
        PressableButtonStyle()
    }
}
