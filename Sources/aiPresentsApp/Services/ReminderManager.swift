import Foundation
import SwiftData
import UserNotifications

extension ModelContext {
    static var placeholder: ModelContext {
        let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            fatalError("Failed to create placeholder ModelContainer")
        }
        return container.mainContext
    }
}

@MainActor
class ReminderManager: ObservableObject {
    private var modelContext: ModelContext
    private let center = UNUserNotificationCenter.current()
    static var shared: ReminderManager!

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Self.shared = self
    }

    func updateModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func requestPermission() async -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        return await center.requestAuthorization(options: options)
    }

    func scheduleAllReminders() async {
        guard await checkPermission() else {
            print("Notification permission not granted")
            return
        }

        guard let rule = currentRule(), rule.enabled else {
            return
        }

        // First, cancel existing reminders to avoid duplicates
        await cancelAllReminders()

        let descriptor = FetchDescriptor<PersonRef>()
        guard let people = try? modelContext.fetch(descriptor) else {
            return
        }

        for person in people {
            await scheduleReminders(for: person, rule: rule)
        }
    }

    private func checkPermission() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    private func currentRule() -> ReminderRule? {
        let descriptor = FetchDescriptor<ReminderRule>()
        guard let rules = try? modelContext.fetch(descriptor) else {
            return ReminderRule(leadDays: [30, 14, 7, 2], quietHoursStart: 22, quietHoursEnd: 8, enabled: true)
        }
        return rules.first ?? ReminderRule(leadDays: [30, 14, 7, 2], quietHoursStart: 22, quietHoursEnd: 8, enabled: true)
    }

    private func isWithinQuietHours(hour: Int, start: Int, end: Int) -> Bool {
        if start < end {
            return hour >= start && hour < end
        }
        return hour >= start || hour < end
    }

    private func scheduleReminders(for person: PersonRef, rule: ReminderRule) async {
        let leadDays = rule.leadDays.sorted(by: >)

        guard !leadDays.isEmpty else {
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let nextBirthday = nextBirthday(for: person, from: today) else {
            return
        }

        for leadDay in leadDays {
            await scheduleReminder(
                for: person,
                nextBirthday: nextBirthday,
                leadDay: leadDay,
                quietHoursStart: rule.quietHoursStart,
                quietHoursEnd: rule.quietHoursEnd
            )
        }
    }

    private func scheduleReminder(
        for person: PersonRef,
        nextBirthday: Date,
        leadDay: Int,
        quietHoursStart: Int,
        quietHoursEnd: Int
    ) async {
        let calendar = Calendar.current
        let notificationDate = calendar.date(byAdding: .day, value: -leadDay, to: nextBirthday) ?? nextBirthday

        // Skip if already passed
        let today = calendar.startOfDay(for: Date())
        if notificationDate < today {
            return
        }

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let hour = components.hour ?? 0

        if isWithinQuietHours(hour: hour, start: quietHoursStart, end: quietHoursEnd) {
            if quietHoursStart < quietHoursEnd {
                components.hour = quietHoursEnd
                components.minute = 0
            } else if hour >= quietHoursStart {
                let nextDay = calendar.date(byAdding: .day, value: 1, to: notificationDate) ?? notificationDate
                var nextComponents = calendar.dateComponents([.year, .month, .day], from: nextDay)
                nextComponents.hour = quietHoursEnd
                nextComponents.minute = 0
                components = nextComponents
            } else {
                components.hour = quietHoursEnd
                components.minute = 0
            }
        }

        if let adjustedDate = calendar.date(from: components), adjustedDate < Date() {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: adjustedDate) ?? adjustedDate
            var nextComponents = calendar.dateComponents([.year, .month, .day], from: nextDay)
            nextComponents.hour = components.hour
            nextComponents.minute = components.minute
            components = nextComponents
        }

        // Create content
        let content = UNMutableNotificationContent()
        content.title = "\(person.displayName)s Geburtstag"
        content.body = notificationBody(for: leadDay)
        content.sound = .default
        content.badge = 1
        content.userInfo = ["personId": person.id.uuidString, "leadDay": leadDay]

        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: "birthday_\(person.id.uuidString)_\(leadDay)_\(nextBirthday.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        // Add request
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    private func notificationBody(for leadDay: Int) -> String {
        switch leadDay {
        case 30:
            return "In 30 Tagen ist es soweit! Zeit für Geschenkideen."
        case 14:
            return "Nur noch 2 Wochen! Hast du etwas gefunden?"
        case 7:
            return "Nur noch eine Woche! Zeit zu handeln."
        case 2:
            return "Bald ist es soweit! Letzter Anstoß."
        default:
            return "Geburtstag steht bevor!"
        }
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

    func cancelReminders(for person: PersonRef) async {
        let descriptor = FetchDescriptor<UNNotificationRequest>()
        // Get all pending requests and filter by person ID
        center.getPendingNotificationRequests { requests in
            let idsToRemove = requests
                .filter { $0.identifier.contains("birthday_\(person.id.uuidString)") }
                .map { $0.identifier }

            self.center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
    }

    func cancelAllReminders() async {
        center.removeAllPendingNotificationRequests()
    }
}
