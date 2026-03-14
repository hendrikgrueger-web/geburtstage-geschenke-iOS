import AppIntents

struct AddGiftIdeaIntent: AppIntent {
    static let title: LocalizedStringResource = "Geschenkidee eintragen"
    static let description: LocalizedStringResource = "Trägt eine neue Geschenkidee ein"
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Person")
    var person: PersonEntity

    @Parameter(title: "Titel")
    var title: String

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
