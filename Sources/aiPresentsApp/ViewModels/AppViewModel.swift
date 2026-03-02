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
        let today = Calendar.current.startOfDay(for: Date())

        let descriptor = FetchDescriptor<PersonRef>()

        guard let people = try? modelContext.fetch(descriptor) else {
            return []
        }

        return people.compactMap { person -> (PersonRef, Date)? in
            guard let nextBirthday = BirthdayCalculator.nextBirthday(for: person.birthday, from: today) else {
                return nil
            }

            let daysUntil = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) ?? 0

            if daysUntil >= 0 && daysUntil <= 30 {
                return (person, nextBirthday)
            }
            return nil
        }
        .sorted { $0.1 < $1.1 }
        .prefix(limit)
        .map { $0.0 }
    }
}
