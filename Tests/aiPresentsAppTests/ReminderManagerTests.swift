import XCTest
import SwiftData
@testable import aiPresentsApp

@MainActor
final class ReminderManagerTests: XCTestCase {
    var modelContext: ModelContext!
    var reminderManager: ReminderManager!

    override func setUp() async throws {
        let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self, SuggestionFeedback.self])
        // SwiftData In-Memory Container kollidiert mit TEST_HOST App-Container im Simulator
        throw XCTSkip("SwiftData ModelContainer conflicts with TEST_HOST — requires standalone test target")
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        modelContext = container.mainContext
        reminderManager = ReminderManager(modelContext: modelContext)
    }

    func testReminderRuleDefaultValues() {
        let rule = ReminderRule()

        XCTAssertEqual(rule.leadDays, [30, 14, 7, 2])
        XCTAssertEqual(rule.quietHoursStart, 22)
        XCTAssertEqual(rule.quietHoursEnd, 8)
        XCTAssertTrue(rule.enabled)
    }

    func testReminderRuleCustomValues() {
        let rule = ReminderRule(
            leadDays: [60, 30, 7],
            quietHoursStart: 20,
            quietHoursEnd: 10,
            enabled: false
        )

        XCTAssertEqual(rule.leadDays, [60, 30, 7])
        XCTAssertEqual(rule.quietHoursStart, 20)
        XCTAssertEqual(rule.quietHoursEnd, 10)
        XCTAssertFalse(rule.enabled)
    }

    func testReminderRuleWithEmptyLeadDays() {
        let rule = ReminderRule(
            leadDays: [],
            quietHoursStart: 22,
            quietHoursEnd: 8,
            enabled: true
        )

        XCTAssertTrue(rule.leadDays.isEmpty)
    }

    func testReminderRuleStorage() {
        let rule = ReminderRule(
            leadDays: [14, 7],
            quietHoursStart: 21,
            quietHoursEnd: 9,
            enabled: true
        )

        modelContext.insert(rule)

        let descriptor = FetchDescriptor<ReminderRule>()
        let fetchedRules = try? modelContext.fetch(descriptor)

        XCTAssertNotNil(fetchedRules)
        XCTAssertEqual(fetchedRules?.count, 1)
        XCTAssertEqual(fetchedRules?.first?.leadDays, [14, 7])
        XCTAssertEqual(fetchedRules?.first?.quietHoursStart, 21)
        XCTAssertEqual(fetchedRules?.first?.quietHoursEnd, 9)
        XCTAssertTrue(fetchedRules?.first?.enabled ?? false)
    }

    func testReminderRuleUpdate() {
        let rule = ReminderRule()
        modelContext.insert(rule)

        rule.leadDays = [30, 7]
        rule.quietHoursStart = 23
        rule.enabled = false

        let descriptor = FetchDescriptor<ReminderRule>()
        let fetchedRules = try? modelContext.fetch(descriptor)

        XCTAssertEqual(fetchedRules?.first?.leadDays, [30, 7])
        XCTAssertEqual(fetchedRules?.first?.quietHoursStart, 23)
        XCTAssertFalse(fetchedRules?.first?.enabled ?? true)
    }

    func testMultipleReminderRules() {
        let rule1 = ReminderRule(leadDays: [30], quietHoursStart: 22, quietHoursEnd: 8, enabled: true)
        let rule2 = ReminderRule(leadDays: [14], quietHoursStart: 20, quietHoursEnd: 10, enabled: false)

        modelContext.insert(rule1)
        modelContext.insert(rule2)

        let descriptor = FetchDescriptor<ReminderRule>()
        let fetchedRules = try? modelContext.fetch(descriptor)

        XCTAssertEqual(fetchedRules?.count, 2)
    }
}
