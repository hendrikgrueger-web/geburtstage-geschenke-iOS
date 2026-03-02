import SwiftUI
import SwiftData

@main
struct aiPresentsApp: App {
    let modelContainer: ModelContainer
    @StateObject private var reminderManager: ReminderManager

    init() {
        do {
            let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self, SuggestionFeedback.self])

            // CloudKit configuration
            let config = ModelConfiguration(
                "ai-presents-app",
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
                let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self, SuggestionFeedback.self])
                let config = ModelConfiguration(isStoredInMemoryOnly: false, cloudKitDatabase: .none)
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
            ZStack {
                if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
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
