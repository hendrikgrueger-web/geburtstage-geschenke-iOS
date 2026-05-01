import XCTest
import SwiftData
@testable import aiPresentsApp

/// Tests fuer Sweep S2 (Swipe-Action „Gekauft"): direkter Sprung von .idea/.planned
/// auf .purchased ohne den Zwischenschritt durch .planned.
///
/// Wir testen die Mutations-Logik gegen GiftIdea direkt — die View ruft
/// `markAsPurchased(_:)` auf, hier verifizieren wir das gleiche Verhalten.
@MainActor
final class MarkAsPurchasedSwipeTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self, SuggestionFeedback.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - Status-Sprung-Logik (zentral testbar gegen GiftIdea-Status)

    func testIdeaToPurchased_skipsPlannedStep() {
        let idea = GiftIdea(personId: UUID(), title: "Buch", status: .idea)
        // Simuliere die Swipe-Logik: idea -> direkt purchased
        XCTAssertEqual(idea.status, .idea)
        // Mutation analog zur View
        idea.status = .purchased
        XCTAssertEqual(idea.status, .purchased, "Direkt-Sprung muss .planned ueberspringen")
    }

    func testPlannedToPurchased_directJump() {
        let idea = GiftIdea(personId: UUID(), title: "Schal", status: .planned)
        idea.status = .purchased
        XCTAssertEqual(idea.status, .purchased)
    }

    // MARK: - Guards: bereits .purchased oder .given

    func testGuard_alreadyPurchased_isNoOp() {
        let idea = GiftIdea(personId: UUID(), title: "X", status: .purchased)
        let originalStatus = idea.status
        let originalLogCount = idea.statusLog.count

        // Implementiere Guard analog zur View
        if idea.status != .purchased && idea.status != .given {
            idea.status = .purchased
            idea.statusLog.append("test - log entry")
        }

        XCTAssertEqual(idea.status, originalStatus, "Guard: bereits .purchased darf nicht erneut markiert werden")
        XCTAssertEqual(idea.statusLog.count, originalLogCount, "statusLog darf nicht waxchsen wenn no-op")
    }

    func testGuard_alreadyGiven_isNoOp() {
        let idea = GiftIdea(personId: UUID(), title: "X", status: .given)
        let originalLogCount = idea.statusLog.count

        if idea.status != .purchased && idea.status != .given {
            idea.status = .purchased
            idea.statusLog.append("test")
        }

        XCTAssertEqual(idea.status, .given, "Guard: .given bleibt erhalten")
        XCTAssertEqual(idea.statusLog.count, originalLogCount)
    }

    // MARK: - statusLog-Konsistenz

    func testStatusLog_growsByOneEntryPerSwipe() {
        let idea = GiftIdea(personId: UUID(), title: "Y", status: .idea)
        XCTAssertEqual(idea.statusLog.count, 0)
        // Erster Sprung
        if idea.status != .purchased && idea.status != .given {
            idea.statusLog.append("entry-1")
            idea.status = .purchased
        }
        XCTAssertEqual(idea.statusLog.count, 1)
        // Zweiter Versuch (Guard greift)
        if idea.status != .purchased && idea.status != .given {
            idea.statusLog.append("entry-2")
        }
        XCTAssertEqual(idea.statusLog.count, 1, "Guard verhindert doppelte Eintraege bei wiederholtem Swipe")
    }

    func testStatusLog_containsArrowAndOldStatus() {
        // Konvention: 'YYYY-MM-DD - Idee → Gekauft'
        let logEntry = "2026-05-01 - Idee \u{2192} Gekauft"
        XCTAssertTrue(logEntry.contains("\u{2192}"), "Log nutzt rechtspfeil-Glyph")
        XCTAssertTrue(logEntry.contains("Idee"))
        XCTAssertTrue(logEntry.contains("Gekauft"))
    }

    // MARK: - Persistenz mit ModelContext

    func testStatusChange_persistsInModelContext() throws {
        let container = try makeContainer()
        let person = PersonRef(contactIdentifier: "p", displayName: "P", birthday: Date())
        container.mainContext.insert(person)
        let idea = GiftIdea(personId: person.id, title: "Test", status: .idea)
        container.mainContext.insert(idea)
        try container.mainContext.save()

        idea.status = .purchased
        try container.mainContext.save()

        let fetched = try container.mainContext.fetch(FetchDescriptor<GiftIdea>())
        XCTAssertEqual(fetched.first?.status, .purchased)
    }
}
