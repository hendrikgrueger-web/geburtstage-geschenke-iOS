import SwiftUI
import SwiftData

struct ContactsImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isImporting = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // Icon + Titel
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)

                    Text("Kontakte importieren")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer().frame(height: 48)

                // Aktions-Buttons
                VStack(spacing: 12) {
                    if isImporting {
                        ProgressView()
                            .controlSize(.large)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    } else {
                        // Primär: Adressbuch
                        Button {
                            importFromContacts()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "person.2.fill")
                                Text("Aus Adressbuch importieren")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }

                        // Sekundär: Demo
                        Button {
                            loadSampleData()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "wand.and.stars")
                                Text("Demo-Daten laden")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(14)
                        }
                    }

                    if let error = importError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal)

                Spacer().frame(height: 24)

                // Datenschutz-Info — Caption, kein Checkbox
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                        Text("Nur Namen & Geburtstage · Lokal gespeichert")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }

    private func importFromContacts() {
        isImporting = true
        importError = nil

        Task {
            do {
                let granted = try await ContactsService.shared.requestPermission()
                guard granted else {
                    await MainActor.run {
                        isImporting = false
                        importError = "Zugriff verweigert – bitte in den Systemeinstellungen erlauben."
                    }
                    return
                }

                let people = try await ContactsService.shared.importBirthdays()
                await MainActor.run {
                    for person in people { modelContext.insert(person) }
                    isImporting = false
                }
                try? await Task.sleep(nanoseconds: 600_000_000)
                await MainActor.run { dismiss() }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isImporting = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                dismiss()
            }
        }
    }
}
