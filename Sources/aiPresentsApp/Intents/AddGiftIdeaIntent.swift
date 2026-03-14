import AppIntents
import SwiftData
import Foundation

// MARK: - AddGiftIdeaIntent

/// Trägt eine Geschenkidee für einen Kontakt direkt via Siri oder Kurzbefehle ein.
struct AddGiftIdeaIntent: AppIntent {
    static let title: LocalizedStringResource = "Geschenkidee eintragen"
    static let description: IntentDescription = IntentDescription(
        "Trägt eine Geschenkidee für einen Kontakt ein",
        categoryName: "Geschenke"
    )

    @Parameter(title: "Kontakt")
    var person: PersonEntity

    @Parameter(title: "Geschenk")
    var giftTitle: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try makeIntentsModelContainer()
        let context = ModelContext(container)

        // PersonRef per UUID laden
        let targetId = person.id
        let descriptor = FetchDescriptor<PersonRef>()
        let allPersons: [PersonRef] = try context.fetch(descriptor)

        guard let personRef = allPersons.first(where: { $0.id == targetId }) else {
            return .result(
                dialog: IntentDialog(stringLiteral: String(localized: "Kontakt konnte nicht gefunden werden."))
            )
        }

        // Neue GiftIdea anlegen und einfügen
        let newIdea = GiftIdea(
            personId: personRef.id,
            title: giftTitle,
            status: .idea
        )
        context.insert(newIdea)
        try context.save()

        let dialogText = String(localized: "'\(giftTitle)' als Geschenkidee für \(person.displayName) eingetragen!")
        return .result(dialog: IntentDialog(stringLiteral: dialogText))
    }
}
