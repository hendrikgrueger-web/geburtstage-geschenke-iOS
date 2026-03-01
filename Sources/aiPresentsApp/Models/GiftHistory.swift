import Foundation
import SwiftData

@Model
final class GiftHistory {
    var id: UUID
    var personId: UUID
    var title: String
    var category: String
    var year: Int

    init(
        id: UUID = UUID(),
        personId: UUID,
        title: String,
        category: String,
        year: Int
    ) {
        self.id = id
        self.personId = personId
        self.title = title
        self.category = category
        self.year = year
    }
}
