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
    static let appGroupID = "group.com.hendrikgrueger.ai-presents"
    private static let userDefaultsKey = "widgetBirthdayEntries"

    private init() {}

    /// Schreibt einen JSON-Snapshot der nächsten Geburtstage in die App Group UserDefaults
    func updateWidgetData(from context: ModelContext) {
        let descriptor = FetchDescriptor<PersonRef>()
        guard let people = try? context.fetch(descriptor) else {
            AppLogger.data.error("WidgetDataService: Konnte Personen nicht laden")
            return
        }

        let today = Calendar.current.startOfDay(for: Date())

        // Alle Personen mit Tagen bis zum nächsten Geburtstag sortieren
        let entries: [WidgetBirthdayEntry] = people.compactMap { person in
            guard let daysUntil = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) else {
                return nil
            }

            let nextBirthday = BirthdayCalculator.nextBirthday(for: person.birthday, from: today)
            let nextAge: Int
            if !person.birthYearKnown {
                nextAge = 0
            } else if let nb = nextBirthday {
                nextAge = BirthdayCalculator.age(for: person.birthday, on: nb) ?? 0
            } else {
                nextAge = (BirthdayCalculator.age(for: person.birthday, on: today) ?? 0) + 1
            }

            let giftStatus = computeGiftStatus(for: person)

            return WidgetBirthdayEntry(
                id: person.id,
                displayName: person.displayName,
                daysUntil: daysUntil,
                nextAge: nextAge,
                relation: person.relation,
                giftStatus: giftStatus,
                skipGift: person.skipGift
            )
        }
        .sorted { $0.daysUntil < $1.daysUntil }

        let topEntries = Array(entries.prefix(10))

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

    /// Berechnet den Gift-Status-String für eine Person (konsistent mit BirthdayRow)
    private func computeGiftStatus(for person: PersonRef) -> String {
        if person.skipGift {
            return "skip"
        }

        guard let ideas = person.giftIdeas, !ideas.isEmpty else {
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
