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
        case .noBirthdays: return String(localized: "Keine Geburtstage")
        case .noGiftIdeas: return String(localized: "Keine Geschenkideen")
        case .noHistory: return String(localized: "Kein Verlauf")
        case .noSearchResults: return String(localized: "Keine Ergebnisse")
        case .noContacts: return String(localized: "Keine Kontakte")
        }
    }

    var message: String {
        switch self {
        case .noBirthdays: return String(localized: "Importiere Kontakte um Geburtstage anzuzeigen")
        case .noGiftIdeas: return String(localized: "Füge deine erste Geschenkidee hinzu")
        case .noHistory: return String(localized: "Dein Geschenk-Verlauf erscheint hier")
        case .noSearchResults: return String(localized: "Versuche andere Suchbegriffe")
        case .noContacts: return String(localized: "Importiere Kontakte mit Geburtstagen")
        }
    }

    var actionTitle: String? {
        switch self {
        case .noBirthdays: return String(localized: "Kontakte importieren")
        case .noGiftIdeas: return String(localized: "Idee hinzufügen")
        case .noHistory: return nil
        case .noSearchResults: return nil
        case .noContacts: return String(localized: "Kontakte importieren")
        }
    }

    var actionIcon: String {
        switch self {
        case .noBirthdays: return "person.badge.plus"
        case .noGiftIdeas: return "plus.circle.fill"
        case .noHistory: return "plus.circle"
        case .noSearchResults: return "magnifyingglass"
        case .noContacts: return "person.badge.plus"
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
        ContentUnavailableView {
            Label(type.title, systemImage: type.iconName)
        } description: {
            Text(type.message)
        } actions: {
            if let actionTitle = type.actionTitle, let action = action {
                Button(action: action) {
                    Label(actionTitle, systemImage: type.actionIcon)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.title). \(type.message)")
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
