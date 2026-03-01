import SwiftUI
import SwiftData

struct ReminderSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var rules: [ReminderRule]

    @State private var leadDays: Set<Int>
    @State private var quietHoursStart: Int
    @State private var quietHoursEnd: Int
    @State private var enabled: Bool
    @State private var reminderManager: ReminderManager?

    init(rule: ReminderRule?) {
        let days = rule?.leadDays ?? [30, 14, 7, 2]
        _leadDays = State(initialValue: Set(days))
        _quietHoursStart = State(initialValue: rule?.quietHoursStart ?? 22)
        _quietHoursEnd = State(initialValue: rule?.quietHoursEnd ?? 8)
        _enabled = State(initialValue: rule?.enabled ?? true)
    }

    var body: some View {
        Form {
            Section {
                Toggle("Erinnerungen aktivieren", isOn: $enabled)
            } header: {
                Text("Allgemein")
            }

            Section {
                ForEach([30, 14, 7, 2], id: \.self) { day in
                    Toggle(
                        "\(day) Tage vorher",
                        isOn: Binding(
                            get: { leadDays.contains(day) },
                            set: { isSelected in
                                if isSelected {
                                    leadDays.insert(day)
                                } else {
                                    leadDays.remove(day)
                                }
                            }
                        )
                    )
                    .accessibilityLabel("\(day) Tage vorher erinnern")
                }
            } header: {
                Text("Vorwarnungen")
            } footer: {
                if leadDays.isEmpty {
                    Text("⚠️ Keine Vorwarnungen ausgewählt. Du wirst nicht erinnert.")
                        .foregroundColor(.orange)
                } else {
                    Text("Wähle aus, wann du erinnert werden möchtest.")
                }
            }

            Section {
                Picker("Beginn Ruhestunden", selection: $quietHoursStart) {
                    ForEach(0..<24) { hour in
                        Text(String(format: "%02d:00", hour)).tag(hour)
                    }
                }
                .accessibilityLabel("Beginn Ruhestunden")

                Picker("Ende Ruhestunden", selection: $quietHoursEnd) {
                    ForEach(0..<24) { hour in
                        Text(String(format: "%02d:00", hour)).tag(hour)
                    }
                }
                .accessibilityLabel("Ende Ruhestunden")
            } header: {
                Text("Ruhestunden")
            } footer: {
                if quietHoursStart == quietHoursEnd {
                    Text("⚠️ Beginn und Ende können nicht identisch sein. Setze einen anderen Wert.")
                        .foregroundColor(.red)
                } else {
                    Text("Keine Benachrichtigungen in diesem Zeitraum.")
                }
            }
        }
        .navigationTitle("Erinnerungseinstellungen")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if reminderManager == nil {
                reminderManager = ReminderManager(modelContext: modelContext)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Speichern") {
                    if quietHoursStart != quietHoursEnd {
                        saveSettings()
                        dismiss()
                    } else {
                        HapticFeedback.warning()
                    }
                }
                .disabled(quietHoursStart == quietHoursEnd)
            }
        }
    }

    private func saveSettings() {
        if let rule = rules.first {
            rule.leadDays = Array(leadDays).sorted()
            rule.quietHoursStart = quietHoursStart
            rule.quietHoursEnd = quietHoursEnd
            rule.enabled = enabled
        } else {
            let newRule = ReminderRule(
                leadDays: Array(leadDays).sorted(),
                quietHoursStart: quietHoursStart,
                quietHoursEnd: quietHoursEnd,
                enabled: enabled
            )
            modelContext.insert(newRule)
        }

        // Reschedule reminders with new settings
        Task {
            await reminderManager?.cancelAllReminders()
            if enabled {
                await reminderManager?.scheduleAllReminders()
            }
        }
    }
}
