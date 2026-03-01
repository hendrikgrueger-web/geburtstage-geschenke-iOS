import SwiftUI

enum AppColor {
    static let primary = Color.blue
    static let secondary = Color.purple
    static let accent = Color.orange
    static let background = Color(UIColor.systemGroupedBackground)
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)

    static let gradientBlue = LinearGradient(
        gradient: Gradient(colors: [.blue, .purple]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientWarm = LinearGradient(
        gradient: Gradient(colors: [.orange, .pink]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func appStyle() -> some View {
        self
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
    }
}
