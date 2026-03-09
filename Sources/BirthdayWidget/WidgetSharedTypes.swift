import Foundation

/// Kopie von WidgetBirthdayEntry für das Widget-Target (kein Zugriff auf App-Target)
struct WidgetBirthdayEntry: Codable, Sendable {
    let id: UUID
    let displayName: String
    let daysUntil: Int
    let nextAge: Int
    let relation: String
    let giftStatus: String
    let skipGift: Bool
}

/// Liest Widget-Daten aus App Group UserDefaults
enum WidgetDataReader {
    static let appGroupID = "group.com.hendrikgrueger.birthdays-presents-ai"
    private static let userDefaultsKey = "widgetBirthdayEntries"

    static func readEntries() -> [WidgetBirthdayEntry] {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: userDefaultsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([WidgetBirthdayEntry].self, from: data)
        } catch {
            return []
        }
    }
}
