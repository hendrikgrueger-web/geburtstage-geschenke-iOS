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
    @State private var showingAddGiftHistory = false
    @State private var showingDeletePerson = false
    @State private var showingAISuggestions = false

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
                    Text("Nächster Geburtstag")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(nextBirthdayInfo)
                        .fontWeight(.medium)
                        .foregroundColor(daysUntilBirthday <= 7 ? .orange : .primary)
                }

                HStack {
                    Text("Beziehung")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(person.relation)
                        .fontWeight(.medium)
                }
            }
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
                    Text("Nächster Geburtstag")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(nextBirthdayInfo)
                        .fontWeight(.medium)
                        .foregroundColor(daysUntilBirthday <= 7 ? .orange : .primary)
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
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                advanceStatus(for: idea)
                            } label: {
                                Label("Vor", systemImage: "arrow.right.circle.fill")
                            }
                            .tint(AppColor.primary)
                        }
                        .contextMenu {
                            Button {
                                advanceStatus(for: idea)
                            } label: {
                                Label("Status vorwärts", systemImage: "arrow.right.circle.fill")
                            }

                            Button(role: .destructive) {
                                if let index = filteredGiftIdeas.firstIndex(where: { $0.id == idea.id }) {
                                    deleteGiftIdeas(at: IndexSet([index]))
                                }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
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
            } footer: {
                Button(action: { showingAISuggestions = true }) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.orange)
                        Text("KI-Vorschläge generieren")
                            .font(.subheadline)
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
                    Button(action: { showingAddGiftHistory = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
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
        .sheet(isPresented: $showingAddGiftHistory) {
            AddGiftHistorySheet(person: person)
        }
        .sheet(isPresented: $showingAISuggestions) {
            AIGiftSuggestionsSheet(person: person)
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
            PersonAvatar(person: person, size: 60)

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

    private var daysUntilBirthday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let birthdayThisYear = calendar.date(bySetting: .year, value: calendar.component(.year, from: today), of: person.birthday) ?? person.birthday
        return calendar.dateComponents([.day], from: today, to: birthdayThisYear).day ?? 0
    }

    private var nextBirthdayInfo: String {
        if daysUntilBirthday == 0 {
            return "🎉 Heute!"
        } else if daysUntilBirthday == 1 {
            return "Morgen"
        } else if daysUntilBirthday < 0 {
            return "Vor \(-daysUntilBirthday) Tagen"
        } else if daysUntilBirthday == 365 {
            return "Nächstes Jahr"
        } else if daysUntilBirthday < 7 {
            return "In \(daysUntilBirthday) Tagen"
        } else {
            return "\(daysUntilBirthday) Tage"
        }
    }

    private func deleteGiftIdeas(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredGiftIdeas[index])
            }
            HapticFeedback.warning()
        }
    }

    private func deletePerson() {
        withAnimation {
            modelContext.delete(person)
            HapticFeedback.error()
        }
        dismiss()
    }

    private func advanceStatus(for idea: GiftIdea) {
        switch idea.status {
        case .idea:
            idea.status = .planned
        case .planned:
            idea.status = .purchased
        case .purchased:
            idea.status = .given
        case .given:
            // No further status
            break
        }
        HapticFeedback.medium()
    }
}
