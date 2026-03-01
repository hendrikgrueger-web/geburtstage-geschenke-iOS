import Foundation
import SwiftData

@MainActor
class AppViewModel: ObservableObject {
    @Published var hasImportedContacts = false

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func checkImportStatus() {
        let descriptor = FetchDescriptor<PersonRef>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        hasImportedContacts = count > 0
    }

    func getUpcomingBirthdays(limit: Int = 10) -> [PersonRef] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<PersonRef>()

        guard let people = try? modelContext.fetch(descriptor) else {
            return []
        }

        return people.compactMap { person -> (PersonRef, Date)? in
            guard let nextBirthday = nextBirthday(for: person, from: today) else {
                return nil
            }

            let daysUntil = calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0

            if daysUntil >= 0 && daysUntil <= 30 {
                return (person, nextBirthday)
            }
            return nil
        }
        .sorted { $0.1 < $1.1 }
        .prefix(limit)
        .map { $0.0 }
    }

    private func nextBirthday(for person: PersonRef, from today: Date) -> Date? {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: today)

        var components = calendar.dateComponents([.month, .day], from: person.birthday)
        components.year = currentYear

        guard var birthday = calendar.date(from: components) else {
            return nil
        }

        if birthday < today {
            components.year = currentYear + 1
            birthday = calendar.date(from: components) ?? birthday
        }

        return birthday
    }
}
