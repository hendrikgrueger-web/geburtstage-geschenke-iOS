import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingResetConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Erinnerungen") {
                    HStack {
                        Text("Standard-Zeiten")
                        Spacer()
                        Text("30, 14, 7, 2 Tage")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Ruhestunden")
                        Spacer()
                        Text("22:00 - 08:00")
                            .foregroundColor(.secondary)
                    }
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
                    HStack {
                        Text("Datenschutz")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Impressum")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .alert("Alle Daten löschen?", isPresented: $showingResetConfirmation) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("Das löscht alle Kontakte und Geschenkideen. Diese Aktion kann nicht rückgängig gemacht werden.")
            }
        }
    }

    private func resetAllData() {
        do {
            try modelContext.deleteContainer()
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
}
