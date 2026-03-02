import Foundation
import SwiftData

class SampleDataService {
    static func createSampleData(in context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()

        // Create people with upcoming birthdays
        let person1 = PersonRef(
            contactIdentifier: "",
            displayName: "Anna Müller",
            birthday: calendar.date(byAdding: .day, value: 5, to: today) ?? today,
            relation: "Schwester"
        )

        let person2 = PersonRef(
            contactIdentifier: "",
            displayName: "Thomas Schmidt",
            birthday: calendar.date(byAdding: .day, value: 12, to: today) ?? today,
            relation: "Freund"
        )

        let person3 = PersonRef(
            contactIdentifier: "",
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
            status: .idea,
            tags: ["Blumen", "Romantisch"]
        )

        let idea2 = GiftIdea(
            personId: person1.id,
            title: "Schmuck",
            note: "Einfache Kette mit Anhänger",
            budgetMin: 80,
            budgetMax: 150,
            link: "https://example.com/jewelry",
            status: .planned,
            tags: ["Schmuck", "Accessoires"]
        )

        let idea3 = GiftIdea(
            personId: person2.id,
            title: "Bier-Set",
            note: "Spezialbiere aus Craft-Brauerei",
            budgetMin: 30,
            budgetMax: 60,
            status: .idea,
            tags: ["Bier", "Essen"]
        )

        let idea4 = GiftIdea(
            personId: person3.id,
            title: "Notizbuch Set",
            note: "Hochwertiges Papier, Leder-Einband",
            budgetMin: 20,
            budgetMax: 40,
            status: .idea,
            tags: ["Büro", "Kreativ"]
        )

        // Add gift history
        let history1 = GiftHistory(
            personId: person1.id,
            title: "Parfüm",
            category: "Kosmetik",
            year: calendar.component(.year, from: today) - 1,
            budget: 65,
            note: "Liebt blumige Düfte"
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
            try context.delete(model: ReminderRule.self)
            try context.delete(model: GiftHistory.self)
            try context.delete(model: GiftIdea.self)
            try context.delete(model: PersonRef.self)
            AppLogger.data.info("Sample data cleared successfully")
        } catch {
            AppLogger.data.error("Failed to clear sample data", error: error)
        }
    }
}
