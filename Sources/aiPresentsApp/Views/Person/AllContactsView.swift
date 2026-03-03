import SwiftUI
import SwiftData

struct AllContactsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PersonRef.displayName) private var people: [PersonRef]
    @State private var searchText = ""
    @State private var personToDelete: PersonRef?
    @State private var showingDeleteAlert = false
    @State private var showingContactsImport = false

    private var filtered: [PersonRef] {
        guard !searchText.isEmpty else { return people }
        return people.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if people.isEmpty {
                EmptyStateView(type: .noContacts, action: {
                    showingContactsImport = true
                })
            } else {
                List {
                    ForEach(filtered) { person in
                        NavigationLink(destination: PersonDetailView(person: person)) {
                            HStack(spacing: 12) {
                                PersonAvatar(person: person, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(person.displayName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(person.relation)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                let days = BirthdayCalculator.daysUntilBirthday(
                                    for: person.birthday,
                                    from: Calendar.current.startOfDay(for: Date())
                                )
                                if let d = days {
                                    Text(d == 0 ? "Heute 🎉" : "in \(d) T.")
                                        .font(.caption)
                                        .foregroundColor(d <= 7 ? .orange : .secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                personToDelete = person
                                showingDeleteAlert = true
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Suche...")
            }
        }
        .navigationTitle("Alle Kontakte (\(people.count))")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingContactsImport) {
            ContactsImportView()
        }
        .alert("Kontakt löschen?", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) {
                personToDelete = nil
            }
            Button("Löschen", role: .destructive) {
                if let person = personToDelete {
                    modelContext.delete(person)
                    personToDelete = nil
                }
            }
        } message: {
            if let person = personToDelete {
                Text("Das löscht \(person.displayName) und alle zugehörigen Geschenkideen.")
            } else {
                Text("Kontakt wird gelöscht.")
            }
        }
    }
}
