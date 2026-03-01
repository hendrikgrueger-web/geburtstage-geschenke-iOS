import Foundation
import SwiftData
import Calendar

class SampleDataService {
    static func createSampleData(in context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()

        // Create people with upcoming birthdays
        let person1 = PersonRef(
            displayName: "Anna Müller",
            birthday: calendar.date(byAdding: .day, value: 5, to: today) ?? today,
            relation: "Schwester"
        )

        let person2 = PersonRef(
            displayName: "Thomas Schmidt",
            birthday: calendar.date(byAdding: .day, value: 12, to: today) ?? today,
            relation: "Freund"
        )

        let person3 = PersonRef(
            displayName: "Lisa Weber",
            birthday: calendar.date(byAdding: .day, value: 25, to: today) ?? today,
            relation: "Kollegin"
        )

        // Add gift ideas
        let idea1 = GiftIdea(
            personId: person1.id,
            title: "Blumenstrauß",
            note: "Liebt weiße Rosen",
            budgetMin: 25,
            budgetMax: 50,
            tags: ["Blumen", "Romantisch"],
            status: .idea
        )

        let idea2 = GiftIdea(
            personId: person1.id,
            title: "Schmuck",
            note: "Einfache Kette mit Anhänger",
            budgetMin: 80,
            budgetMax: 150,
            link: "https://example.com/jewelry",
            tags: ["Schmuck", "Accessoires"],
            status: .planned
        )

        let idea3 = GiftIdea(
            personId: person2.id,
            title: "Bier-Set",
            note: "Spezialbiere aus Craft-Brauerei",
            budgetMin: 30,
            budgetMax: 60,
            tags: ["Bier", "Essen"],
            status: .idea
        )

        let idea4 = GiftIdea(
            personId: person3.id,
            title: "Notizbuch Set",
            note: "Hochwertiges Papier, Leder-Einband",
            budgetMin: 20,
            budgetMax: 40,
            tags: ["Büro", "Kreativ"],
            status: .idea
        )

        // Add gift history
        let history1 = GiftHistory(
            personId: person1.id,
            title: "Parfüm",
            category: "Kosmetik",
            year: calendar.component(.year, from: today) - 1
        )

        // Create reminder rule
        let reminderRule = ReminderRule(
            leadDays: [30, 14, 7, 2],
            quietHoursStart: 22,
            quietHoursEnd: 8,
            enabled: true
        )

        // Insert all
        context.insert(person1)
        context.insert(person2)
        context.insert(person3)
        context.insert(idea1)
        context.insert(idea2)
        context.insert(idea3)
        context.insert(idea4)
        context.insert(history1)
        context.insert(reminderRule)
    }

    static func clearSampleData(in context: ModelContext) {
        do {
            try context.deleteContainer()
        } catch {
            print("Failed to clear sample data: \(error)")
        }
    }
}
