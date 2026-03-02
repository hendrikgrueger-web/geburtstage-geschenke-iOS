import SwiftUI

enum AppColor {
    // Primary Colors - iOS Blue inspired
    static let primary = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let primaryLight = Color(red: 0.4, green: 0.7, blue: 1.0)
    static let primaryDark = Color(red: 0.0, green: 0.35, blue: 0.8)

    // Secondary Colors - Soft Purple
    static let secondary = Color(red: 0.6, green: 0.4, blue: 0.9)
    static let secondaryLight = Color(red: 0.75, green: 0.55, blue: 0.95)

    // Accent Colors - Warm Orange
    static let accent = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let accentLight = Color(red: 1.0, green: 0.75, blue: 0.3)

    // Status Colors
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let warning = Color(red: 1.0, green: 0.7, blue: 0.0)
    static let error = Color(red: 1.0, green: 0.3, blue: 0.3)

    // Birthday Colors
    static let birthdayToday = Color(red: 1.0, green: 0.4, blue: 0.7)
    static let birthdaySoon = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let birthdayUpcoming = Color(red: 0.3, green: 0.7, blue: 1.0)

    // Background Colors
    static let background = Color(UIColor.systemGroupedBackground)
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let separator = Color(UIColor.separator)

    // Text Colors
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)

    // Gradients
    static let gradientBlue = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.0, green: 0.55, blue: 1.0),
            Color(red: 0.0, green: 0.48, blue: 1.0),
            Color(red: 0.0, green: 0.35, blue: 0.8)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientWarm = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.65, blue: 0.1),
            Color(red: 1.0, green: 0.58, blue: 0.0),
            Color(red: 1.0, green: 0.4, blue: 0.7)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientPurple = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.7, green: 0.5, blue: 1.0),
            Color(red: 0.6, green: 0.4, blue: 0.9),
            Color(red: 0.5, green: 0.3, blue: 0.8)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientSuccess = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.3, green: 0.85, blue: 0.5),
            Color(red: 0.2, green: 0.8, blue: 0.4)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientError = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.4, blue: 0.4),
            Color(red: 1.0, green: 0.3, blue: 0.3)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Special Gradients for different relations
    static func gradientForRelation(_ relation: String) -> LinearGradient {
        switch relation.lowercased() {
        case "familie", "mama", "papa", "schwester", "bruder", "tochter", "sohn":
            return gradientWarm
        case "freund", "freundin", "kollege", "kollegin":
            return gradientBlue
        case "partner", "ehepartner":
            return LinearGradient(
                gradient: Gradient(colors: [.pink, .red]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return gradientPurple
        }
    }
}

extension View {
    func appStyle() -> some View {
        self
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
    }

    func cardStyle() -> some View {
        self
            .background(AppColor.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// Gift Status Colors
extension GiftStatus {
    var color: Color {
        switch self {
        case .idea:
            return AppColor.textTertiary
        case .planned:
            return AppColor.accent
        case .purchased:
            return AppColor.primary
        case .given:
            return AppColor.success
        }
    }

    var icon: String {
        switch self {
        case .idea:
            return "lightbulb"
        case .planned:
            return "calendar"
        case .purchased:
            return "bag"
        case .given:
            return "checkmark.circle.fill"
        }
    }
}

