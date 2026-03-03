import SwiftUI
import SwiftData

struct AllContactsView: View {
    @Query(sort: \PersonRef.displayName) private var people: [PersonRef]
    @State private var searchText = ""

    private var filtered: [PersonRef] {
        guard !searchText.isEmpty else { return people }
        return people.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List(filtered) { person in
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
        }
        .searchable(text: $searchText, prompt: "Suche...")
        .navigationTitle("Alle Kontakte (\(people.count))")
        .navigationBarTitleDisplayMode(.inline)
    }
}
