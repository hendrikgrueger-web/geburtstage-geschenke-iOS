import SwiftUI
import SwiftData

struct ContactsImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingPeople: [PersonRef]
    @State private var isImporting = false
    @State private var importError: String?
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showingPaywall = false
    @State private var showingPaywallAfterImport = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // Icon + Titel
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 64))
                        .foregroundStyle(AppColor.primary)

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
                            if subscriptionManager.hasFullAccess {
                                importFromContacts()
                            } else {
                                showingPaywall = true
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "person.2.fill")
                                Text("Aus Adressbuch importieren")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColor.primary)
                            .foregroundStyle(.white)
                            .clipShape(.rect(cornerRadius: 14))
                        }

                        // Sekundär: Demo
                        Button {
                            if subscriptionManager.hasFullAccess {
                                loadSampleData()
                            } else {
                                showingPaywall = true
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "wand.and.stars")
                                Text("Demo-Daten laden")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(.rect(cornerRadius: 14))
                        }
                    }

                    if let error = importError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(AppColor.accent)
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
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingPaywallAfterImport, onDismiss: {
            dismiss()
        }) {
            PaywallView()
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
                        importError = String(localized: "Zugriff verweigert – bitte in den Systemeinstellungen erlauben.")
                    }
                    return
                }

                let people = try await ContactsService.shared.importBirthdays()

                await MainActor.run {
                    // Bestehende Kontakte per contactIdentifier nachschlagen
                    let existingByID = Dictionary(
                        existingPeople.map { ($0.contactIdentifier, $0) },
                        uniquingKeysWith: { first, _ in first }
                    )

                    var newPeople: [PersonRef] = []
                    var updatedCount = 0

                    for person in people {
                        if let existing = existingByID[person.contactIdentifier] {
                            // Update: Geburtstag, Name und birthYearKnown synchronisieren
                            if existing.birthday != person.birthday || existing.birthYearKnown != person.birthYearKnown {
                                existing.birthday = person.birthday
                                existing.birthYearKnown = person.birthYearKnown
                                updatedCount += 1
                            }
                            if existing.displayName != person.displayName {
                                existing.displayName = person.displayName
                                updatedCount += 1
                            }
                        } else {
                            newPeople.append(person)
                        }
                    }

                    for person in newPeople { modelContext.insert(person) }
                    WidgetDataService.shared.updateWidgetData(from: modelContext)
                    isImporting = false
                }
                try? await Task.sleep(nanoseconds: 600_000_000)
                await MainActor.run {
                    if !UserDefaults.standard.bool(forKey: "hasSeenPostImportPaywall") {
                        UserDefaults.standard.set(true, forKey: "hasSeenPostImportPaywall")
                        showingPaywallAfterImport = true
                    } else {
                        dismiss()
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
        WidgetDataService.shared.updateWidgetData(from: modelContext)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isImporting = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                dismiss()
            }
        }
    }
}
