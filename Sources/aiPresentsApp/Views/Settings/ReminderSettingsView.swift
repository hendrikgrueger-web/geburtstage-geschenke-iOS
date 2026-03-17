import SwiftUI
import SwiftData

struct ReminderSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var rules: [ReminderRule]

    @EnvironmentObject private var reminderManager: ReminderManager

    @State private var leadDays: Set<Int>
    @State private var quietHoursStart: Int
    @State private var quietHoursEnd: Int
    @State private var enabled: Bool

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
                    .accessibilityLabel(String(localized: "Erinnerungen aktivieren"))
            } header: {
                Text("Allgemein")
            } footer: {
                Text("Wenn deaktiviert, erhältst du keine Benachrichtigungen.")
            }

            Section {
                ForEach([30, 14, 7, 2], id: \.self) { day in
                    HStack {
                        Text(dayText(for: day))
                            .foregroundStyle(AppColor.textPrimary)

                        Spacer()

                        Toggle(
                            "",
                            isOn: Binding(
                                get: { leadDays.contains(day) },
                                set: { isSelected in
                                    if isSelected {
                                        leadDays.insert(day)
                                        HapticFeedback.light()
                                    } else {
                                        leadDays.remove(day)
                                    }
                                }
                            )
                        )
                        .labelsHidden()
                        .accessibilityLabel(String(localized: "\(dayText(for: day))"))
                    }
                }
            } header: {
                Text("Vorwarnungen")
            } footer: {
                if leadDays.isEmpty {
                    Text("⚠️ Keine Vorwarnungen ausgewählt. Du wirst nicht erinnert.")
                        .foregroundStyle(AppColor.accent)
                } else {
                    Text("Du wirst \(leadDays.count)-mal erinnert: \(sortedLeadDays.map { "\($0)T" }.joined(separator: ", ")) vor dem Geburtstag.")
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Zeitraum ohne Benachrichtigungen")
                        .font(.caption)
                        .foregroundStyle(AppColor.textSecondary)

                    HStack {
                        Text("Ab")
                            .foregroundStyle(AppColor.textSecondary)

                        Picker("", selection: $quietHoursStart) {
                            ForEach(0..<24) { hour in
                                Text(String(format: "%02d:00", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel(String(localized: "Beginn Ruhestunden"))

                        Spacer()

                        Text("Bis")
                            .foregroundStyle(AppColor.textSecondary)

                        Picker("", selection: $quietHoursEnd) {
                            ForEach(0..<24) { hour in
                                Text(String(format: "%02d:00", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel(String(localized: "Ende Ruhestunden"))
                    }
                }
            } header: {
                Text("Ruhestunden")
            } footer: {
                if quietHoursStart == quietHoursEnd {
                    Text("⚠️ Beginn und Ende können nicht identisch sein.")
                        .foregroundStyle(AppColor.danger)
                } else {
                    let quietRange = quietHoursRange
                    Text("Keine Benachrichtigungen zwischen \(quietRange.start) und \(quietRange.end).")
                }
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Info")
                            .font(.headline)
                        Text("Erinnerungen werden automatisch mit iOS-Benachrichtigungen erstellt.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "bell.badge")
                        .font(.title2)
                        .foregroundStyle(AppColor.primary)
                }
            }
        }
        .navigationTitle("Erinnerungseinstellungen")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: quietHoursStart) { oldValue, newValue in
            if newValue == quietHoursEnd {
                HapticFeedback.warning()
            }
        }
        .onChange(of: quietHoursEnd) { oldValue, newValue in
            if newValue == quietHoursStart {
                HapticFeedback.warning()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Speichern") {
                    if quietHoursStart != quietHoursEnd && !leadDays.isEmpty {
                        saveSettings()
                        dismiss()
                    } else {
                        HapticFeedback.warning()
                    }
                }
                .disabled(quietHoursStart == quietHoursEnd || leadDays.isEmpty)
            }
        }
    }

    private var sortedLeadDays: [Int] {
        leadDays.sorted(by: >)
    }

    private func dayText(for day: Int) -> String {
        switch day {
        case 30: return String(localized: "30 Tage vorher (frühzeitig)")
        case 14: return String(localized: "14 Tage vorher (2 Wochen)")
        case 7: return String(localized: "7 Tage vorher (1 Woche)")
        case 2: return String(localized: "2 Tage vorher (kurzfristig)")
        default: return String(localized: "\(day) Tage vorher")
        }
    }

    private var quietHoursRange: (start: String, end: String) {
        let start = String(format: "%02d:00", quietHoursStart)
        let end = String(format: "%02d:00", quietHoursEnd)
        return (start, end)
    }

    private func saveSettings() {
        if let rule = rules.first {
            rule.leadDays = sortedLeadDays
            rule.quietHoursStart = quietHoursStart
            rule.quietHoursEnd = quietHoursEnd
            rule.enabled = enabled
        } else {
            let newRule = ReminderRule(
                leadDays: sortedLeadDays,
                quietHoursStart: quietHoursStart,
                quietHoursEnd: quietHoursEnd,
                enabled: enabled
            )
            modelContext.insert(newRule)
        }

        // Reschedule reminders with new settings
        Task {
            await reminderManager.cancelBirthdayReminders()
            if enabled {
                await reminderManager.scheduleAllReminders()
            }
        }
    }
}
