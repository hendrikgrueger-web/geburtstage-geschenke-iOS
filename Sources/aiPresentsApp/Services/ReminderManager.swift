import Foundation
import SwiftData
import UserNotifications

@MainActor
class ReminderManager: ObservableObject {
    static let shared = ReminderManager()

    private let modelContext: ModelContext
    private let center = UNUserNotificationCenter.current()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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

        let descriptor = FetchDescriptor<PersonRef>()
        guard let people = try? modelContext.fetch(descriptor) else {
            return
        }

        for person in people {
            await scheduleReminders(for: person)
        }
    }

    private func checkPermission() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    private func scheduleReminders(for person: PersonRef) async {
        let leadDays = [30, 14, 7, 2]

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let nextBirthday = nextBirthday(for: person, from: today) else {
            return
        }

        for leadDay in leadDays {
            await scheduleReminder(for: person, nextBirthday: nextBirthday, leadDay: leadDay)
        }
    }

    private func scheduleReminder(for person: PersonRef, nextBirthday: Date, leadDay: Int) async {
        let calendar = Calendar.current
        let notificationDate = calendar.date(byAdding: .day, value: -leadDay, to: nextBirthday) ?? nextBirthday

        // Skip if already passed
        let today = calendar.startOfDay(for: Date())
        if notificationDate < today {
            return
        }

        // Quiet hours check (22:00 - 08:00)
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let hour = components.hour ?? 0

        if hour >= 22 || hour < 8 {
            components.hour = 9
            components.minute = 0
        }

        // Create content
        let content = UNMutableNotificationContent()
        content.title = "\(person.displayName)s Geburtstag"
        content.body = notificationBody(for: leadDay)
        content.sound = .default
        content.badge = 1

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
