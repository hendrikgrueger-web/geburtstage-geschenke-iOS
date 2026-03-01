import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let person: PersonRef

    @Query private var giftIdeas: [GiftIdea]

    @State private var showingAddGiftIdea = false

    var body: some View {
        List {
            // Person Info
            Section {
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
                        GiftIdeaRow(idea: idea)
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
        }
        .sheet(isPresented: $showingAddGiftIdea) {
            AddGiftIdeaSheet(person: person)
        }
        .navigationTitle(person.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filteredGiftIdeas: [GiftIdea] {
        giftIdeas.filter { $0.personId == person.id }
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
}
