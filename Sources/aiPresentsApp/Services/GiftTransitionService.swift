import Foundation
import SwiftData

@MainActor
struct GiftTransitionService {

    static func autoTransitionPurchasedGifts(in context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentYear = calendar.component(.year, from: today)

        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        let dateString = formatter.string(from: today)

        let descriptor = FetchDescriptor<GiftIdea>()
        guard let allIdeas = try? context.fetch(descriptor) else { return }

        let personDescriptor = FetchDescriptor<PersonRef>()
        guard let allPeople = try? context.fetch(personDescriptor) else { return }

        let personMap = Dictionary(uniqueKeysWithValues: allPeople.map { ($0.id, $0) })

        var transitionCount = 0

        for idea in allIdeas where idea.status == .purchased {
            guard let person = personMap[idea.personId] else { continue }

            // Prüfen: Geburtstag dieses Jahr bereits vorbei?
            var birthdayComponents = calendar.dateComponents([.month, .day], from: person.birthday)
            birthdayComponents.year = currentYear
            guard let birthdayThisYear = calendar.date(from: birthdayComponents) else { continue }

            let birthdayDate = calendar.startOfDay(for: birthdayThisYear)
            guard birthdayDate < today else { continue }

            // Transition: purchased → given
            idea.status = .given
            idea.statusLog.append("\(dateString) - Gekauft \u{2192} Verschenkt (automatisch)")

            // GiftHistory-Eintrag erstellen
            let averageBudget = (idea.budgetMin + idea.budgetMax) / 2
            let history = GiftHistory(
                personId: idea.personId,
                title: idea.title,
                category: idea.tags.first ?? "Sonstiges",
                year: currentYear,
                budget: averageBudget,
                note: "Automatisch aus Geschenkidee übernommen"
            )
            context.insert(history)
            transitionCount += 1
        }

        if transitionCount > 0 {
            AppLogger.data.info("GiftTransitionService: \(transitionCount) Geschenk(e) automatisch auf verschenkt gesetzt")
        }
    }
}
