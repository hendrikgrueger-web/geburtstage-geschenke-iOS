import SwiftUI

/// Zentrale Farb-Token für die gesamte App — Dark-Mode-adaptiv via `UIColor`-Closures.
///
/// **Farbsystem:**
/// - Primär: iOS Blue (light: #007AFF, dark: #0A84FF) — Buttons, Links, Primäre CTAs
/// - Sekundär: Soft Purple (light: #9966E5, dark: #AF7AFF) — Akzent-Elemente, Secondary CTAs
/// - Akzent: Warm Orange (light: #FF9400, dark: #FF9F0A) — Warnungen, Highlights
/// - Status: grün (success), gelb (warning), rot (danger) — für Feedback
///
/// **Dark-Mode-Adaption:** Alle dynamischen Farben nutzen `UIColor { trait in ... }` Closures,
/// die sich zur Laufzeit an das aktuelle Interface-Style anpassen. Verwende die Token-Namen
/// statt Hex-Werte direkt im Code — so können Farben zentral aktualisiert werden.
///
/// **Verwendung:** `AppColor.primary`, `AppColor.gradientBlue.gradient` bei LinearGradient, etc.
enum AppColor {
    // MARK: - Primary Colors — iOS Blue (dynamisch, Light/Dark Mode)
    static let primary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 10/255, green: 132/255, blue: 255/255, alpha: 1)   // iOS Dark Blue
            : UIColor(red: 0/255,  green: 122/255, blue: 255/255, alpha: 1)   // iOS Light Blue
    })

    // MARK: - Secondary Colors — Soft Purple (dynamisch)
    static let secondary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 175/255, green: 122/255, blue: 255/255, alpha: 1)  // Dark Purple
            : UIColor(red: 153/255, green: 102/255, blue: 229/255, alpha: 1)  // Light Purple
    })

    // MARK: - Accent Colors — Warm Orange (dynamisch)
    static let accent = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 255/255, green: 159/255, blue: 10/255,  alpha: 1)  // iOS Dark Orange
            : UIColor(red: 255/255, green: 148/255, blue: 0/255,   alpha: 1)  // iOS Light Orange
    })

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

    // MARK: - Birthday Colors (dynamisch, Light/Dark Mode)
    /// Pink — "Heute Geburtstag". Dark: leicht gedämpft für bessere Lesbarkeit auf dunklem Hintergrund.
    static let birthdayToday = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 204/255, green: 82/255,  blue: 143/255, alpha: 1)  // 80 % von (1.0, 0.4, 0.7)
            : UIColor(red: 255/255, green: 102/255, blue: 179/255, alpha: 1)  // Light: #FF66B3
    })
    /// Orange — "Bald Geburtstag". Dark: leicht gedämpft.
    static let birthdaySoon = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 204/255, green: 122/255, blue: 41/255,  alpha: 1)  // 80 % von (1.0, 0.6, 0.2)
            : UIColor(red: 255/255, green: 153/255, blue: 51/255,  alpha: 1)  // Light: #FF9933
    })
    /// Blau — "Zukünftiger Geburtstag". Dark: leicht gedämpft.
    static let birthdayUpcoming = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 61/255,  green: 143/255, blue: 204/255, alpha: 1)  // 80 % von (0.3, 0.7, 1.0)
            : UIColor(red: 77/255,  green: 179/255, blue: 255/255, alpha: 1)  // Light: #4DB3FF
    })

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
                gradient: Gradient(colors: [AppColor.birthdayToday, AppColor.danger]),
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

