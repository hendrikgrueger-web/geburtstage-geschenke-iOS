import XCTest
import SwiftData
@testable import aiPresentsApp

/// Edge-Cases fuer den Daten-Export — die Faelle die ChatGPT/normale Tests
/// uebersehen wuerden, aber im Echtbetrieb auftreten:
/// - Orphaned GiftIdea (Person existiert nicht mehr)
/// - Sehr lange `note` (Bandwidth-Schutz)
/// - `budgetMin > budgetMax` (Datenkonsistenz)
/// - Leere `statusLog` und `tags` und `hobbies`
/// - Multi-Person mit gleicher displayName aber verschiedenen IDs
@MainActor
final class DataExportEdgeCasesTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self, SuggestionFeedback.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - 1. Orphaned GiftIdea

    func testExport_orphanedGiftIdea_includedDespiteMissingPerson() throws {
        // Realistic case: Person wurde geloescht, aber GiftIdea-Cascade hat
        // sie noch nicht entfernt (CloudKit-Race), oder GiftIdea zeigt auf
        // eine personId die nie existierte.
        let container = try makeContainer()
        let orphanPersonId = UUID()  // Diese Person wird NIE eingefuegt
        let idea = GiftIdea(personId: orphanPersonId, title: "Orphan-Idee")
        container.mainContext.insert(idea)

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let ideas = json?["giftIdeas"] as? [[String: Any]] ?? []

        XCTAssertEqual(ideas.count, 1, "Orphaned Idea muss exportiert werden — User koennte sie spaeter zuordnen")
        XCTAssertEqual(ideas.first?["personId"] as? String, orphanPersonId.uuidString)
    }

    // MARK: - 2. Sehr grosse Datenfelder

    func testExport_veryLongNote_doesNotTruncate() throws {
        let container = try makeContainer()
        let person = PersonRef(contactIdentifier: "p", displayName: "P", birthday: Date())
        container.mainContext.insert(person)

        let veryLongNote = String(repeating: "Dies ist eine sehr lange Notiz mit Umlauten ää öö üü. ", count: 200)
        XCTAssertGreaterThan(veryLongNote.count, 5000)
        let idea = GiftIdea(personId: person.id, title: "Mit langer Note", note: veryLongNote)
        container.mainContext.insert(idea)

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let exportedNote = (json?["giftIdeas"] as? [[String: Any]])?.first?["note"] as? String

        XCTAssertEqual(exportedNote?.count, veryLongNote.count, "Note darf nicht truncated werden")
    }

    // MARK: - 3. Inkonsistente Budget-Werte

    func testExport_budgetMinGreaterThanMax_preservedAsIs() throws {
        // Datenintegritaet ist Sache der UI, nicht des Exporters.
        // Export muss exakt das wiedergeben, was im Model steht.
        let container = try makeContainer()
        let person = PersonRef(contactIdentifier: "p", displayName: "P", birthday: Date())
        container.mainContext.insert(person)
        let idea = GiftIdea(personId: person.id, title: "Inkonsistent",
                           budgetMin: 100.0, budgetMax: 50.0)
        container.mainContext.insert(idea)

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let g = (json?["giftIdeas"] as? [[String: Any]])?.first

        XCTAssertEqual(g?["budgetMin"] as? Double, 100.0)
        XCTAssertEqual(g?["budgetMax"] as? Double, 50.0,
                      "Export bewahrt inkonsistente Werte — UI verantwortet Validierung")
    }

    // MARK: - 4. Leere Sammlungen

    func testExport_emptyHobbiesAndTagsAndStatusLog_serializedAsEmptyArrays() throws {
        let container = try makeContainer()
        let person = PersonRef(contactIdentifier: "p", displayName: "P", birthday: Date())
        // hobbies absichtlich nicht gesetzt -> default []
        container.mainContext.insert(person)
        let idea = GiftIdea(personId: person.id, title: "Leer")
        container.mainContext.insert(idea)

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let p = (json?["people"] as? [[String: Any]])?.first
        XCTAssertEqual((p?["hobbies"] as? [String])?.count, 0, "hobbies leer = []")

        let g = (json?["giftIdeas"] as? [[String: Any]])?.first
        XCTAssertEqual((g?["tags"] as? [String])?.count, 0)
        XCTAssertEqual((g?["statusLog"] as? [String])?.count, 0)
    }

    // MARK: - 5. Multi-Person mit gleichem Namen

    func testExport_multiplePersonsWithSameDisplayName_uniqueIds() throws {
        let container = try makeContainer()
        let p1 = PersonRef(contactIdentifier: "id-1", displayName: "Anna", birthday: Date())
        let p2 = PersonRef(contactIdentifier: "id-2", displayName: "Anna", birthday: Date())
        container.mainContext.insert(p1)
        container.mainContext.insert(p2)

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let people = json?["people"] as? [[String: Any]] ?? []

        XCTAssertEqual(people.count, 2)
        let ids = Set(people.compactMap { $0["id"] as? String })
        XCTAssertEqual(ids.count, 2, "IDs muessen unique bleiben auch bei gleichem Namen")
    }

    // MARK: - 6. Multi-Currency-Mix

    func testExport_giftHistoryWithVariousYears_allPreserved() throws {
        let container = try makeContainer()
        let person = PersonRef(contactIdentifier: "p", displayName: "P", birthday: Date())
        container.mainContext.insert(person)

        let years = [2020, 2021, 2022, 2023, 2024, 2025, 2026]
        for year in years {
            let h = GiftHistory(
                personId: person.id, title: "Geschenk \(year)",
                category: "Test", year: year, budget: 25.0
            )
            container.mainContext.insert(h)
        }

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let history = json?["giftHistory"] as? [[String: Any]] ?? []

        XCTAssertEqual(history.count, years.count)
        let exportedYears = Set(history.compactMap { $0["year"] as? Int })
        XCTAssertEqual(exportedYears, Set(years))
    }

    // MARK: - 7. Sonderzeichen die in JSON escaped werden muessen

    func testExport_quotesAndBackslashes_escapedCorrectly() throws {
        let container = try makeContainer()
        let person = PersonRef(
            contactIdentifier: "id-q",
            displayName: "Test \"mit Quotes\" und \\ Backslash",
            birthday: Date()
        )
        container.mainContext.insert(person)

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)

        // Re-Decode: muss ohne Fehler durchlaufen
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let people = decoded?["people"] as? [[String: Any]] ?? []
        let displayName = people.first?["displayName"] as? String

        XCTAssertEqual(displayName, "Test \"mit Quotes\" und \\ Backslash",
                      "Quotes/Backslash muessen verlustfrei round-trippen")
    }

    // MARK: - 8. Newlines in Notizen

    func testExport_newlinesInNote_preserved() throws {
        let container = try makeContainer()
        let person = PersonRef(contactIdentifier: "p", displayName: "P", birthday: Date())
        container.mainContext.insert(person)
        let multiLine = "Zeile 1\nZeile 2\n\nZeile 4 nach Leerzeile\nMit Tab\thier"
        let idea = GiftIdea(personId: person.id, title: "Multi-Line", note: multiLine)
        container.mainContext.insert(idea)

        let url = try DataExportService.exportAll(modelContext: container.mainContext)
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let exportedNote = (json?["giftIdeas"] as? [[String: Any]])?.first?["note"] as? String

        XCTAssertEqual(exportedNote, multiLine, "Newlines + Tabs muessen verlustfrei erhalten bleiben")
    }
}
