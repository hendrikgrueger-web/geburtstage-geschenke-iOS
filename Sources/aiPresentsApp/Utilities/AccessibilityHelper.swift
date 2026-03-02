import SwiftUI

// MARK: - Accessibility Helper
struct AccessibilityHelper {
    /// Formats a date for accessibility (e.g., "2. Januar 2026")
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }

    /// Formats a date difference for accessibility
    static func formatDaysUntil(_ days: Int) -> String {
        if days == 0 {
            return "Heute"
        } else if days == 1 {
            return "Morgen"
        } else if days < 7 {
            return "In \(days) Tagen"
        } else if days < 30 {
            return "In \(days) Tagen"
        } else {
            return "\(days) Tage ab heute"
        }
    }

    /// Formats budget for accessibility
    static func formatBudget(_ min: Double, _ max: Double) -> String {
        if min == max {
            return String(format: "%.0f Euro", min)
        } else if min == 0 {
            return String(format: "bis %.0f Euro", max)
        } else {
            return String(format: "%.0f bis %.0f Euro", min, max)
        }
    }

    /// Formats tags for accessibility
    static func formatTags(_ tags: [String]) -> String {
        if tags.isEmpty {
            return "Keine Tags"
        }
        let formatted = tags.map { "#\($0)" }.joined(separator: ", ")
        return "Tags: \(formatted)"
    }

    /// Formats gift status for accessibility
    static func formatGiftStatus(_ status: GiftStatus) -> String {
        switch status {
        case .idea:
            return "Geschenkidee"
        case .planned:
            return "Geplant"
        case .purchased:
            return "Gekauft"
        case .given:
            return "Verschenkt"
        }
    }

    /// Creates a complete accessibility label for a gift idea
    static func giftIdeaLabel(_ idea: GiftIdea, includeStatus: Bool = true) -> String {
        var label = idea.title

        if includeStatus {
            label += ", Status: \(formatGiftStatus(idea.status))"
        }

        if idea.budgetMax > 0 {
            label += ", Budget: \(formatBudget(idea.budgetMin, idea.budgetMax))"
        }

        if !idea.tags.isEmpty {
            label += ", \(formatTags(idea.tags))"
        }

        if !idea.note.isEmpty {
            label += ", Notiz: \(idea.note)"
        }

        return label
    }

    /// Creates a complete accessibility label for a person
    static func personLabel(_ person: PersonRef, daysUntil: Int?) -> String {
        var label = person.displayName
        label += ", Beziehung: \(person.relation)"

        if let days = daysUntil {
            label += ", Nächster Geburtstag: \(formatDaysUntil(days))"
        }

        if let giftCount = person.giftIdeas?.count, giftCount > 0 {
            label += ", \(giftCount) Geschenkidee\(giftCount == 1 ? "" : "n")"
        }

        return label
    }

    /// Creates a complete accessibility label for gift history
    static func giftHistoryLabel(_ history: GiftHistory) -> String {
        var label = "\(history.title), Jahr: \(history.year)"
        label += ", Kategorie: \(history.category)"

        if history.budget > 0 {
            label += ", Budget: \(formatBudget(history.budget, history.budget))"
        }

        if !history.note.isEmpty {
            label += ", Notiz: \(history.note)"
        }

        return label
    }
}

// MARK: - View Extensions for Accessibility
extension View {
    /// Adds common accessibility hints
    func accessibilityHintForButton(_ hint: String) -> some View {
        self.accessibilityHint(hint)
    }

    /// Makes view accessible as a button
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Doppeltippen zum Auswählen")
            .accessibilityAddTraits(.isButton)
    }

    /// Makes view accessible as a header
    func accessibleHeader(_ text: String) -> some View {
        self
            .accessibilityLabel(text)
            .accessibilityAddTraits(.isHeader)
    }

    /// Combines child accessibility labels
    func combineAccessibility() -> some View {
        self.accessibilityElement(children: .combine)
    }
}

// MARK: - Preview
#Preview {
    VStack(alignment: .leading, spacing: 16) {
        Text("Accessibility Helper Examples")
            .font(.headline)

        Text("Date: \(AccessibilityHelper.formatDate(Date()))")
        Text("Days: \(AccessibilityHelper.formatDaysUntil(7))")
        Text("Budget: \(AccessibilityHelper.formatBudget(25, 75))")
        Text("Tags: \(AccessibilityHelper.formatTags(["Geburtstag", "Geschenk"]))")
    }
    .padding()
}
