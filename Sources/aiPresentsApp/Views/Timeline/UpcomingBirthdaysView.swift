import SwiftUI
import SwiftData

struct UpcomingBirthdaysView: View {
    let days: Int
    @Query(sort: \PersonRef.displayName) private var people: [PersonRef]

    private var upcoming: [(person: PersonRef, daysUntil: Int)] {
        let today = Calendar.current.startOfDay(for: Date())
        return people.compactMap { person in
            guard let d = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today),
                  d >= 0, d <= days else { return nil }
            return (person, d)
        }
        .sorted { $0.daysUntil < $1.daysUntil }
    }

    var body: some View {
        Group {
            if upcoming.isEmpty {
                ContentUnavailableView(
                    "Keine Geburtstage",
                    systemImage: "gift",
                    description: Text("In den nächsten \(days) Tagen hat niemand Geburtstag.")
                )
            } else {
                List(upcoming, id: \.person.id) { entry in
                    NavigationLink(destination: PersonDetailView(person: entry.person)) {
                        HStack(spacing: 12) {
                            PersonAvatar(person: entry.person, size: 44)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.person.displayName)
                                    .font(.body).fontWeight(.medium)
                                Text(birthdayString(for: entry.person))
                                    .font(.caption).foregroundColor(.secondary)
                            }

                            Spacer()

                            BirthdayCountdownBadge(daysUntil: entry.daysUntil)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Diese Woche (\(upcoming.count))"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func birthdayString(for person: PersonRef) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd. MMMM"
        formatter.locale = .current
        let today = Calendar.current.startOfDay(for: Date())
        guard let next = BirthdayCalculator.nextBirthday(for: person.birthday, from: today),
              let age = BirthdayCalculator.age(for: person.birthday, on: today) else {
            return formatter.string(from: person.birthday)
        }
        return "\(formatter.string(from: next)) · " + String(localized: "wird \(age + 1)")
    }
}
