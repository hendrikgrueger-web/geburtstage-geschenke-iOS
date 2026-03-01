import Foundation
import SwiftData

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
    var createdAt: Date

    init(
        id: UUID = UUID(),
        personId: UUID,
        title: String,
        category: String,
        year: Int,
        budget: Double = 0,
        note: String = "",
        link: String = "",
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
        self.createdAt = createdAt
    }
}
