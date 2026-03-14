import AppIntents

struct OpenPersonIntent: AppIntent {
    static let title: LocalizedStringResource = "Kontakt öffnen"
    static let description: LocalizedStringResource = "Öffnet einen Kontakt in der App"
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Person")
    var person: PersonEntity

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
