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
    var skipGift: Bool = false
    /// Hobbies und Interessen der Person (max. 10 Einträge).
    /// Fließen in den KI-Prompt ein, um bessere Geschenkvorschläge zu generieren.
    var hobbies: [String] = []

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

    // Export gift ideas as CSV
    func exportGiftIdeasAsCSV() -> String {
        guard let ideas = giftIdeas, !ideas.isEmpty else {
            return ""
        }

        var csv = "Titel,Status,Budget Min,Budget Max,Link,Tags,Notiz\n"

        for idea in ideas {
            let escapedTitle = idea.title.replacingOccurrences(of: "\"", with: "\"\"")
            let status = idea.status.rawValue
            let budgetMin = String(format: "%.2f", idea.budgetMin)
            let budgetMax = String(format: "%.2f", idea.budgetMax)
            let link = idea.link.replacingOccurrences(of: "\"", with: "\"\"")
            let tags = idea.tags.joined(separator: "; ").replacingOccurrences(of: "\"", with: "\"\"")
            let note = idea.note.replacingOccurrences(of: "\"", with: "\"\"").replacingOccurrences(of: "\n", with: " ")

            csv += "\"\(escapedTitle)\",\(status),\(budgetMin),\(budgetMax),\"\(link)\",\"\(tags)\",\"\(note)\"\n"
        }

        return csv
    }

    // Export gift history as CSV
    func exportGiftHistoryAsCSV() -> String {
        guard let history = giftHistory, !history.isEmpty else {
            return ""
        }

        var csv = "Titel,Jahr,Kategorie,Budget,Richtung,Link,Notiz\n"

        for item in history {
            let escapedTitle = item.title.replacingOccurrences(of: "\"", with: "\"\"")
            let year = String(item.year)
            let category = item.category.replacingOccurrences(of: "\"", with: "\"\"")
            let budget = String(format: "%.2f", item.budget)
            let direction = item.giftDirection.displayName
            let link = item.link.replacingOccurrences(of: "\"", with: "\"\"")
            let note = item.note.replacingOccurrences(of: "\"", with: "\"\"").replacingOccurrences(of: "\n", with: " ")

            csv += "\"\(escapedTitle)\",\(year),\"\(category)\",\(budget),\"\(direction)\",\"\(link)\",\"\(note)\"\n"
        }

        return csv
    }
}

