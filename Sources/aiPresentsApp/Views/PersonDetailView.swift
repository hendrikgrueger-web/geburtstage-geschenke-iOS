import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: PersonRef

    @Query private var giftIdeas: [GiftIdea]
    @Query private var giftHistory: [GiftHistory]

    @State private var showingAddGiftIdea = false
    @State private var showingEditGiftIdea: GiftIdea?
    @State private var showingDeletePerson = false

    var body: some View {
        List {
            // Person Info
            Section {
                avatarRow

                HStack {
                    Text("Name")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(person.displayName)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Geburtstag")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(birthdayString)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Beziehung")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(person.relation)
                        .fontWeight(.medium)
                }
            }

            // Gift Ideas
            Section {
                if filteredGiftIdeas.isEmpty {
                    Text("Keine Ideen")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(filteredGiftIdeas) { idea in
                        Button {
                            showingEditGiftIdea = idea
                        } label: {
                            GiftIdeaRow(idea: idea)
                        }
                    }
                    .onDelete(perform: deleteGiftIdeas)
                }
            } header: {
                HStack {
                    Text("Geschenkideen")
                    Spacer()
                    Button(action: { showingAddGiftIdea = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }

            // Gift History
            Section {
                if filteredGiftHistory.isEmpty {
                    Text("Noch keine Geschenke eingetragen")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(filteredGiftHistory) { history in
                        GiftHistoryRow(history: history)
                    }
                }
            } header: {
                HStack {
                    Text("Geschenke-Verlauf")
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } footer: {
                Text("In früheren Jahren verschenkt")
            }

            // Danger Zone
            Section {
                Button(role: .destructive) {
                    showingDeletePerson = true
                } label: {
                    HStack {
                        Text("Kontakt löschen")
                        Spacer()
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddGiftIdea) {
            AddGiftIdeaSheet(person: person)
        }
        .sheet(item: $showingEditGiftIdea) { idea in
            EditGiftIdeaSheet(person: person, idea: idea)
        }
        .alert("Kontakt löschen?", isPresented: $showingDeletePerson) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                deletePerson()
            }
        } message: {
            Text("Das löscht \(person.displayName) und alle zugehörigen Geschenkideen.")
        }
        .navigationTitle(person.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddGiftIdea = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private var avatarRow: some View {
        HStack {
            Circle()
                .fill(AppColor.gradientBlue)
                .frame(width: 60, height: 60)
                .overlay {
                    Text(String(person.displayName.prefix(1)))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var filteredGiftIdeas: [GiftIdea] {
        let statusOrder: [GiftStatus] = [.idea, .planned, .purchased, .given]

        return giftIdeas
            .filter { $0.personId == person.id }
            .sorted { idea1, idea2 in
                let index1 = statusOrder.firstIndex(of: idea1.status) ?? 0
                let index2 = statusOrder.firstIndex(of: idea2.status) ?? 0
                if index1 != index2 {
                    return index1 < index2
                }
                return idea1.title < idea2.title
            }
    }

    private var filteredGiftHistory: [GiftHistory] {
        giftHistory
            .filter { $0.personId == person.id }
            .sorted { $0.year > $1.year }
    }

    private var birthdayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: person.birthday)
    }

    private func deleteGiftIdeas(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredGiftIdeas[index])
            }
        }
    }

    private func deletePerson() {
        withAnimation {
            modelContext.delete(person)
        }
        dismiss()
    }
}
