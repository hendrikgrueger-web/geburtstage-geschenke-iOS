import SwiftUI
import SwiftData

@main
struct aiPresentsApp: App {
    let modelContainer: ModelContainer
    @StateObject private var reminderManager: ReminderManager

    init() {
        // iCloud-Präferenz lesen (default: true beim ersten Start)
        let iCloudEnabled = UserDefaults.standard.object(forKey: "iCloudSyncEnabled") as? Bool ?? true
        let cloudKitDB: ModelConfiguration.CloudKitDatabase = iCloudEnabled ? .automatic : .none

        do {
            let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self, SuggestionFeedback.self])
            let config = ModelConfiguration(
                "ai-presents-app",
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: cloudKitDB
            )
            modelContainer = try ModelContainer(for: schema, configurations: [config])

            let manager = ReminderManager(modelContext: modelContainer.mainContext)
            _reminderManager = StateObject(wrappedValue: manager)
        } catch {
            // Fallback: lokal ohne CloudKit
            do {
                let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self, SuggestionFeedback.self])
                let config = ModelConfiguration("ai-presents-app-local", schema: schema,
                                               isStoredInMemoryOnly: false, cloudKitDatabase: .none)
                modelContainer = try ModelContainer(for: schema, configurations: [config])

                let manager = ReminderManager(modelContext: modelContainer.mainContext)
                _reminderManager = StateObject(wrappedValue: manager)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }

        #if DEBUG
        if CommandLine.arguments.contains("--reset-sample-data") {
            let ctx = modelContainer.mainContext
            try? ctx.delete(model: SuggestionFeedback.self)
            try? ctx.delete(model: ReminderRule.self)
            try? ctx.delete(model: GiftHistory.self)
            try? ctx.delete(model: GiftIdea.self)
            try? ctx.delete(model: PersonRef.self)
            SampleDataService.createSampleData(in: ctx)
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
        #endif
    }

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    ContentView()
                        .onAppear {
                            Task {
                                await reminderManager.scheduleAllReminders()
                            }
                        }
                } else {
                    OnboardingView()
                }
            }
        }
        .modelContainer(modelContainer)
    }
}
