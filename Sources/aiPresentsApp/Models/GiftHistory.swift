import Foundation
import SwiftData

/// Richtung eines Geschenks — verschenkt oder erhalten.
/// Wird in `GiftHistory` als String gespeichert (SwiftData-kompatibel)
/// und über die computed property `giftDirection` typsicher gelesen/geschrieben.
enum GiftDirection: String, Codable, CaseIterable, Sendable {
    case given = "given"
    case received = "received"

    var displayName: String {
        switch self {
        case .given: "Verschenkt"
        case .received: "Erhalten"
        }
    }

    var localizedName: String {
        switch self {
        case .given: return String(localized: "Verschenkt")
        case .received: return String(localized: "Erhalten")
        }
    }
}

@Model
final class GiftHistory {
    var id: UUID
    var personId: UUID
    var title: String
    var category: String
    var year: Int
    var budget: Double
    var note: String
    var link: String
    // String statt Enum, weil SwiftData bei Schema-Migration robuster mit primitiven Typen umgeht
    var direction: String = "given"
    var createdAt: Date

    /// Typsicherer Zugriff auf `direction` als `GiftDirection` enum.
    /// Fallback auf `.given` falls der gespeicherte String ungültig ist.
    var giftDirection: GiftDirection {
        get { GiftDirection(rawValue: direction) ?? .given }
        set { direction = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        personId: UUID,
        title: String,
        category: String,
        year: Int,
        budget: Double = 0,
        note: String = "",
        link: String = "",
        direction: GiftDirection = .given,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.personId = personId
        self.title = title
        self.category = category
        self.year = year
        self.budget = budget
        self.note = note
        self.link = link
        self.direction = direction.rawValue
        self.createdAt = createdAt
    }
}
