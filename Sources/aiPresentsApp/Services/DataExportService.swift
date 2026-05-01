import Foundation
import SwiftData

/// Exportiert alle App-Daten (Personen, Geschenkideen, Geschenk-Historie) als
/// versioniertes JSON. Zweck: User-Backup vor SwiftData/CloudKit-Korruption,
/// Geräte-Wechsel ausserhalb der iCloud-Welt, App-Store-Review-Trust-Signal.
///
/// Das JSON-Schema ist versioniert (`schemaVersion`), damit ein zukuenftiger
/// Restore-Flow alte Exports parsen kann.
@MainActor
enum DataExportService {

    /// Aktuelle Schema-Version. Hochzaehlen wenn Felder hinzukommen oder
    /// die Bedeutung sich aendert.
    static let schemaVersion = 1

    /// Exportiert alle SwiftData-Inhalte als JSON-Datei in das Temp-Directory.
    /// Gibt die URL zurueck, die in einen `UIActivityViewController` gegeben wird.
    /// Datei-Name folgt `merktag-export-YYYY-MM-DD.json`.
    static func exportAll(modelContext: ModelContext) throws -> URL {
        let people = try modelContext.fetch(FetchDescriptor<PersonRef>())
        let giftIdeas = try modelContext.fetch(FetchDescriptor<GiftIdea>())
        let giftHistory = try modelContext.fetch(FetchDescriptor<GiftHistory>())

        let payload = ExportPayload(
            schemaVersion: schemaVersion,
            exportedAt: Date(),
            appVersion: Bundle.main.appVersion,
            people: people.map(PersonExport.init),
            giftIdeas: giftIdeas.map(GiftIdeaExport.init),
            giftHistory: giftHistory.map(GiftHistoryExport.init)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)

        let fileName = "merktag-export-\(Self.todayStamp()).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func todayStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
}

// MARK: - Export-DTOs (Sendable Codable Plain-Structs, vom Model entkoppelt)

private struct ExportPayload: Codable, Sendable {
    let schemaVersion: Int
    let exportedAt: Date
    let appVersion: String
    let people: [PersonExport]
    let giftIdeas: [GiftIdeaExport]
    let giftHistory: [GiftHistoryExport]
}

private struct PersonExport: Codable, Sendable {
    let id: UUID
    let contactIdentifier: String
    let displayName: String
    let birthday: Date
    let birthYearKnown: Bool
    let relation: String
    let hobbies: [String]
    let skipGift: Bool
    let updatedAt: Date

    init(_ p: PersonRef) {
        self.id = p.id
        self.contactIdentifier = p.contactIdentifier
        self.displayName = p.displayName
        self.birthday = p.birthday
        self.birthYearKnown = p.birthYearKnown
        self.relation = p.relation
        self.hobbies = p.hobbies
        self.skipGift = p.skipGift
        self.updatedAt = p.updatedAt
    }
}

private struct GiftIdeaExport: Codable, Sendable {
    let id: UUID
    let personId: UUID
    let title: String
    let note: String
    let budgetMin: Double
    let budgetMax: Double
    let link: String
    let status: String
    let tags: [String]
    let statusLog: [String]
    let createdAt: Date

    init(_ g: GiftIdea) {
        self.id = g.id
        self.personId = g.personId
        self.title = g.title
        self.note = g.note
        self.budgetMin = g.budgetMin
        self.budgetMax = g.budgetMax
        self.link = g.link
        self.status = g.status.rawValue
        self.tags = g.tags
        self.statusLog = g.statusLog
        self.createdAt = g.createdAt
    }
}

private struct GiftHistoryExport: Codable, Sendable {
    let id: UUID
    let personId: UUID
    let title: String
    let category: String
    let year: Int
    let budget: Double
    let note: String
    let link: String
    let direction: String
    let createdAt: Date

    init(_ h: GiftHistory) {
        self.id = h.id
        self.personId = h.personId
        self.title = h.title
        self.category = h.category
        self.year = h.year
        self.budget = h.budget
        self.note = h.note
        self.link = h.link
        self.direction = h.direction
        self.createdAt = h.createdAt
    }
}

// MARK: - Bundle-Helper

private extension Bundle {
    var appVersion: String {
        let short = (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?"
        let build = (infoDictionary?["CFBundleVersion"] as? String) ?? "?"
        return "\(short) (\(build))"
    }
}
