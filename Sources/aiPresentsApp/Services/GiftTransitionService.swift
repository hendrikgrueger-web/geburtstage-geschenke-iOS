import Foundation
import SwiftData

@MainActor
enum GiftTransitionService {

    static func autoTransitionPurchasedGifts(in context: ModelContext) {
        var calendar = Calendar.current
        calendar.timeZone = .current
        let today = calendar.startOfDay(for: Date())
        let currentYear = calendar.component(.year, from: today)

        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        let dateString = formatter.string(from: today)

        let descriptor = FetchDescriptor<GiftIdea>()
        let allIdeas: [GiftIdea]
        do {
            allIdeas = try context.fetch(descriptor)
        } catch {
            AppLogger.data.error("GiftTransitionService: Geschenkideen laden fehlgeschlagen", error: error)
            return
        }

        let personDescriptor = FetchDescriptor<PersonRef>()
        let allPeople: [PersonRef]
        do {
            allPeople = try context.fetch(personDescriptor)
        } catch {
            AppLogger.data.error("GiftTransitionService: Personen laden fehlgeschlagen", error: error)
            return
        }

        let personMap = Dictionary(uniqueKeysWithValues: allPeople.map { ($0.id, $0) })

        var transitionCount = 0

        for idea in allIdeas where idea.status == .purchased {
            guard let person = personMap[idea.personId] else { continue }

            // Prüfen: Geburtstag dieses Jahr bereits vorbei?
            var birthdayComponents = calendar.dateComponents([.month, .day], from: person.birthday)
            birthdayComponents.year = currentYear

            // Schaltjahr-Fallback: 29.02. → 28.02. im Nicht-Schaltjahr
            if birthdayComponents.month == 2 && birthdayComponents.day == 29 {
                if calendar.date(from: birthdayComponents) == nil {
                    birthdayComponents.day = 28
                }
            }

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
            WidgetDataService.shared.updateWidgetData(from: context)
        }
    }
}
