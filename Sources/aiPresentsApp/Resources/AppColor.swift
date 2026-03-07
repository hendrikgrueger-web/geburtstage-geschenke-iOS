import SwiftUI

enum AppColor {
    // MARK: - Primary Colors — iOS Blue (dynamisch, Light/Dark Mode)
    static let primary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 10/255, green: 132/255, blue: 255/255, alpha: 1)   // iOS Dark Blue
            : UIColor(red: 0/255,  green: 122/255, blue: 255/255, alpha: 1)   // iOS Light Blue
    })
    static let primaryLight = Color(red: 0.4, green: 0.7, blue: 1.0)
    static let primaryDark = Color(red: 0.0, green: 0.35, blue: 0.8)

    // MARK: - Secondary Colors — Soft Purple (dynamisch)
    static let secondary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 175/255, green: 122/255, blue: 255/255, alpha: 1)  // Dark Purple
            : UIColor(red: 153/255, green: 102/255, blue: 229/255, alpha: 1)  // Light Purple
    })
    static let secondaryLight = Color(red: 0.75, green: 0.55, blue: 0.95)

    // MARK: - Accent Colors — Warm Orange (dynamisch)
    static let accent = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 255/255, green: 159/255, blue: 10/255,  alpha: 1)  // iOS Dark Orange
            : UIColor(red: 255/255, green: 148/255, blue: 0/255,   alpha: 1)  // iOS Light Orange
    })
    static let accentLight = Color(red: 1.0, green: 0.75, blue: 0.3)

    // MARK: - Status Colors (dynamisch)
    static let success = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 48/255,  green: 209/255, blue: 88/255,  alpha: 1)  // iOS Dark Green
            : UIColor(red: 52/255,  green: 199/255, blue: 89/255,  alpha: 1)  // iOS Light Green
    })
    static let warning = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 255/255, green: 214/255, blue: 10/255,  alpha: 1)  // iOS Dark Yellow
            : UIColor(red: 255/255, green: 204/255, blue: 0/255,   alpha: 1)  // iOS Light Yellow
    })
    static let danger = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 255/255, green: 69/255,  blue: 58/255,  alpha: 1)  // iOS Dark Red
            : UIColor(red: 255/255, green: 59/255,  blue: 48/255,  alpha: 1)  // iOS Light Red
    })
    /// Alias für Abwärtskompatibilität — neu: `AppColor.danger` verwenden
    static var error: Color { danger }

    // MARK: - Birthday Colors
    static let birthdayToday = Color(red: 1.0, green: 0.4, blue: 0.7)
    static let birthdaySoon = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let birthdayUpcoming = Color(red: 0.3, green: 0.7, blue: 1.0)

    // MARK: - Background Colors (dynamisch)
    static let background = Color(UIColor.systemGroupedBackground)
    /// Karten-Hintergrund: weiß (Light) / iOS secondarySystemBackground (Dark)
    static let cardBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 28/255, green: 28/255, blue: 30/255,  alpha: 1)    // iOS secondarySystemBackground Dark
            : UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)  // Weiß
    })
    /// Subtiler Hintergrund: iOS tertiäres System-Grau
    static let subtleBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 44/255, green: 44/255, blue: 46/255,   alpha: 1)   // iOS tertiarySystemBackground Dark
            : UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)  // iOS tertiarySystemBackground Light
    })
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
            .clipShape(.rect(cornerRadius: 12))
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

