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

        var csv = "Titel,Jahr,Kategorie,Budget,Link,Notiz\n"

        for item in history {
            let escapedTitle = item.title.replacingOccurrences(of: "\"", with: "\"\"")
            let year = String(item.year)
            let category = item.category.replacingOccurrences(of: "\"", with: "\"\"")
            let budget = String(format: "%.2f", item.budget)
            let link = item.link.replacingOccurrences(of: "\"", with: "\"\"")
            let note = item.note.replacingOccurrences(of: "\"", with: "\"\"").replacingOccurrences(of: "\n", with: " ")

            csv += "\"\(escapedTitle)\",\(year),\"\(category)\",\(budget),\"\(link)\",\"\(note)\"\n"
        }

        return csv
    }
}

extension PersonRef {
    func exportAllGiftIdeasAsText() -> String {
        guard let ideas = giftIdeas, !ideas.isEmpty else {
            return "Keine Geschenkideen für \(displayName)."
        }

        var text = "Geschenkideen für \(displayName):\n\n"

        for idea in ideas {
            let statusText = switch idea.status {
            case .idea: "💡 Idee"
            case .planned: "📅 Geplant"
            case .purchased: "🛍️ Gekauft"
            case .given: "✅ Verschenkt"
            }

            text += "\(statusText)\n"
            text += "\(idea.title)\n"

            if idea.budgetMin > 0 || idea.budgetMax > 0 {
                text += "Budget: "
                if idea.budgetMin == idea.budgetMax {
                    text += String(format: "%.0f€", idea.budgetMin)
                } else if idea.budgetMin == 0 {
                    text += String(format: "bis %.0f€", idea.budgetMax)
                } else {
                    text += String(format: "%.0f - %.0f€", idea.budgetMin, idea.budgetMax)
                }
                text += "\n"
            }

            if !idea.tags.isEmpty {
                text += "Tags: \(idea.tags.map { "#\($0)" }.joined(separator: " "))\n"
            }

            if !idea.note.isEmpty {
                text += "Notiz: \(idea.note)\n"
            }

            if !idea.link.isEmpty {
                text += "Link: \(idea.link)\n"
            }

            text += "\n"
        }

        return text
    }
}

extension GiftIdea {
    func exportAsText() -> String {
        var text = "🎁 \(title)\n"

        let statusText = switch status {
        case .idea: "💡 Idee"
        case .planned: "📅 Geplant"
        case .purchased: "🛍️ Gekauft"
        case .given: "✅ Verschenkt"
        }

        text += "\(statusText)\n"

        if budgetMin > 0 || budgetMax > 0 {
            if budgetMin == budgetMax {
                text += "💰 \(String(format: "%.0f€", budgetMin))\n"
            } else if budgetMin == 0 {
                text += "💰 bis \(String(format: "%.0f€", budgetMax))\n"
            } else {
                text += "💰 \(String(format: "%.0f - %.0f€", budgetMin, budgetMax))\n"
            }
        }

        if !tags.isEmpty {
            text += "🏷️ \(tags.map { "#\($0)" }.joined(separator: " "))\n"
        }

        if !note.isEmpty {
            text += "📝 \(note)\n"
        }

        if !link.isEmpty {
            text += "🔗 \(link)\n"
        }

        return text
    }
}
