import XCTest
import SwiftData
@testable import aiPresentsApp

@MainActor
final class PersonRefExportTests: XCTestCase {
    var modelContext: ModelContext!
    var person: PersonRef!

    override func setUp() async throws {
        let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        modelContext = container.mainContext

        person = PersonRef(
            contactIdentifier: "test-123",
            displayName: "Max Mustermann",
            birthday: Calendar.current.date(from: DateComponents(year: 1990, month: 5, day: 15))!,
            relation: "Bruder"
        )
        modelContext.insert(person)
    }

    func testExportGiftIdeasAsCSV_Empty() {
        let csv = person.exportGiftIdeasAsCSV()

        XCTAssertTrue(csv.isEmpty)
    }

    func testExportGiftIdeasAsCSV_SingleIdea() {
        let idea = GiftIdea(
            personId: person.id,
            title: "Buch",
            note: "Thriller",
            budgetMin: 10,
            budgetMax: 20,
            link: "https://example.com/book",
            status: .idea,
            tags: ["Geburtstag", "Bücher"]
        )
        modelContext.insert(idea)

        let csv = person.exportGiftIdeasAsCSV()

        XCTAssertTrue(csv.contains("Titel,Status,Budget Min,Budget Max,Link,Tags,Notiz"))
        XCTAssertTrue(csv.contains("Buch"))
        XCTAssertTrue(csv.contains("https://example.com/book"))
        XCTAssertTrue(csv.contains("Bücher"))
    }

    func testExportGiftIdeasAsCSV_MultipleIdeas() {
        let idea1 = GiftIdea(
            personId: person.id,
            title: "Buch",
            note: "Thriller",
            budgetMin: 10,
            budgetMax: 20,
            link: "",
            status: .idea,
            tags: []
        )

        let idea2 = GiftIdea(
            personId: person.id,
            title: "Schal",
            note: "Wintergeschenk",
            budgetMin: 25,
            budgetMax: 50,
            link: "https://shop.com",
            status: .planned,
            tags: ["Mode"]
        )

        modelContext.insert(idea1)
        modelContext.insert(idea2)

        let csv = person.exportGiftIdeasAsCSV()

        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.count, 3) // Header + 2 Zeilen
        XCTAssertTrue(csv.contains("Buch"))
        XCTAssertTrue(csv.contains("Schal"))
    }

    func testExportGiftIdeasAsCSV_EscapedQuotes() {
        let idea = GiftIdea(
            personId: person.id,
            title: "Buch \"Bestseller\"",
            note: "Notiz mit \"Zitat\"",
            budgetMin: 0,
            budgetMax: 0,
            link: "",
            status: .idea,
            tags: []
        )
        modelContext.insert(idea)

        let csv = person.exportGiftIdeasAsCSV()

        XCTAssertTrue(csv.contains("Buch"))
        XCTAssertTrue(csv.contains("Bestseller"))
    }

    func testExportGiftHistoryAsCSV_Empty() {
        let csv = person.exportGiftHistoryAsCSV()

        XCTAssertTrue(csv.isEmpty)
    }

    func testExportGiftHistoryAsCSV_SingleEntry() {
        let history = GiftHistory(
            personId: person.id,
            title: "Uhr",
            category: "Elektronik",
            year: 2023,
            budget: 150,
            note: "Geburtstagsgeschenk",
            link: ""
        )
        modelContext.insert(history)

        let csv = person.exportGiftHistoryAsCSV()

        XCTAssertTrue(csv.contains("Titel,Jahr,Kategorie,Budget,Link,Notiz"))
        XCTAssertTrue(csv.contains("Uhr"))
        XCTAssertTrue(csv.contains("2023"))
        XCTAssertTrue(csv.contains("Elektronik"))
        XCTAssertTrue(csv.contains("150"))
    }

    func testExportAllGiftIdeasAsText_Empty() {
        let text = person.exportAllGiftIdeasAsText()

        XCTAssertTrue(text.contains("Keine Geschenkideen"))
    }

    func testExportAllGiftIdeasAsText_SingleIdea() {
        let idea = GiftIdea(
            personId: person.id,
            title: "Buch",
            note: "Thriller",
            budgetMin: 15,
            budgetMax: 15,
            link: "https://example.com",
            status: .idea,
            tags: ["Geburtstag"]
        )
        modelContext.insert(idea)

        let text = person.exportAllGiftIdeasAsText()

        XCTAssertTrue(text.contains("Geschenkideen für Max Mustermann"))
        XCTAssertTrue(text.contains("💡 Idee"))
        XCTAssertTrue(text.contains("Buch"))
        XCTAssertTrue(text.contains("15€"))
        XCTAssertTrue(text.contains("#Geburtstag"))
        XCTAssertTrue(text.contains("Thriller"))
        XCTAssertTrue(text.contains("https://example.com"))
    }

    func testExportAllGiftIdeasAsText_BudgetRange() {
        let idea = GiftIdea(
            personId: person.id,
            title: "Geschenk",
            note: "",
            budgetMin: 10,
            budgetMax: 30,
            link: "",
            status: .idea,
            tags: []
        )
        modelContext.insert(idea)

        let text = person.exportAllGiftIdeasAsText()

        XCTAssertTrue(text.contains("10 - 30€"))
    }

    func testExportAllGiftIdeasAsText_BudgetMaxOnly() {
        let idea = GiftIdea(
            personId: person.id,
            title: "Geschenk",
            note: "",
            budgetMin: 0,
            budgetMax: 25,
            link: "",
            status: .idea,
            tags: []
        )
        modelContext.insert(idea)

        let text = person.exportAllGiftIdeasAsText()

        XCTAssertTrue(text.contains("bis 25€"))
    }

    func testExportAllGiftIdeasAsText_MultipleIdeas() {
        let idea1 = GiftIdea(
            personId: person.id,
            title: "Buch",
            note: "",
            budgetMin: 0,
            budgetMax: 0,
            link: "",
            status: .idea,
            tags: []
        )

        let idea2 = GiftIdea(
            personId: person.id,
            title: "Schal",
            note: "",
            budgetMin: 0,
            budgetMax: 0,
            link: "",
            status: .planned,
            tags: []
        )

        modelContext.insert(idea1)
        modelContext.insert(idea2)

        let text = person.exportAllGiftIdeasAsText()

        XCTAssertTrue(text.contains("💡 Idee"))
        XCTAssertTrue(text.contains("📅 Geplant"))
        XCTAssertTrue(text.contains("Buch"))
        XCTAssertTrue(text.contains("Schal"))
    }

    func testExportAllGiftIdeasAsText_StatusAllCases() {
        let statuses: [GiftStatus] = [.idea, .planned, .purchased, .given]

        for status in statuses {
            let idea = GiftIdea(
                personId: person.id,
                title: "Geschenk \(status)",
                note: "",
                budgetMin: 0,
                budgetMax: 0,
                link: "",
                status: status,
                tags: []
            )
            modelContext.insert(idea)
        }

        let text = person.exportAllGiftIdeasAsText()

        XCTAssertTrue(text.contains("💡 Idee"))
        XCTAssertTrue(text.contains("📅 Geplant"))
        XCTAssertTrue(text.contains("🛍️ Gekauft"))
        XCTAssertTrue(text.contains("✅ Verschenkt"))
    }
}
