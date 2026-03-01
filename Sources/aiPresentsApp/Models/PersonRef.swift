import Foundation
import SwiftData

@Model
final class PersonRef {
    var id: UUID
    var contactIdentifier: String
    var displayName: String
    var birthday: Date
    var relation: String
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var giftIdeas: [GiftIdea]?

    @Relationship(deleteRule: .cascade)
    var giftHistory: [GiftHistory]?

    init(
        id: UUID = UUID(),
        contactIdentifier: String,
        displayName: String,
        birthday: Date,
        relation: String = "Sonstige",
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.contactIdentifier = contactIdentifier
        self.displayName = displayName
        self.birthday = birthday
        self.relation = relation
        self.updatedAt = updatedAt
    }
}
