import SwiftUI
import SwiftData

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Gift Idea Export Extension
extension GiftIdea {
    func exportAsText() -> String {
        var text = "🎁 \(title)\n"

        if !note.isEmpty {
            text += "📝 \(note)\n"
        }

        if budgetMax > 0 {
            text += "💰 "
            if budgetMin == budgetMax {
                text += String(format: "%.0f €", budgetMin)
            } else if budgetMin == 0 {
                text += String(format: "bis %.0f €", budgetMax)
            } else {
                text += String(format: "%.0f - %.0f €", budgetMin, budgetMax)
            }
            text += "\n"
        }

        if !link.isEmpty {
            text += "🔗 \(link)\n"
        }

        if !tags.isEmpty {
            text += "🏷️ \(tags.map { "#\($0)" }.joined(separator: " "))\n"
        }

        text += "✅ Status: \(statusText)\n"

        return text
    }

    private var statusText: String {
        switch status {
        case .idea: return String(localized: "Idee")
        case .planned: return String(localized: "Geplant")
        case .purchased: return String(localized: "Gekauft")
        case .given: return String(localized: "Verschenkt")
        }
    }
}

// MARK: - Person Export Extension
extension PersonRef {
    func exportAllGiftIdeasAsText() -> String {
        let ideas = giftIdeas?.sorted { $0.createdAt > $1.createdAt } ?? []

        if ideas.isEmpty {
            return "🎁 Keine Geschenkideen für \(displayName)"
        }

        var text = "🎁 Geschenkideen für \(displayName)\n"
        text += String(repeating: "=", count: 40) + "\n\n"

        for (index, idea) in ideas.enumerated() {
            text += "[\(index + 1)] \(idea.exportAsText())\n"
            text += String(repeating: "-", count: 30) + "\n"
        }

        return text
    }

    func exportSummaryAsText() -> String {
        let ideaCount = giftIdeas?.count ?? 0
        let purchasedCount = giftIdeas?.filter { $0.status == .purchased }.count ?? 0
        let givenCount = giftIdeas?.filter { $0.status == .given }.count ?? 0

        var text = "🎁 \(displayName)\n"
        text += "📅 \(birthdayString)\n"
        text += "👤 \(relation)\n"
        text += String(repeating: "-", count: 30) + "\n"
        text += "💡 Ideen: \(ideaCount)\n"
        text += "🛒 Gekauft: \(purchasedCount)\n"
        text += "🎉 Verschenkt: \(givenCount)\n"

        return text
    }

    private var birthdayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = .current
        return formatter.string(from: birthday)
    }
}
