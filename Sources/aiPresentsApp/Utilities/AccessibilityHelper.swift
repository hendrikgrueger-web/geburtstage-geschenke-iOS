import SwiftUI

// MARK: - Accessibility Helper
struct AccessibilityHelper {
    /// Formats a date for accessibility (e.g., "2. Januar 2026")
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = .current
        return formatter.string(from: date)
    }

    /// Formats a date difference for accessibility
    static func formatDaysUntil(_ days: Int) -> String {
        if days == 0 {
            return String(localized: "Heute")
        } else if days == 1 {
            return String(localized: "Morgen")
        } else if days < 7 {
            return String(localized: "In \(days) Tagen")
        } else if days < 30 {
            return String(localized: "In \(days) Tagen")
        } else {
            return String(localized: "\(days) Tage ab heute")
        }
    }

    /// Formats budget for accessibility
    static func formatBudget(_ min: Double, _ max: Double) -> String {
        let minStr = "\(Int(min))"
        let maxStr = "\(Int(max))"
        if min == max {
            return minStr + " " + String(localized: "Euro")
        } else if min == 0 {
            return String(localized: "bis") + " " + maxStr + " " + String(localized: "Euro")
        } else {
            return minStr + " " + String(localized: "bis") + " " + maxStr + " " + String(localized: "Euro")
        }
    }

    /// Formats tags for accessibility
    static func formatTags(_ tags: [String]) -> String {
        if tags.isEmpty {
            return String(localized: "Keine Tags")
        }
        let formatted = tags.map { "#\($0)" }.joined(separator: ", ")
        return String(localized: "Tags: \(formatted)")
    }

    /// Formats gift status for accessibility
    static func formatGiftStatus(_ status: GiftStatus) -> String {
        switch status {
        case .idea:
            return String(localized: "Geschenkidee")
        case .planned:
            return String(localized: "Geplant")
        case .purchased:
            return String(localized: "Gekauft")
        case .given:
            return String(localized: "Verschenkt")
        }
    }

    /// Creates a complete accessibility label for a gift idea
    static func giftIdeaLabel(_ idea: GiftIdea, includeStatus: Bool = true) -> String {
        var label = idea.title

        if includeStatus {
            let status = formatGiftStatus(idea.status)
            label += ", " + String(localized: "Status: \(status)")
        }

        if idea.budgetMax > 0 {
            let budget = formatBudget(idea.budgetMin, idea.budgetMax)
            label += ", " + String(localized: "Budget: \(budget)")
        }

        if !idea.tags.isEmpty {
            label += ", \(formatTags(idea.tags))"
        }

        if !idea.note.isEmpty {
            label += ", " + String(localized: "Notiz: \(idea.note)")
        }

        return label
    }

    /// Creates a complete accessibility label for a person
    static func personLabel(_ person: PersonRef, daysUntil: Int?) -> String {
        var label = person.displayName
        label += ", " + String(localized: "Beziehung: \(person.relation)")

        if let days = daysUntil {
            let daysFormatted = formatDaysUntil(days)
            label += ", " + String(localized: "Nächster Geburtstag: \(daysFormatted)")
        }

        if let giftCount = person.giftIdeas?.count, giftCount > 0 {
            let suffix = giftCount == 1
                ? String(localized: "Geschenkidee")
                : String(localized: "Geschenkideen")
            label += ", \(giftCount) \(suffix)"
        }

        return label
    }

    /// Creates a complete accessibility label for gift history
    static func giftHistoryLabel(_ history: GiftHistory) -> String {
        var label = "\(history.title), " + String(localized: "Jahr:") + " \(history.year)"
        label += ", " + String(localized: "Kategorie:") + " \(history.category)"

        if history.budget > 0 {
            let budget = formatBudget(history.budget, history.budget)
            label += ", " + String(localized: "Budget: \(budget)")
        }

        if !history.note.isEmpty {
            label += ", " + String(localized: "Notiz: \(history.note)")
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
            .accessibilityHint(hint ?? String(localized: "Doppeltippen zum Auswählen"))
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
