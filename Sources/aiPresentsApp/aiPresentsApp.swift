import SwiftUI
import SwiftData

@main
struct aiPresentsApp: App {
    let modelContainer: ModelContainer
    @StateObject private var reminderManager: ReminderManager

    init() {
        do {
            let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self])

            // CloudKit configuration
            let config = ModelConfiguration(
                identifier: "ai-presents-app",
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .automatic
            )

            modelContainer = try ModelContainer(for: schema, configurations: [config])

            let manager = ReminderManager(modelContext: modelContainer.mainContext)
            _reminderManager = StateObject(wrappedValue: manager)
        } catch {
            // Fallback to local-only if CloudKit fails
            do {
                let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self])
                let config = ModelConfiguration(isStoredInMemoryOnly: false, cloudKitDatabase: nil)
                modelContainer = try ModelContainer(for: schema, configurations: [config])

                let manager = ReminderManager(modelContext: modelContainer.mainContext)
                _reminderManager = StateObject(wrappedValue: manager)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    Task {
                        await reminderManager.scheduleAllReminders()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
