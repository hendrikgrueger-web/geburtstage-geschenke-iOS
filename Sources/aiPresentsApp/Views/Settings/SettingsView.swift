import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showingResetConfirmation = false
    @State private var hasNotificationPermission = false
    @State private var showingReminderSettings = false
    @State private var isRefreshingReminders = false
    @State private var refreshAlertMessage: String?
    @State private var toast: ToastItem?
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true
    @State private var showingICloudRestartNotice = false
    @State private var showingAbout = false
    @State private var showingRevokeConsentConfirmation = false
    @State private var showingPaywall = false

    @StateObject private var reminderManager = ReminderManager(modelContext: ModelContext.placeholder)
    @StateObject private var consentManager = AIConsentManager.shared

    @Query private var reminderRule: [ReminderRule]
    @Query private var people: [PersonRef]

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var nextBirthday: (person: PersonRef, date: Date)? {
        let today = Calendar.current.startOfDay(for: Date())

        let sorted = people.compactMap { person -> (PersonRef, Date)? in
            guard let nextBirthday = BirthdayCalculator.nextBirthday(for: person.birthday, from: today),
                  let daysUntil = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) else {
                return nil
            }
            if daysUntil >= 0 && daysUntil <= 365 {
                return (person, nextBirthday)
            }
            return nil
        }.sorted { $0.1 < $1.1 }

        return sorted.first
    }

    private func daysUntil(from date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }

    private func birthdayText(for days: Int) -> String {
        if days == 0 {
            return "Heute!"
        } else if days == 1 {
            return "Morgen"
        } else if days <= 7 {
            return "In \(days) Tagen"
        } else {
            return "In \(days) Tagen"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Next Birthday Card
                if let next = nextBirthday {
                    Section {
                        HStack(spacing: 16) {
                            PersonAvatar(person: next.person, size: 50)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Nächster Geburtstag")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(next.person.displayName)
                                    .font(.headline)

                                Text(birthdayText(for: daysUntil(from: next.date)))
                                    .font(.subheadline)
                                    .foregroundColor(daysUntil(from: next.date) <= 7 ? .orange : .secondary)
                            }

                            Spacer()

                            BirthdayCountdownBadge(daysUntil: daysUntil(from: next.date))
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Übersicht")
                    }
                }

                // MARK: - Abo-Verwaltung
                Section {
                    if subscriptionManager.isPremium {
                        HStack {
                            PremiumBadge(style: .prominent)
                            Spacer()
                            if let product = subscriptionManager.activeProduct {
                                Text(product.displayPrice + "/\(product.id.contains("yearly") ? "Jahr" : "Monat")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Text("Abo verwalten")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Button {
                            showingPaywall = true
                            HapticFeedback.medium()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Premium freischalten")
                                        .font(.headline)
                                    Text("Unbegrenzte Kontakte, KI-Vorschläge & mehr")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.orange)
                            }
                        }

                        Button("Käufe wiederherstellen") {
                            Task {
                                await subscriptionManager.restorePurchases()
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Abo")
                } footer: {
                    if !subscriptionManager.isPremium {
                        Text("Free: \(SubscriptionManager.freePersonLimit) Kontakte · Demo-KI · 1 Erinnerung")
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundColor(.secondary)
                    }

                    Button(action: openAbout) {
                        HStack {
                            Text("Über die App")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: openFeedback) {
                        HStack {
                            Text("Feedback senden")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    #if DEBUG
                    NavigationLink {
                        DevSettingsView()
                    } label: {
                        HStack {
                            Text("Dev Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    #endif
                }

                Section("Benachrichtigungen") {
                    Toggle("Erinnerungen aktivieren", isOn: $hasNotificationPermission)
                        .onChange(of: hasNotificationPermission) { _, newValue in
                            Task {
                                await handlePermissionChange(newValue)
                            }
                        }
                        .accessibilityLabel("Erinnerungen aktivieren")

                    NavigationLink {
                        ReminderSettingsView(rule: reminderRule.first)
                    } label: {
                        HStack {
                            Text("Erinnerungseinstellungen")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    if hasNotificationPermission {
                        Button {
                            Task {
                                await refreshReminders()
                            }
                        } label: {
                            HStack {
                                if isRefreshingReminders {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }

                                Text("Erinnerungen neu laden")
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                        }
                        .disabled(isRefreshingReminders)
                        .accessibilityLabel("Erinnerungen neu laden")
                    }
                }

                Section {
                    Toggle(isOn: $iCloudSyncEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("iCloud Sync")
                            Text(iCloudSyncEnabled ? "Aktiv" : "Nur lokal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: iCloudSyncEnabled) { _, _ in
                        showingICloudRestartNotice = true
                    }
                } header: {
                    Text("iCloud Sync")
                } footer: {
                    Text(iCloudSyncEnabled
                         ? "Daten werden automatisch über deine Apple-Geräte synchronisiert."
                         : "Daten werden nur lokal auf diesem Gerät gespeichert.")
                }
                .alert("Neustart erforderlich", isPresented: $showingICloudRestartNotice) {
                    Button("OK") { }
                } message: {
                    Text("Die Änderung wird beim nächsten App-Start wirksam.")
                }

                Section {
                    Toggle("KI-Vorschläge aktiviert", isOn: $consentManager.aiEnabled)
                        .disabled(!consentManager.consentGiven)

                    if consentManager.consentGiven {
                        HStack {
                            Label("Einwilligung erteilt", systemImage: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Spacer()
                            Button("Widerrufen") {
                                showingRevokeConsentConfirmation = true
                            }
                            .foregroundColor(.red)
                            .font(.subheadline)
                        }
                    } else {
                        Label("Keine Einwilligung erteilt", systemImage: "shield.slash")
                            .foregroundColor(.secondary)
                    }

                    if !AIService.isAPIKeyConfigured {
                        Label("API-Key nicht konfiguriert (Demo-Modus)", systemImage: "key.slash")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("KI-Assistent")
                } footer: {
                    Text("Die KI-Funktionen nutzen OpenRouter → Google Gemini (USA). Es werden Vorname, Alter, Beziehungstyp und Sternzeichen übertragen. Widerruf jederzeit möglich.")
                }
                .alert("Einwilligung widerrufen?", isPresented: $showingRevokeConsentConfirmation) {
                    Button("Abbrechen", role: .cancel) { }
                    Button("Widerrufen", role: .destructive) {
                        consentManager.revokeConsent()
                    }
                } message: {
                    Text("Die KI-Funktionen werden deaktiviert. Du kannst die Einwilligung jederzeit erneut erteilen.")
                }

                Section("Daten") {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        HStack {
                            Text("Alle Daten löschen")
                            Spacer()
                            Image(systemName: "trash")
                        }
                    }
                }

                Section {
                    NavigationLink {
                        PrivacyView()
                    } label: {
                        HStack {
                            Text("Datenschutz")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    NavigationLink {
                        LegalView()
                    } label: {
                        HStack {
                            Text("Impressum")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .onAppear {
                reminderManager.updateModelContext(modelContext)
                Task {
                    await checkNotificationPermission()
                }
            }
            .alert("Alle Daten löschen?", isPresented: $showingResetConfirmation) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    Task {
                        await reminderManager.cancelAllReminders()
                    }
                    resetAllData()
                }
            } message: {
                Text("Das löscht alle Kontakte und Geschenkideen. Diese Aktion kann nicht rückgängig gemacht werden.")
            }
            .alert("Erinnerungen", isPresented: Binding(
                get: { refreshAlertMessage != nil },
                set: { if !$0 { refreshAlertMessage = nil } }
            )) {
                Button("OK") {
                    refreshAlertMessage = nil
                }
            } message: {
                if let message = refreshAlertMessage {
                    Text(message)
                }
            }
        }
        .toast(item: $toast)
        .sheet(isPresented: $showingAbout) {
            aboutSheet
        }
        .paywallSheet(isPresented: $showingPaywall)
    }

    private var aboutSheet: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(appVersion) (Build \(buildNumber))")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Text("""
                    Eine private iOS App zum Verwalten von Geburtstagen und Geschenkideen.
                    """)
                    .font(.body)
                    .foregroundColor(.secondary)
                } header: {
                    Text("Über die App")
                }

                Section("Features") {
                    Label("Geburtstags-Übersicht mit Countdowns", systemImage: "calendar")
                    Label("Geschenkideen mit Budget und Tags", systemImage: "gift")
                    Label("Smarte Erinnerungen", systemImage: "bell")
                    Label("iCloud Sync", systemImage: "icloud")
                    Label("KI-Vorschläge (OpenRouter)", systemImage: "sparkles")
                }

                Section {
                    Button {
                        if let url = URL(string: "https://github.com/harryhirsch1878/ai-presents-app-ios") {
                            UIApplication.shared.open(url) { success in
                                if !success {
                                    AppLogger.ui.warning("Failed to open GitHub URL")
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Über ai-presents-app")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        showingAbout = false
                    }
                }
            }
        }
    }

    private func checkNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        hasNotificationPermission = settings.authorizationStatus == .authorized
    }

    private func handlePermissionChange(_ enabled: Bool) async {
        if enabled {
            let granted = await reminderManager.requestPermission()
            hasNotificationPermission = granted

            if granted {
                await reminderManager.scheduleAllReminders()
                toast = ToastItem.success("Erinnerungen aktiviert", message: "Du erhältst Benachrichtigungen für Geburtstage.")
            } else {
                toast = ToastItem.warning("Berechtigung verweigert", message: "Bitte erlaube Benachrichtigungen in den Systemeinstellungen.")
            }
        } else {
            await reminderManager.cancelAllReminders()
            toast = ToastItem.info("Erinnerungen deaktiviert", message: "Du erhältst keine Benachrichtigungen mehr.")
        }
    }

    private func refreshReminders() async {
        isRefreshingReminders = true
        HapticFeedback.light()

        await reminderManager.cancelAllReminders()
        await reminderManager.scheduleAllReminders()

        isRefreshingReminders = false
        HapticFeedback.success()

        // Count pending reminders
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()

        let count = pendingRequests.count
        toast = ToastItem.success("Erinnerungen aktualisiert", message: "\(count) Erinnerung\(count == 1 ? "" : "en") neu geplant.")
    }

    private func resetAllData() {
        do {
            try modelContext.delete(model: ReminderRule.self)
            try modelContext.delete(model: GiftHistory.self)
            try modelContext.delete(model: GiftIdea.self)
            try modelContext.delete(model: PersonRef.self)
            try modelContext.delete(model: SuggestionFeedback.self)
            AppLogger.data.info("All data reset successfully")
            toast = ToastItem.success("Daten gelöscht", message: "Alle Kontakte und Geschenkideen wurden entfernt.")
        } catch {
            AppLogger.data.error("Failed to reset data", error: error)
            toast = ToastItem.error("Fehler beim Löschen", message: "Ein Fehler ist aufgetreten. Bitte versuche es erneut.")
        }
    }

    private func openFeedback() {
        let feedbackEmail = "harryhirsch1878@gmail.com"
        let subject = "ai-presents-app Feedback v\(appVersion)"
        let body = "Was funktioniert gut?\n\nWas könnte besser sein?\n\n"

        if let url = URL(string: "mailto:\(feedbackEmail)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url) { success in
                if success {
                    toast = ToastItem.info("Mail-App geöffnet", message: "Vielen Dank für dein Feedback!")
                } else {
                    AppLogger.ui.warning("Failed to open mail feedback link")
                    toast = ToastItem.warning("Fehler", message: "Mail-App konnte nicht geöffnet werden.")
                }
            }
        }
    }

    private func openAbout() {
        showingAbout = true
    }
}
