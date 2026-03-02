import SwiftUI

// MARK: - Pressable Button Style
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - FAB (Floating Action Button) Style
struct FABButtonStyle: ButtonStyle {
    let color: Color

    init(color: Color = AppColor.primary) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(color)
            .clipShape(Circle())
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Card Button Style
struct CardButtonStyle: ButtonStyle {
    let isDestructive: Bool

    init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isDestructive ? .red : AppColor.primary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isDestructive ? Color.red.opacity(0.1) : AppColor.primary.opacity(0.1))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Gradient Button Style
struct GradientButtonStyle: ButtonStyle {
    let gradient: LinearGradient

    init(gradient: LinearGradient = AppColor.gradientBlue) {
        self.gradient = gradient
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .fontWeight(.semibold)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(gradient)
            .cornerRadius(12)
            .shadow(color: AppColor.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - View Extensions for Button Styles
extension View {
    func pressable() -> some View {
        self.buttonStyle(PressableButtonStyle())
    }

    func fab(color: Color = AppColor.primary) -> some View {
        self.buttonStyle(FABButtonStyle(color: color))
    }

    func cardButton(isDestructive: Bool = false) -> some View {
        self.buttonStyle(CardButtonStyle(isDestructive: isDestructive))
    }

    func gradientButton(_ gradient: LinearGradient = AppColor.gradientBlue) -> some View {
        self.buttonStyle(GradientButtonStyle(gradient: gradient))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Button("Pressable") {}
            .pressable()

        Button("FAB") {}
            .fab()

        Button("Card Button") {}
            .cardButton()

        Button("Destructive Card") {}
            .cardButton(isDestructive: true)

        Button("Gradient Button") {}
            .gradientButton()
    }
    .padding()
    .background(AppColor.background)
}
