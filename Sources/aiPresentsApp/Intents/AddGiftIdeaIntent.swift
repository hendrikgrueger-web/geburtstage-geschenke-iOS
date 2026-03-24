import AppIntents
import StoreKit
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
        guard await hasFullAccess() else {
            return .result(dialog: IntentDialog(stringLiteral: String(localized: "Upgrade für vollen Zugriff")))
        }

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
        await WidgetDataService.shared.updateWidgetData(from: context)

        let dialogText = String(localized: "'\(giftTitle)' als Geschenkidee für \(person.displayName) eingetragen!")
        return .result(dialog: IntentDialog(stringLiteral: dialogText))
    }

    private nonisolated func hasFullAccess() async -> Bool {
        let productIDs = Set(SubscriptionManager.ProductID.allCases.map(\.rawValue))
        var purchasedProductIDs: Set<String> = []
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if productIDs.contains(transaction.productID) {
                purchasedProductIDs.insert(transaction.productID)
            }
        }

        return SubscriptionAccessPolicy.hasFullAccess(
            purchasedProductIDs: purchasedProductIDs,
            trialStartDate: SubscriptionAccessPolicy.trialStartDate()
        )
    }
}
