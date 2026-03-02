import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingResetConfirmation = false
    @State private var hasNotificationPermission = false
    @State private var showingReminderSettings = false
    @State private var isRefreshingReminders = false
    @State private var refreshAlertMessage: String?

    @StateObject private var reminderManager = ReminderManager(modelContext: ModelContext.placeholder)

    @Query private var reminderRule: [ReminderRule]
    @Query private var people: [PersonRef]

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var nextBirthday: (person: PersonRef, date: Date)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let sorted = people.compactMap { person -> (PersonRef, Date)? in
            guard let nextBirthday = nextBirthday(for: person, from: today) else {
                return nil
            }
            let daysUntil = calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0
            if daysUntil >= 0 && daysUntil <= 365 {
                return (person, nextBirthday)
            }
            return nil
        }.sorted { $0.1 < $1.1 }

        return sorted.first
    }

    private func nextBirthday(for person: PersonRef, from today: Date) -> Date? {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: today)

        var components = calendar.dateComponents([.month, .day], from: person.birthday)
        components.year = currentYear

        guard var birthday = calendar.date(from: components) else {
            return nil
        }

        if birthday < today {
            components.year = currentYear + 1
            birthday = calendar.date(from: components) ?? birthday
        }

        return birthday
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

                Section("iCloud Sync") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iCloud Sync")
                                .font(.body)

                            Text("Automatisch synchronisiert")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "icloud.fill")
                            .foregroundColor(.blue)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("iCloud Sync, automatisch synchronisiert")
                    .accessibilityHint("Daten werden automatisch über deine Apple-Geräte synchronisiert")
                } footer: {
                    Text("Daten werden automatisch über deine Apple-Geräte synchronisiert.")
                }

                Section("KI-Assistent") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("KI-Vorschläge")
                                .font(.body)

                            Text("Geschenkideen mit OpenRouter")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "sparkles")
                            .foregroundColor(.orange)
                    }
                } footer: {
                    Text("Die KI hilft dir, passende Geschenkideen zu finden. Optional und kann deaktiviert werden.")
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
                        await reminderManager?.cancelAllReminders()
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
            }
        } else {
            await reminderManager.cancelAllReminders()
        }
    }

    private func refreshReminders() async {
        isRefreshingReminders = true
        HapticFeedback.light()

        await reminderManager?.cancelAllReminders()
        await reminderManager?.scheduleAllReminders()

        isRefreshingReminders = false
        HapticFeedback.success()

        // Count pending reminders
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()

        refreshAlertMessage = "\(pendingRequests.count) Erinnerung\(pendingRequests.count == 1 ? "" : "en") neu geplant."
    }

    private func resetAllData() {
        do {
            try modelContext.deleteContainer()
        } catch {
            print("Failed to reset data: \(error)")
        }
    }

    private func openFeedback() {
        let feedbackEmail = "harryhirsch1878@gmail.com"
        let subject = "ai-presents-app Feedback v\(appVersion)"
        let body = "Was funktioniert gut?\n\nWas könnte besser sein?\n\n"

        if let url = URL(string: "mailto:\(feedbackEmail)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }

    private func openAbout() {
        let aboutText = """
        ai-presents-app v\(appVersion)

        Eine private iOS App zum Verwalten von Geburtstagen und Geschenkideen.

        Features:
        • Geburtstags-Übersicht mit Countdowns
        • Geschenkideen mit Budget und Tags
        • Smarte Erinnerungen (30/14/7/2 Tage)
        • iCloud Sync
        • KI-Vorschläge (OpenRouter)

        Entwickelt mit SwiftUI & SwiftData
        """

        let alert = UIAlertController(
            title: "Über ai-presents-app",
            message: aboutText,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.addAction(UIAlertAction(title: "GitHub", style: .default) { _ in
            if let url = URL(string: "https://github.com/harryhirsch1878/ai-presents-app-ios") {
                UIApplication.shared.open(url)
            }
        })

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}
