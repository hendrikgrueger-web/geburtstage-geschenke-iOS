import SwiftUI
import SwiftData
import WidgetKit

@main
struct aiPresentsApp: App {
    let modelContainer: ModelContainer
    @StateObject private var reminderManager: ReminderManager
    @StateObject private var subscriptionManager = SubscriptionManager()
    @Environment(\.scenePhase) private var scenePhase
    @State private var deepLinkPersonID: UUID?
    /// True wenn weder persistenter noch lokaler Container erstellt werden konnte.
    private let containerCreationFailed: Bool

    init() {
        // iCloud-Präferenz lesen (default: true beim ersten Start)
        let iCloudEnabled = UserDefaults.standard.object(forKey: "iCloudSyncEnabled") as? Bool ?? true
        let cloudKitDB: ModelConfiguration.CloudKitDatabase = iCloudEnabled ? .automatic : .none

        let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self, SuggestionFeedback.self])

        do {
            let config = ModelConfiguration(
                "ai-presents-app",
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: cloudKitDB
            )
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            containerCreationFailed = false

            let manager = ReminderManager(modelContext: modelContainer.mainContext)
            _reminderManager = StateObject(wrappedValue: manager)
        } catch {
            AppLogger.data.error("ModelContainer (CloudKit) fehlgeschlagen, versuche lokal", error: error)
            // Fallback: lokal ohne CloudKit
            do {
                let config = ModelConfiguration("ai-presents-app-local", schema: schema,
                                               isStoredInMemoryOnly: false, cloudKitDatabase: .none)
                modelContainer = try ModelContainer(for: schema, configurations: [config])
                containerCreationFailed = false

                let manager = ReminderManager(modelContext: modelContainer.mainContext)
                _reminderManager = StateObject(wrappedValue: manager)
            } catch {
                AppLogger.data.error("Auch lokaler ModelContainer fehlgeschlagen — In-Memory-Fallback", error: error)
                // Letzter Fallback: In-Memory (Daten gehen bei App-Neustart verloren, aber kein Crash)
                let config = ModelConfiguration("ai-presents-app-recovery", schema: schema,
                                               isStoredInMemoryOnly: true, cloudKitDatabase: .none)
                // swiftlint:disable:next force_try
                modelContainer = try! ModelContainer(for: schema, configurations: [config])
                containerCreationFailed = true

                let manager = ReminderManager(modelContext: modelContainer.mainContext)
                _reminderManager = StateObject(wrappedValue: manager)
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
                if containerCreationFailed {
                    // Datenbank konnte nicht erstellt werden — User informieren statt Crash
                    ContentUnavailableView(
                        "Datenbankfehler",
                        systemImage: "exclamationmark.triangle.fill",
                        description: Text("Die App-Datenbank konnte nicht geladen werden. Bitte starte die App neu oder lösche sie und installiere sie erneut.")
                    )
                } else if hasCompletedOnboarding {
                    ContentView(deepLinkPersonID: $deepLinkPersonID)
                        .onAppear {
                            GiftTransitionService.autoTransitionPurchasedGifts(in: modelContainer.mainContext)
                            Task {
                                await reminderManager.scheduleAllReminders()
                            }
                            // Widget-Daten initial aktualisieren
                            WidgetDataService.shared.updateWidgetData(from: modelContainer.mainContext)
                        }
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(subscriptionManager)
            .environmentObject(reminderManager)
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                WidgetDataService.shared.updateWidgetData(from: modelContainer.mainContext)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "aipresents",
              url.host == "person",
              let idString = url.pathComponents.dropFirst().first,
              let id = UUID(uuidString: idString) else {
            return
        }
        deepLinkPersonID = id
    }
}
