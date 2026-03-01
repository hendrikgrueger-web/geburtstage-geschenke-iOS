import SwiftUI
import SwiftData

struct ContactsImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isRequestingPermission = false
    @State private var hasPermission = false
    @State private var isImporting = false
    @State private var importedCount = 0
    @State private importError: String?
    @State private var useSampleData = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                // Title
                Text("Kontakte importieren")
                    .font(.title2)
                    .fontWeight(.bold)

                // Description
                Text("Importiere Kontakte mit Geburtstagen aus deinem Adressbuch oder verwende Demo-Daten zum Testen.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Import Mode Toggle
                Picker("Modus", selection: $useSampleData) {
                    Text(" echte Kontakte").tag(false)
                    Text(" Demo-Daten").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Permission Status
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: hasPermission ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(hasPermission ? .green : .gray)

                        Text(useSampleData ? "Demo-Daten verwenden" : "Zugriff auf Kontakte")
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)

                        Text(useSampleData ? "3 Beispiel-Kontakte" : "Nur Geburtstage & Namen")
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)

                        Text("Lokal gespeichert")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                if importedCount > 0 {
                    Text("✓ \(importedCount) Kontakte importiert")
                        .font(.headline)
                        .foregroundColor(.green)
                }

                if let error = importError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }

                Spacer()

                // Action Button
                Button(action: mainAction) {
                    if isRequestingPermission || isImporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if importedCount > 0 {
                        Text("Fertig")
                            .fontWeight(.semibold)
                    } else {
                        Text(useSampleData ? "Demo-Daten laden" : "Importieren")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(importedCount > 0 ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isRequestingPermission || isImporting || importedCount > 0)
            }
            .padding()
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func mainAction() {
        if useSampleData {
            loadSampleData()
        } else if hasPermission {
            importContacts()
        } else {
            requestPermission()
        }
    }

    private func requestPermission() {
        isRequestingPermission = true
        importError = nil

        Task {
            do {
                let granted = try await ContactsService.shared.requestPermission()

                await MainActor.run {
                    isRequestingPermission = false
                    hasPermission = granted

                    if !granted {
                        importError = "Zugriff verweigert. Bitte in Settings erlauben."
                    }
                }
            } catch {
                await MainActor.run {
                    isRequestingPermission = false
                    importError = error.localizedDescription
                }
            }
        }
    }

    private func importContacts() {
        isImporting = true
        importError = nil

        Task {
            do {
                let importedPeople = try await ContactsService.shared.importBirthdays()

                await MainActor.run {
                    isImporting = false
                    importedCount = importedPeople.count

                    // Save to SwiftData
                    for person in importedPeople {
                        modelContext.insert(person)
                    }
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    importError = error.localizedDescription
                }
            }
        }
    }

    private func loadSampleData() {
        isImporting = true
        importError = nil

        SampleDataService.createSampleData(in: modelContext)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isImporting = false
            importedCount = 3
        }
    }
}
