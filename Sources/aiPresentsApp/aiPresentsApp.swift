import SwiftUI
import SwiftData
import WidgetKit

@main
struct aiPresentsApp: App {
    let modelContainer: ModelContainer
    @State private var reminderManager: ReminderManager
    @State private var subscriptionManager = SubscriptionManager()
    @Environment(\.scenePhase) private var scenePhase
    @State private var deepLinkPersonID: UUID?
    @State private var screenshotShowChat = false
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
            _reminderManager = State(wrappedValue: manager)
        } catch {
            AppLogger.data.error("ModelContainer (CloudKit) fehlgeschlagen, versuche lokal", error: error)
            // Fallback: lokal ohne CloudKit
            do {
                let config = ModelConfiguration("ai-presents-app-local", schema: schema,
                                               isStoredInMemoryOnly: false, cloudKitDatabase: .none)
                modelContainer = try ModelContainer(for: schema, configurations: [config])
                containerCreationFailed = false

                let manager = ReminderManager(modelContext: modelContainer.mainContext)
                _reminderManager = State(wrappedValue: manager)
            } catch {
                AppLogger.data.error("Auch lokaler ModelContainer fehlgeschlagen — In-Memory-Fallback", error: error)
                // Letzter Fallback: In-Memory (Daten gehen bei App-Neustart verloren, aber kein Crash)
                let config = ModelConfiguration("ai-presents-app-recovery", schema: schema,
                                               isStoredInMemoryOnly: true, cloudKitDatabase: .none)
                // swiftlint:disable:next force_try
                modelContainer = try! ModelContainer(for: schema, configurations: [config])
                containerCreationFailed = true

                let manager = ReminderManager(modelContext: modelContainer.mainContext)
                _reminderManager = State(wrappedValue: manager)
            }
        }

        #if DEBUG
        // Screenshot-Modus: globaler Flag (versteckt Dev-Only-UI in Screenshots)
        let screenshotArgs = ["--reset-sample-data", "--show-person", "--show-chat", "--show-settings", "--show-add-gift", "--show-onboarding"]
        if CommandLine.arguments.contains(where: { screenshotArgs.contains($0) }) {
            UserDefaults.standard.set(true, forKey: "screenshotMode")
        } else {
            UserDefaults.standard.removeObject(forKey: "screenshotMode")
        }

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

        // Screenshot-Modus: Person-ID merken für onAppear
        if let idx = CommandLine.arguments.firstIndex(of: "--show-person"),
           idx + 1 < CommandLine.arguments.count {
            UserDefaults.standard.set(CommandLine.arguments[idx + 1], forKey: "screenshotPersonID")
        } else {
            UserDefaults.standard.removeObject(forKey: "screenshotPersonID")
        }

        // Screenshot-Modus: AI-Chat öffnen
        if CommandLine.arguments.contains("--show-chat") {
            UserDefaults.standard.set(true, forKey: "screenshotShowChat")
        } else {
            UserDefaults.standard.removeObject(forKey: "screenshotShowChat")
        }

        // Screenshot-Modus: Settings öffnen
        if CommandLine.arguments.contains("--show-settings") {
            UserDefaults.standard.set(true, forKey: "screenshotShowSettings")
        } else {
            UserDefaults.standard.removeObject(forKey: "screenshotShowSettings")
        }

        // Screenshot-Modus: Add Gift Idea Sheet öffnen
        if let idx = CommandLine.arguments.firstIndex(of: "--show-add-gift"),
           idx + 1 < CommandLine.arguments.count {
            UserDefaults.standard.set(CommandLine.arguments[idx + 1], forKey: "screenshotShowAddGift")
        } else {
            UserDefaults.standard.removeObject(forKey: "screenshotShowAddGift")
        }

        // Screenshot-Modus: Onboarding zeigen (hasCompletedOnboarding zurücksetzen)
        if CommandLine.arguments.contains("--show-onboarding") {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
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
                    ContentView(deepLinkPersonID: $deepLinkPersonID, screenshotShowChat: $screenshotShowChat)
                        .onAppear {
                            GiftTransitionService.autoTransitionPurchasedGifts(in: modelContainer.mainContext)
                            Task {
                                await reminderManager.scheduleAllReminders()
                            }
                            // Widget-Daten initial aktualisieren
                            WidgetDataService.shared.updateWidgetData(from: modelContainer.mainContext)

                            #if DEBUG
                            // Screenshot-Modus: Deep Link nach View-Aufbau setzen
                            if let idString = UserDefaults.standard.string(forKey: "screenshotPersonID"),
                               let id = UUID(uuidString: idString) {
                                UserDefaults.standard.removeObject(forKey: "screenshotPersonID")
                                Task { @MainActor in
                                    try? await Task.sleep(for: .seconds(0.5))
                                    deepLinkPersonID = id
                                }
                            }
                            // Screenshot-Modus: AI-Chat öffnen
                            if UserDefaults.standard.bool(forKey: "screenshotShowChat") {
                                UserDefaults.standard.removeObject(forKey: "screenshotShowChat")
                                Task { @MainActor in
                                    try? await Task.sleep(for: .seconds(0.5))
                                    screenshotShowChat = true
                                }
                            }
                            #endif
                        }
                } else {
                    OnboardingView()
                }
            }
            .environment(reminderManager)
            .environment(subscriptionManager)
            .overlay {
                if AppLockManager.shared.isLocked {
                    AppLockView()
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                WidgetDataService.shared.updateWidgetData(from: modelContainer.mainContext)
                AppLockManager.shared.lockIfEnabled()
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
