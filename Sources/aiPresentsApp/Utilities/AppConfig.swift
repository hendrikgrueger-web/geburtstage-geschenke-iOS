import Foundation
import SwiftUI

enum AppEnvironment {
    case development
    case production
}

struct AppConfig {
    static let currentEnvironment: AppEnvironment = .development

    static let isOpenRouterConfigured = false // Set to true when API key is added

    #if DEBUG
    static let isDebugBuild = true
    #else
    static let isDebugBuild = false
    #endif

    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    static var versionString: String {
        "\(appVersion) (\(buildNumber))"
    }

    // MARK: - UI Constants
    struct Budget {
        static let sliderMinimum: Double = 0
        static let sliderMaximum: Double = 500
        static let sliderStep: Double = 5
    }

    struct Timeline {
        static let defaultUpcomingDays: Int = 30
        static let todayDays: Int = 0
        static let weekDays: Int = 7
        static let monthDays: Int = 30
    }

    struct Reminder {
        static let defaultLeadDays: [Int] = [30, 14, 7, 2]
        static let defaultQuietHoursStart: Int = 22
        static let defaultQuietHoursEnd: Int = 8
    }

    struct Limits {
        static let maxTitleLength: Int = 100
        static let maxNoteLength: Int = 500
        static let maxTags: Int = 10
        static let maxTagLength: Int = 30
        static let maxCategoryLength: Int = 50
    }
}

// MARK: - Debug Helpers
#if DEBUG
struct DebugMenu {
    static func resetAllData(modelContext: ModelContext) {
        do {
            try modelContext.deleteContainer()
            print("✅ Debug: All data reset")
        } catch {
            print("❌ Debug: Failed to reset data: \(error)")
        }
    }

    static func createSampleData(modelContext: ModelContext) {
        SampleDataService.createSampleData(in: modelContext)
        print("✅ Debug: Sample data created")
    }

    static func exportDatabaseStats(modelContext: ModelContext) -> String {
        let personDescriptor = FetchDescriptor<PersonRef>()
        let ideaDescriptor = FetchDescriptor<GiftIdea>()
        let historyDescriptor = FetchDescriptor<GiftHistory>()

        let personCount = (try? modelContext.fetchCount(personDescriptor)) ?? 0
        let ideaCount = (try? modelContext.fetchCount(ideaDescriptor)) ?? 0
        let historyCount = (try? modelContext.fetchCount(historyDescriptor)) ?? 0

        return """
        📊 Database Stats:
        - People: \(personCount)
        - Gift Ideas: \(ideaCount)
        - Gift History: \(historyCount)
        """
    }

    static func logReminderStatus(modelContext: ModelContext) {
        let ruleDescriptor = FetchDescriptor<ReminderRule>()
        if let rule = try? modelContext.fetch(ruleDescriptor).first {
            print("🔔 Reminder Rule:")
            print("   - Enabled: \(rule.enabled)")
            print("   - Lead Days: \(rule.leadDays)")
            print("   - Quiet Hours: \(rule.quietHoursStart):00 - \(rule.quietHoursEnd):00")
        } else {
            print("⚠️ No reminder rule configured")
        }
    }
}
#endif

// MARK: - Test Helpers
struct TestDataGenerator {
    static func createTestPerson() -> PersonRef {
        let calendar = Calendar.current
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 3, day: 15))!

        return PersonRef(
            contactIdentifier: UUID().uuidString,
            displayName: "Max Mustermann",
            birthday: birthday,
            relation: "Freund"
        )
    }

    static func createTestGiftIdea(for person: PersonRef) -> GiftIdea {
        GiftIdea(
            personId: person.id,
            title: "Test Geschenk",
            note: "Dies ist eine Test-Notiz",
            budgetMin: 10,
            budgetMax: 50,
            link: "https://example.com",
            status: .idea,
            tags: ["test", "demo"]
        )
    }

    static func createTestReminderRule() -> ReminderRule {
        ReminderRule(
            leadDays: [30, 14, 7, 2],
            quietHoursStart: 22,
            quietHoursEnd: 8,
            enabled: true
        )
    }
}

// MARK: - Development Settings View
#if DEBUG
struct DevSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var dbStats: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Info") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(AppConfig.versionString)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Environment")
                        Spacer()
                        Text(AppConfig.currentEnvironment == .development ? "Development" : "Production")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("OpenRouter")
                        Spacer()
                        Text(AppConfig.isOpenRouterConfigured ? "✅ Configured" : "❌ Not configured")
                            .foregroundColor(AppConfig.isOpenRouterConfigured ? .green : .red)
                    }
                }

                Section("Database") {
                    Button("Show Stats") {
                        dbStats = DebugMenu.exportDatabaseStats(modelContext: modelContext)
                    }

                    if !dbStats.isEmpty {
                        Text(dbStats)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }

                    Button(role: .destructive) {
                        DebugMenu.resetAllData(modelContext: modelContext)
                    } label: {
                        Text("Reset All Data")
                    }

                    Button {
                        DebugMenu.createSampleData(modelContext: modelContext)
                    } label: {
                        Text("Create Sample Data")
                    }
                }

                Section("Reminders") {
                    Button {
                        DebugMenu.logReminderStatus(modelContext: modelContext)
                    } label: {
                        Text("Log Reminder Status to Console")
                    }
                }
            }
            .navigationTitle("Dev Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
#endif
