import AppIntents
import SwiftData
import Foundation

// MARK: - UpcomingBirthdaysIntent

/// Zeigt die nächsten Geburtstage aus der App — nutzbar via Siri und Kurzbefehle.
struct UpcomingBirthdaysIntent: AppIntent {
    static let title: LocalizedStringResource = "Nächste Geburtstage"
    static let description: IntentDescription = IntentDescription(
        "Zeigt wer bald Geburtstag hat",
        categoryName: "Geburtstage"
    )

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try makeIntentsModelContainer()
        let context = ModelContext(container)

        let allPersons: [PersonRef] = try context.fetch(FetchDescriptor<PersonRef>())

        // Sortiert nach Tagen bis zum nächsten Geburtstag (aufsteigend)
        let sorted = allPersons
            .compactMap { person -> (PersonRef, Int)? in
                guard let days = BirthdayCalculator.daysUntilBirthday(for: person.birthday) else {
                    return nil
                }
                return (person, days)
            }
            .sorted { $0.1 < $1.1 }

        guard !sorted.isEmpty else {
            return .result(
                dialog: IntentDialog(stringLiteral: String(localized: "Du hast noch keine Kontakte in der App."))
            )
        }

        // Top 5 Personen formatieren
        let top5 = sorted.prefix(5)
        let parts: [String] = top5.map { person, days in
            if days == 0 {
                return String(localized: "\(person.displayName) (\(person.relation)) hat heute Geburtstag!")
            } else if days == 1 {
                return String(localized: "\(person.displayName) (\(person.relation)) morgen")
            } else {
                return String(localized: "\(person.displayName) (\(person.relation)) in \(days) Tagen")
            }
        }

        let dialogText = parts.joined(separator: ", ")
        return .result(dialog: IntentDialog(stringLiteral: dialogText))
    }
}
