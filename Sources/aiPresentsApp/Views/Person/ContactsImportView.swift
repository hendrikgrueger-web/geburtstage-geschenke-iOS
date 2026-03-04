import SwiftUI
import SwiftData

struct ContactsImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @Query private var existingPeople: [PersonRef]
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showingPaywall = false

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
            .paywallSheet(isPresented: $showingPaywall)
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

                var people = try await ContactsService.shared.importBirthdays()

                // Free-Tier: Maximal freePersonLimit Personen insgesamt
                if !subscriptionManager.isPremium {
                    let remaining = max(0, SubscriptionManager.freePersonLimit - existingPeople.count)
                    if people.count > remaining {
                        people = Array(people.prefix(remaining))
                    }
                }

                await MainActor.run {
                    for person in people { modelContext.insert(person) }
                    isImporting = false

                    // Hinweis wenn Limit erreicht
                    if !subscriptionManager.isPremium && existingPeople.count + people.count >= SubscriptionManager.freePersonLimit {
                        importError = "Free-Limit erreicht (\(SubscriptionManager.freePersonLimit) Kontakte). Upgrade für unbegrenzte Kontakte."
                    }
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
