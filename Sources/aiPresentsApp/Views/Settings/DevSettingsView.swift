#if DEBUG
import SwiftUI
import SwiftData

struct DevSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isCreatingSampleData = false
    @State private var isClearingData = false
    @State private var sampleDataCreated = false
    @State private var dataCleared = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    @Query private var people: [PersonRef]

    var body: some View {
        List {
            Section {
                Button {
                    createSampleData()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppColor.success)
                        Text("Demo-Daten erstellen")
                        Spacer()
                        if sampleDataCreated {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColor.success)
                        }
                    }
                }
                .disabled(isCreatingSampleData)

                Button {
                    clearAllData()
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(AppColor.danger)
                        Text("Alle Daten löschen")
                        Spacer()
                        if dataCleared {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColor.success)
                        }
                    }
                }
                .disabled(isClearingData)
            } header: {
                Text("Test-Daten")
            } footer: {
                Text("Demo-Daten für Tests und Screenshots")
            }

            Section("Daten-Statistik") {
                HStack {
                    Text("Kontakte")
                    Spacer()
                    Text("\(people.count)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Geschenkideen")
                    Spacer()
                    Text("\(totalGiftIdeas)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Geschenk-Verlauf")
                    Spacer()
                    Text("\(totalGiftHistory)")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Info") {
                Text("Diese Ansicht ist nur im Debug-Modus verfügbar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Dev Settings")
        .alert("Info", isPresented: $showingAlert) {
            Button("OK") {
                alertMessage = ""
            }
        } message: {
            Text(alertMessage)
        }
    }

    private var totalGiftIdeas: Int {
        people.reduce(0) { $0 + ($1.giftIdeas?.count ?? 0) }
    }

    private var totalGiftHistory: Int {
        people.reduce(0) { $0 + ($1.giftHistory?.count ?? 0) }
    }

    private func createSampleData() {
        isCreatingSampleData = true
        SampleDataService.createSampleData(in: modelContext)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            isCreatingSampleData = false
            sampleDataCreated = true
            alertMessage = String(localized: "Demo-Daten erstellt!")
            showingAlert = true
        }
    }

    private func clearAllData() {
        isClearingData = true

        do {
            try modelContext.delete(model: ReminderRule.self)
            try modelContext.delete(model: GiftHistory.self)
            try modelContext.delete(model: GiftIdea.self)
            try modelContext.delete(model: PersonRef.self)
            try modelContext.delete(model: SuggestionFeedback.self)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.5))
                isClearingData = false
                dataCleared = true
                alertMessage = String(localized: "Alle Daten gelöscht!")
                showingAlert = true
            }
        } catch {
            isClearingData = false
            alertMessage = String(localized: "Fehler beim Löschen: \(error.localizedDescription)")
            showingAlert = true
        }
    }
}
#endif
