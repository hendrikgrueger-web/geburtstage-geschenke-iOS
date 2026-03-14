import AppIntents

struct UpcomingBirthdaysIntent: AppIntent {
    static let title: LocalizedStringResource = "Nächste Geburtstage"
    static let description: LocalizedStringResource = "Zeigt die nächsten Geburtstage an"
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
