import Foundation
import SwiftData

@Model
final class GiftIdea {
    var id: UUID
    var personId: UUID
    var title: String
    var note: String
    var budgetMin: Double
    var budgetMax: Double
    var link: String
    var status: GiftStatus
    var tags: [String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        personId: UUID,
        title: String,
        note: String = "",
        budgetMin: Double = 0,
        budgetMax: Double = 0,
        link: String = "",
        status: GiftStatus = .idea,
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.personId = personId
        self.title = title
        self.note = note
        self.budgetMin = budgetMin
        self.budgetMax = budgetMax
        self.link = link
        self.status = status
        self.tags = tags
        self.createdAt = createdAt
    }
}

enum GiftStatus: String, Codable, CaseIterable {
    case idea = "idea"
    case planned = "planned"
    case purchased = "purchased"
    case given = "given"
}
