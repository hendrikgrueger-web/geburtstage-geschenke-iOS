import Foundation
import SwiftData
import UserNotifications

// MARK: - ReminderManagerProtocol

/// Protocol für den Erinnerungs-Manager — ermöglicht Dependency Injection und Testbarkeit.
@MainActor
protocol ReminderManagerProtocol: AnyObject {
    func requestPermission() async -> Bool
    func checkPermission() async -> Bool
    func scheduleAllReminders() async
    func cancelReminders(for person: PersonRef) async
    func cancelBirthdayReminders() async
    func cancelAllReminders() async
}

// MARK: - ReminderManager

@MainActor
@Observable
class ReminderManager: ReminderManagerProtocol {
    private static let birthdayNotificationPrefix = "birthday_"
    private let modelContext: ModelContext
    private let center = UNUserNotificationCenter.current()

    nonisolated(unsafe) private static var _shared: ReminderManager?
    nonisolated(unsafe) private static let lock = NSLock() // nonisolated(unsafe) nötig für deinit-Zugriff

    static var shared: ReminderManager? {
        lock.lock()
        defer { lock.unlock() }
        return _shared
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Self.lock.lock()
        Self._shared = self
        Self.lock.unlock()
    }

    deinit {
        Self.lock.lock()
        if Self._shared === self { Self._shared = nil }
        Self.lock.unlock()
    }

    func requestPermission() async -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        do { return try await center.requestAuthorization(options: options) }
        catch {
            AppLogger.reminder.error("Failed to request notification permission", error: error)
            return false
        }
    }

    func checkPermission() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    func scheduleAllReminders() async {
        guard await checkPermission() else {
            AppLogger.reminder.warning("Notification permission not granted")
            return
        }
        guard let rule = currentRule(), rule.enabled else {
            AppLogger.reminder.debug("Reminder rule disabled or not found")
            return
        }
        await cancelBirthdayReminders()
        let descriptor = FetchDescriptor<PersonRef>()
        guard let people = try? modelContext.fetch(descriptor) else { return }
        for person in people { await scheduleReminders(for: person, rule: rule) }
    }

    private func currentRule() -> ReminderRule? {
        let descriptor = FetchDescriptor<ReminderRule>()
        guard let rules = try? modelContext.fetch(descriptor) else { return defaultRule() }
        return rules.first ?? defaultRule()
    }

    private func defaultRule() -> ReminderRule {
        ReminderRule(
            leadDays: AppConfig.Reminder.defaultLeadDays,
            quietHoursStart: AppConfig.Reminder.defaultQuietHoursStart,
            quietHoursEnd: AppConfig.Reminder.defaultQuietHoursEnd,
            enabled: true
        )
    }

    private func isWithinQuietHours(hour: Int, start: Int, end: Int) -> Bool {
        if start < end { return hour >= start && hour < end }
        return hour >= start || hour < end
    }

    private func scheduleReminders(for person: PersonRef, rule: ReminderRule) async {
        let leadDays = rule.leadDays.sorted(by: >)
        guard !leadDays.isEmpty else { return }
        let today = Calendar.current.startOfDay(for: Date())
        guard let nextBirthday = BirthdayCalculator.nextBirthday(for: person.birthday, from: today) else { return }
        for leadDay in leadDays {
            await scheduleReminder(for: person, nextBirthday: nextBirthday, leadDay: leadDay,
                                   quietHoursStart: rule.quietHoursStart, quietHoursEnd: rule.quietHoursEnd)
        }
    }

    private func scheduleReminder(for person: PersonRef, nextBirthday: Date, leadDay: Int,
                                  quietHoursStart: Int, quietHoursEnd: Int) async {
        let calendar = Calendar.current
        let notificationDate = calendar.date(byAdding: .day, value: -leadDay, to: nextBirthday) ?? nextBirthday
        let today = calendar.startOfDay(for: Date())
        if notificationDate < today { return }

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let hour = components.hour ?? 0

        if isWithinQuietHours(hour: hour, start: quietHoursStart, end: quietHoursEnd) {
            if quietHoursStart < quietHoursEnd {
                components.hour = quietHoursEnd; components.minute = 0
            } else if hour >= quietHoursStart {
                let nextDay = calendar.date(byAdding: .day, value: 1, to: notificationDate) ?? notificationDate
                var nextComponents = calendar.dateComponents([.year, .month, .day], from: nextDay)
                nextComponents.hour = quietHoursEnd; nextComponents.minute = 0
                components = nextComponents
            } else {
                components.hour = quietHoursEnd; components.minute = 0
            }
        }

        if let adjustedDate = calendar.date(from: components), adjustedDate < Date() {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: adjustedDate) ?? adjustedDate
            var nextComponents = calendar.dateComponents([.year, .month, .day], from: nextDay)
            nextComponents.hour = components.hour; nextComponents.minute = components.minute
            components = nextComponents
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "\(person.displayName)'s Geburtstag")
        content.body = notificationBody(for: leadDay)
        content.sound = .default; content.badge = 1
        content.userInfo = ["personId": person.id.uuidString, "leadDay": leadDay]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(Self.birthdayNotificationPrefix)\(person.id.uuidString)_\(leadDay)_\(nextBirthday.timeIntervalSince1970)",
            content: content, trigger: trigger)

        do {
            try await center.add(request)
            AppLogger.reminder.debug("Scheduled reminder for \(person.displayName): \(leadDay) days before")
        } catch {
            AppLogger.reminder.error("Failed to schedule notification for \(person.displayName)", error: error)
        }
    }

    private func notificationBody(for leadDay: Int) -> String {
        switch leadDay {
        case 30: return String(localized: "In 30 Tagen ist es soweit! Zeit für Geschenkideen.")
        case 14: return String(localized: "Nur noch 2 Wochen! Hast du etwas gefunden?")
        case 7: return String(localized: "Nur noch eine Woche! Zeit zu handeln.")
        case 2: return String(localized: "Bald ist es soweit! Letzter Anstoß.")
        default: return String(localized: "Geburtstag steht bevor!")
        }
    }

    /// Fixed: Uses async/await pattern to avoid race conditions
    func cancelReminders(for person: PersonRef) async {
        let requests = await center.pendingNotificationRequests()
        let idsToRemove = requests
            .filter { $0.identifier.contains("\(Self.birthdayNotificationPrefix)\(person.id.uuidString)") }
            .map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        AppLogger.reminder.debug("Cancelled reminders for \(person.displayName)")
    }

    func cancelBirthdayReminders() async {
        let requests = await center.pendingNotificationRequests()
        let idsToRemove = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.birthdayNotificationPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        AppLogger.reminder.debug("All birthday reminders cancelled")
    }

    func cancelAllReminders() async {
        center.removeAllPendingNotificationRequests()
        AppLogger.reminder.debug("All reminders cancelled")
    }
}
