import Foundation

// MARK: - Enums für PersonDetailView-Filterung und -Sortierung

enum GiftSortOption: String, CaseIterable, Sendable {
    case status, budget, title, date

    var displayName: String {
        switch self {
        case .status: return String(localized: "Status")
        case .budget: return String(localized: "Budget")
        case .title: return String(localized: "Titel")
        case .date: return String(localized: "Datum")
        }
    }
}

enum GiftStatusFilter: String, CaseIterable, Sendable {
    case all, idea, planned, purchased, given

    var displayName: String {
        switch self {
        case .all: return String(localized: "Alle")
        case .idea: return String(localized: "Ideen")
        case .planned: return String(localized: "Geplant")
        case .purchased: return String(localized: "Gekauft")
        case .given: return String(localized: "Verschenkt")
        }
    }
}
