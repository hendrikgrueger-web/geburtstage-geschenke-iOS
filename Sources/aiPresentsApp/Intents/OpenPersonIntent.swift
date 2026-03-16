import AppIntents
import Foundation

// MARK: - OpenPersonIntent

/// Öffnet einen Kontakt direkt in der App via Siri oder Kurzbefehle.
/// openAppWhenRun = true bringt die App in den Vordergrund.
/// Die UUID des Kontakts wird via NSUserActivity an ContentView übergeben,
/// wo deepLinkPersonID via onContinueUserActivity gesetzt wird.
struct OpenPersonIntent: AppIntent {
    static let title: LocalizedStringResource = "Kontakt öffnen"
    static let description: IntentDescription = IntentDescription(
        "Öffnet einen Kontakt in der App",
        categoryName: "Navigation"
    )
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Kontakt")
    var person: PersonEntity

    func perform() async throws -> some IntentResult & OpensIntent {
        // Die App wird via openAppWhenRun=true in den Vordergrund gebracht.
        // Der Deep-Link URL wird als Result mitgegeben — iOS öffnet ihn via onOpenURL in ContentView.
        guard let url = URL(string: "aipresents://person/\(person.id.uuidString)") else {
            throw IntentError.personNotFound
        }
        return .result(opensIntent: OpenURLIntent(url))
    }

    private enum IntentError: Error {
        case personNotFound
    }
}
