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
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                let days = BirthdayCalculator.daysUntilBirthday(
                                    for: person.birthday,
                                    from: Calendar.current.startOfDay(for: Date())
                                )
                                if let d = days {
                                    if d == 0 {
                                        Text("Heute 🎉")
                                            .font(.caption)
                                            .foregroundStyle(AppColor.accent)
                                    } else {
                                        Text("in \(d) T.")
                                            .font(.caption)
                                            .foregroundStyle(d <= 7 ? AppColor.accent : Color.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                personToDelete = person
                                showingDeleteAlert = true
                            } label: {
                                Label("Entfernen", systemImage: "trash")
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
        .alert("Aus App entfernen?", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) {
                personToDelete = nil
            }
            Button("Entfernen", role: .destructive) {
                if let person = personToDelete {
                    modelContext.delete(person)
                    WidgetDataService.shared.updateWidgetData(from: modelContext)
                    personToDelete = nil
                }
            }
        } message: {
            if let person = personToDelete {
                Text("\(person.displayName) wird nur aus dieser App entfernt. Dein iOS-Kontakt bleibt unverändert.")
            } else {
                Text("Der Kontakt wird nur aus dieser App entfernt. Dein iOS-Kontakt bleibt unverändert.")
            }
        }
    }
}
