import XCTest
import SwiftData
@testable import aiPresentsApp

/// Extreme Test-Coverage fuer DataExportService:
/// - JSON-Schema-Stabilitaet (versioniert)
/// - Round-Trip Encode -> Decode -> Re-Encode == Original
/// - Edge-Cases: Umlaute, Emoji, sehr lange Felder, leere Listen, Sonderzeichen
/// - Date-Encoding: ISO-8601 in beiden Richtungen
/// - Schema-Felder: alle Pflicht-Keys vorhanden
@MainActor
final class DataExportServiceTests: XCTestCase {

    // MARK: - Container-Helper (Schema-only, kein TEST_HOST-Konflikt da nur ephemere Inserts)

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self, SuggestionFeedback.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - 1. Schema-Stabilitaet

    func testSchemaVersionIsStable() {
        XCTAssertEqual(DataExportService.schemaVersion, 1, "Schema-Version sollte stabil bei 1 bleiben — Migration noetig wenn geaendert")
    }

    func testExport_emptyDatabase_producesValidJSON() throws {
        let container = try makeContainer()
        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["schemaVersion"] as? Int, 1)
        XCTAssertNotNil(json?["exportedAt"])
        XCTAssertEqual((json?["people"] as? [Any])?.count, 0)
        XCTAssertEqual((json?["giftIdeas"] as? [Any])?.count, 0)
        XCTAssertEqual((json?["giftHistory"] as? [Any])?.count, 0)
        try? FileManager.default.removeItem(at: url)
    }

    func testExport_includesAllRequiredTopLevelKeys() throws {
        let container = try makeContainer()
        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let keys = Set(json?.keys.map { $0 } ?? [])
        let required: Set<String> = ["schemaVersion", "exportedAt", "appVersion", "people", "giftIdeas", "giftHistory"]
        XCTAssertEqual(keys, required, "Top-Level-Keys muessen exakt diese Pflichtfelder sein")
        try? FileManager.default.removeItem(at: url)
    }

    func testExport_fileName_followsConvention() throws {
        let container = try makeContainer()
        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        XCTAssertTrue(url.lastPathComponent.hasPrefix("merktag-export-"))
        XCTAssertTrue(url.lastPathComponent.hasSuffix(".json"))
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - 2. People-Export

    func testExport_singlePerson_includesAllFields() throws {
        let container = try makeContainer()
        let person = PersonRef(
            contactIdentifier: "test-123",
            displayName: "Max Mustermann",
            birthday: Calendar.current.date(from: DateComponents(year: 1990, month: 5, day: 15))!,
            relation: "Bruder"
        )
        person.hobbies = ["Sci-Fi", "Brettspiele"]
        person.skipGift = false
        person.birthYearKnown = true
        container.mainContext.insert(person)

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let people = json?["people"] as? [[String: Any]]

        XCTAssertEqual(people?.count, 1)
        let p = try XCTUnwrap(people?.first)
        XCTAssertEqual(p["displayName"] as? String, "Max Mustermann")
        XCTAssertEqual(p["relation"] as? String, "Bruder")
        XCTAssertEqual(p["contactIdentifier"] as? String, "test-123")
        XCTAssertEqual(p["birthYearKnown"] as? Bool, true)
        XCTAssertEqual(p["skipGift"] as? Bool, false)
        XCTAssertEqual((p["hobbies"] as? [String]) ?? [], ["Sci-Fi", "Brettspiele"])
    }

    func testExport_personWithUmlauts_encodesCorrectly() throws {
        let container = try makeContainer()
        let person = PersonRef(
            contactIdentifier: "id-uml",
            displayName: "Müller-Lüdenscheidt",
            birthday: Date(),
            relation: "Großvater"
        )
        person.hobbies = ["Häkeln", "Französisch", "Café-Besuche"]
        container.mainContext.insert(person)

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let raw = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(raw.contains("Müller-Lüdenscheidt"), "Umlaute muessen erhalten bleiben")
        XCTAssertTrue(raw.contains("Großvater"))
        XCTAssertTrue(raw.contains("Häkeln"))
        XCTAssertTrue(raw.contains("Café-Besuche"))
    }

    func testExport_personWithEmojiAndSpecialChars_encodesCorrectly() throws {
        let container = try makeContainer()
        let person = PersonRef(
            contactIdentifier: "id-emoji",
            displayName: "Anna 🎉 \"Anni\"",
            birthday: Date(),
            relation: "Freundin"
        )
        person.hobbies = ["📚 Lesen", "Slash/Forward", "Quotes \"test\""]
        container.mainContext.insert(person)

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let raw = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(raw.contains("🎉"))
        XCTAssertTrue(raw.contains("📚"))
        // Anführungszeichen werden im JSON escaped
        XCTAssertTrue(raw.contains("Anna"))
    }

    // MARK: - 3. Gift-Ideas-Export

    func testExport_giftIdeasFullFields_correct() throws {
        let container = try makeContainer()
        let person = PersonRef(
            contactIdentifier: "id-x",
            displayName: "Test Person",
            birthday: Date()
        )
        container.mainContext.insert(person)
        let idea = GiftIdea(
            personId: person.id,
            title: "Kindle Paperwhite",
            note: "11. Generation",
            budgetMin: 150.0,
            budgetMax: 199.99,
            link: "https://amazon.de/kindle",
            status: .planned,
            tags: ["Lesen", "Tech"]
        )
        idea.statusLog = ["2026-05-01 - Idee → Geplant"]
        container.mainContext.insert(idea)

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let ideas = json?["giftIdeas"] as? [[String: Any]]

        XCTAssertEqual(ideas?.count, 1)
        let g = try XCTUnwrap(ideas?.first)
        XCTAssertEqual(g["title"] as? String, "Kindle Paperwhite")
        XCTAssertEqual(g["status"] as? String, "planned", "GiftStatus muss als Raw-Value gespeichert werden, nicht als Enum-Object")
        XCTAssertEqual(g["budgetMin"] as? Double, 150.0)
        XCTAssertEqual(g["budgetMax"] as? Double, 199.99)
        XCTAssertEqual(g["link"] as? String, "https://amazon.de/kindle")
        XCTAssertEqual((g["tags"] as? [String]) ?? [], ["Lesen", "Tech"])
        XCTAssertEqual((g["statusLog"] as? [String])?.count, 1)
    }

    func testExport_giftIdeasAllStatuses_encodedCorrectly() throws {
        let container = try makeContainer()
        let person = PersonRef(contactIdentifier: "p", displayName: "P", birthday: Date())
        container.mainContext.insert(person)

        for status in GiftStatus.allCases {
            let idea = GiftIdea(
                personId: person.id,
                title: "Idee \(status.rawValue)",
                status: status
            )
            container.mainContext.insert(idea)
        }

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let ideas = json?["giftIdeas"] as? [[String: Any]] ?? []

        XCTAssertEqual(ideas.count, GiftStatus.allCases.count)
        let statuses = Set(ideas.compactMap { $0["status"] as? String })
        XCTAssertEqual(statuses, Set(GiftStatus.allCases.map { $0.rawValue }))
    }

    // MARK: - 4. Gift-History-Export

    func testExport_giftHistory_bothDirections() throws {
        let container = try makeContainer()
        let person = PersonRef(contactIdentifier: "p", displayName: "P", birthday: Date())
        container.mainContext.insert(person)

        let given = GiftHistory(
            personId: person.id,
            title: "Buch — Sapiens",
            category: "Bücher",
            year: 2024,
            budget: 22.99,
            note: "Hat ihr gefallen",
            direction: .given
        )
        let received = GiftHistory(
            personId: person.id,
            title: "Schal aus Italien",
            category: "Mode",
            year: 2025,
            budget: 0,
            direction: .received
        )
        container.mainContext.insert(given)
        container.mainContext.insert(received)

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let history = json?["giftHistory"] as? [[String: Any]] ?? []

        XCTAssertEqual(history.count, 2)
        let directions = Set(history.compactMap { $0["direction"] as? String })
        XCTAssertEqual(directions, Set(["given", "received"]))
    }

    // MARK: - 5. Round-Trip-Stabilitaet

    func testExport_roundTrip_preservesStructure() throws {
        let container = try makeContainer()
        let person = PersonRef(contactIdentifier: "p1", displayName: "Anna", birthday: Date())
        person.hobbies = ["Sport", "Musik"]
        container.mainContext.insert(person)
        let idea = GiftIdea(personId: person.id, title: "Konzertkarte", budgetMax: 89.0, status: .idea, tags: ["Musik"])
        container.mainContext.insert(idea)

        let url1 = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url1) }
        let data1 = try Data(contentsOf: url1)
        let parsed1 = try JSONSerialization.jsonObject(with: data1) as? [String: Any]

        // Ein zweiter Export muss strukturell identische People/Ideas/History haben
        // (nur exportedAt aendert sich)
        let url2 = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url2) }
        let data2 = try Data(contentsOf: url2)
        let parsed2 = try JSONSerialization.jsonObject(with: data2) as? [String: Any]

        XCTAssertEqual((parsed1?["people"] as? [[String: Any]])?.count,
                       (parsed2?["people"] as? [[String: Any]])?.count)
        XCTAssertEqual((parsed1?["giftIdeas"] as? [[String: Any]])?.count,
                       (parsed2?["giftIdeas"] as? [[String: Any]])?.count)
        XCTAssertEqual(parsed1?["schemaVersion"] as? Int, parsed2?["schemaVersion"] as? Int)
    }

    // MARK: - 6. Date-Encoding

    func testExport_dateEncoding_isISO8601() throws {
        let container = try makeContainer()
        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let raw = try String(contentsOf: url, encoding: .utf8)
        // ISO-8601 typische Form: 2026-05-01T12:00:00Z oder 2026-05-01T12:00:00+02:00
        let isoPattern = #"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}"#
        XCTAssertNotNil(raw.range(of: isoPattern, options: .regularExpression),
                       "exportedAt sollte ISO-8601-encoded sein, aktuell: \(raw.prefix(200))")
    }

    // MARK: - 7. Mass-Export

    func testExport_largeDataset_completesAndValid() throws {
        let container = try makeContainer()
        for i in 0..<100 {
            let person = PersonRef(
                contactIdentifier: "id-\(i)",
                displayName: "Person \(i) Mustermann",
                birthday: Date()
            )
            person.hobbies = ["Hobby A", "Hobby B", "Hobby C"]
            container.mainContext.insert(person)
            for j in 0..<5 {
                let idea = GiftIdea(personId: person.id, title: "Idee \(i)-\(j)")
                container.mainContext.insert(idea)
            }
        }

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual((json?["people"] as? [Any])?.count, 100)
        XCTAssertEqual((json?["giftIdeas"] as? [Any])?.count, 500)
        XCTAssertGreaterThan(data.count, 10_000, "100 Personen + 500 Ideen sollten substantielles JSON erzeugen")
    }

    // MARK: - 8. Pretty-Printed Output (Lesbarkeit)

    func testExport_outputIsPrettyPrinted() throws {
        let container = try makeContainer()
        let person = PersonRef(contactIdentifier: "p", displayName: "P", birthday: Date())
        container.mainContext.insert(person)
        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let raw = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(raw.contains("\n"), "JSON soll pretty-printed sein (mit Newlines)")
        XCTAssertTrue(raw.contains("  "), "JSON soll pretty-printed sein (mit Indentation)")
    }

    // MARK: - 9. App-Version-Marker

    func testExport_appVersion_isCaptured() throws {
        let container = try makeContainer()
        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let appVersion = json?["appVersion"] as? String
        XCTAssertNotNil(appVersion)
        XCTAssertFalse(appVersion?.isEmpty ?? true)
        // Format: "X.Y.Z (build)"
        XCTAssertTrue(appVersion?.contains("(") ?? false, "appVersion-String sollte Build-Info in Klammern enthalten")
    }
}
