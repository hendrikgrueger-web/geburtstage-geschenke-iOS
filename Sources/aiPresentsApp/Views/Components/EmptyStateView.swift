import SwiftUI

enum EmptyStateType {
    case noBirthdays
    case noGiftIdeas
    case noHistory
    case noSearchResults
    case noContacts

    var iconName: String {
        switch self {
        case .noBirthdays: return "giftcard"
        case .noGiftIdeas: return "lightbulb"
        case .noHistory: return "clock.arrow.circlepath"
        case .noSearchResults: return "magnifyingglass"
        case .noContacts: return "person.crop.circle.badge.xmark"
        }
    }

    var title: String {
        switch self {
        case .noBirthdays: return "Keine Geburtstage"
        case .noGiftIdeas: return "Keine Geschenkideen"
        case .noHistory: return "Kein Verlauf"
        case .noSearchResults: return "Keine Ergebnisse"
        case .noContacts: return "Keine Kontakte"
        }
    }

    var message: String {
        switch self {
        case .noBirthdays: return "Importiere Kontakte um Geburtstage anzuzeigen"
        case .noGiftIdeas: return "Füge deine erste Geschenkidee hinzu"
        case .noHistory: return "Dein Geschenk-Verlauf erscheint hier"
        case .noSearchResults: return "Versuche andere Suchbegriffe"
        case .noContacts: return "Importiere Kontakte mit Geburtstagen"
        }
    }

    var actionTitle: String? {
        switch self {
        case .noBirthdays: return "Kontakte importieren"
        case .noGiftIdeas: return "Idee hinzufügen"
        case .noHistory: return nil
        case .noSearchResults: return nil
        case .noContacts: return "Kontakte importieren"
        }
    }
}

struct EmptyStateView: View {
    let type: EmptyStateType
    let action: (() -> Void)?

    init(type: EmptyStateType, action: (() -> Void)? = nil) {
        self.type = type
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            // Icon with animation
            iconView

            // Title and message
            VStack(spacing: 8) {
                Text(type.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColor.textPrimary)

                Text(type.message)
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Action button
            if let actionTitle = type.actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .buttonStyle(.pressable())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.title). \(type.message)")
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(type.color.opacity(0.15))
                .frame(width: 120, height: 120)

            Image(systemName: type.iconName)
                .font(.system(size: 50))
                .foregroundColor(type.color)
                .symbolEffect(.bounce, options: .repeating, isActive: true)
        }
    }

    private var color: Color {
        switch type {
        case .noBirthdays: return AppColor.secondary
        case .noGiftIdeas: return AppColor.primary
        case .noHistory: return .gray
        case .noSearchResults: return .orange
        case .noContacts: return .red
        }
    }
}

// MARK: - Convenience Initializers

extension EmptyStateView {
    static func noBirthdays(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(type: .noBirthdays, action: action)
    }

    static func noGiftIdeas(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(type: .noGiftIdeas, action: action)
    }

    static func noHistory() -> EmptyStateView {
        EmptyStateView(type: .noHistory)
    }

    static func noSearchResults() -> EmptyStateView {
        EmptyStateView(type: .noSearchResults)
    }

    static func noContacts(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(type: .noContacts, action: action)
    }
}

#Preview {
    EmptyStateView(type: .noGiftIdeas, action: {})
}
