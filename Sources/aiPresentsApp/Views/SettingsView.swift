import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingResetConfirmation = false
    @State private var hasNotificationPermission = false
    @State private var showingReminderSettings = false

    @StateObject private var reminderManager = ReminderManager(modelContext: ModelContext.placeholder)

    @Query private var reminderRule: [ReminderRule]

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundColor(.secondary)
                    }

                    Button(action: openFeedback) {
                        HStack {
                            Text("Feedback senden")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Benachrichtigungen") {
                    Toggle("Erinnerungen aktivieren", isOn: $hasNotificationPermission)
                        .onChange(of: hasNotificationPermission) { _, newValue in
                            Task {
                                await handlePermissionChange(newValue)
                            }
                        }

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
        }
    }

    private func checkNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        hasNotificationPermission = settings.authorizationStatus == .authorized
    }

    private func handlePermissionChange(_ enabled: Bool) async {
        guard let manager = reminderManager else { return }

        if enabled {
            let granted = await manager.requestPermission()
            hasNotificationPermission = granted

            if granted {
                await manager.scheduleAllReminders()
            }
        } else {
            await manager.cancelAllReminders()
        }
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
}
