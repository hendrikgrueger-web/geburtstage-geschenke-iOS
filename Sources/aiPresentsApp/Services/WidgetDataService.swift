import Foundation
import SwiftData
import WidgetKit

/// Leichtgewichtiger Codable-Struct für Widget-Daten
struct WidgetBirthdayEntry: Codable, Sendable {
    let id: UUID
    let displayName: String
    let daysUntil: Int
    let nextAge: Int
    let relation: String
    let giftStatus: String // "skip" | "purchased" | "planned" | "ideas:N" | "none"
    let skipGift: Bool
}

/// Service für Daten-Sharing zwischen App und Widget via App Group UserDefaults
@MainActor
final class WidgetDataService {
    static let shared = WidgetDataService()
    static let appGroupID = "group.com.hendrikgrueger.birthdays-presents-ai"
    private static let userDefaultsKey = "widgetBirthdayEntries"

    private init() {}

    static func refresh(using context: ModelContext?) {
        guard let context else { return }
        shared.updateWidgetData(from: context)
    }

    /// Schreibt einen JSON-Snapshot der nächsten Geburtstage in die App Group UserDefaults
    func updateWidgetData(from context: ModelContext) {
        let descriptor = FetchDescriptor<PersonRef>()
        guard let people = try? context.fetch(descriptor) else {
            AppLogger.data.error("WidgetDataService: Konnte Personen nicht laden")
            return
        }

        let giftDescriptor = FetchDescriptor<GiftIdea>()
        let allIdeas = (try? context.fetch(giftDescriptor)) ?? []
        let topEntries = Self.makeEntries(people: people, ideas: allIdeas)

        // In App Group UserDefaults schreiben
        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else {
            AppLogger.data.error("WidgetDataService: App Group UserDefaults nicht verfügbar")
            return
        }

        do {
            let data = try JSONEncoder().encode(topEntries)
            defaults.set(data, forKey: Self.userDefaultsKey)
            AppLogger.data.info("WidgetDataService: \(topEntries.count) Einträge geschrieben")
        } catch {
            AppLogger.data.error("WidgetDataService: JSON-Encoding fehlgeschlagen: \(error)")
        }

        // Widget-Timeline neu laden
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Liest Widget-Daten aus App Group UserDefaults (für Widget-Zugriff)
    static func readWidgetData() -> [WidgetBirthdayEntry] {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: userDefaultsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([WidgetBirthdayEntry].self, from: data)
        } catch {
            AppLogger.data.error("Widget-Daten konnten nicht gelesen werden: \(error)")
            return []
        }
    }

    static func makeEntries(
        people: [PersonRef],
        ideas: [GiftIdea],
        today: Date = Calendar.current.startOfDay(for: Date()),
        limit: Int = 10
    ) -> [WidgetBirthdayEntry] {
        let ideasByPerson = Dictionary(grouping: ideas, by: \.personId)

        let entries = people.compactMap { person -> WidgetBirthdayEntry? in
            guard let daysUntil = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) else {
                return nil
            }

            let nextBirthday = BirthdayCalculator.nextBirthday(for: person.birthday, from: today)
            let nextAge: Int
            if !person.birthYearKnown {
                nextAge = 0
            } else if let nextBirthday {
                nextAge = BirthdayCalculator.age(for: person.birthday, on: nextBirthday) ?? 0
            } else {
                nextAge = (BirthdayCalculator.age(for: person.birthday, on: today) ?? 0) + 1
            }

            return WidgetBirthdayEntry(
                id: person.id,
                displayName: person.displayName,
                daysUntil: daysUntil,
                nextAge: nextAge,
                relation: person.relation,
                giftStatus: computeGiftStatus(skipGift: person.skipGift, ideas: ideasByPerson[person.id] ?? []),
                skipGift: person.skipGift
            )
        }
        .sorted { $0.daysUntil < $1.daysUntil }

        return Array(entries.prefix(limit))
    }

    /// Berechnet den Gift-Status-String für eine Person (konsistent mit BirthdayRow)
    private static func computeGiftStatus(skipGift: Bool, ideas: [GiftIdea]) -> String {
        if skipGift {
            return "skip"
        }

        guard !ideas.isEmpty else {
            return "none"
        }

        if ideas.contains(where: { $0.status == .purchased || $0.status == .given }) {
            return "purchased"
        }

        if ideas.contains(where: { $0.status == .planned }) {
            return "planned"
        }

        let ideaCount = ideas.filter { $0.status == .idea }.count
        if ideaCount > 0 {
            return "ideas:\(ideaCount)"
        }

        return "none"
    }
}
