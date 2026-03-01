import SwiftUI
import SwiftData

@main
struct aiPresentsApp: App {
    let modelContainer: ModelContainer
    @StateObject private var reminderManager: ReminderManager

    init() {
        do {
            let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])

            let manager = ReminderManager(modelContext: modelContainer.mainContext)
            _reminderManager = StateObject(wrappedValue: manager)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
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
