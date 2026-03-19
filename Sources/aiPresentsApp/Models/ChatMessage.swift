import Foundation

/// In-Memory Chat-Nachricht (nicht persistiert).
struct ChatMessage: Identifiable, Equatable, Sendable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date
    let action: ChatAction?

    enum Role: String, Sendable {
        case user
        case assistant
        case system
    }

    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date(), action: ChatAction? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.action = action
    }
}

// MARK: - Chat-Aktionen

/// Strukturierte Aktion, die die KI als Teil ihrer Antwort zurückgibt.
struct ChatAction: Equatable, Sendable {
    let type: ActionType
    let data: ActionData?

    enum ActionType: String, Codable, Sendable {
        case createGiftIdea = "create_gift_idea"
        case query = "query"
        case updateGiftStatus = "update_gift_status"
        case openSuggestions = "open_suggestions"
        case clarifyPerson = "clarify_person"
        case offTopic = "off_topic"
        case none = "none"
    }
}

/// Daten einer Chat-Aktion (je nach Typ unterschiedlich befüllt).
struct ActionData: Equatable, Sendable {
    let personId: String?
    let personName: String?
    let giftTitle: String?
    let giftNote: String?
    let newStatus: String?
    let giftIdeaId: String?
}

// MARK: - API Response Parsing

/// JSON-Format das die KI zurückgibt.
struct ChatResponseJSON: Codable, Sendable {
    let message: String
    let action: ChatActionJSON?
}

struct ChatActionJSON: Codable, Sendable {
    let type: String
    let personId: String?
    let personName: String?
    let giftTitle: String?
    let giftNote: String?
    let newStatus: String?
    let giftIdeaId: String?

    enum CodingKeys: String, CodingKey {
        case type
        case personId = "person_id"
        case personName = "person_name"
        case giftTitle = "gift_title"
        case giftNote = "gift_note"
        case newStatus = "new_status"
        case giftIdeaId = "gift_idea_id"
    }
}
