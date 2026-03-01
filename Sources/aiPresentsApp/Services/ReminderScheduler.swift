import Foundation
import UserNotifications

class ReminderScheduler: ObservableObject {
    static let shared = ReminderScheduler()

    private init() {}

    func scheduleReminders(for person: PersonRef, rule: ReminderRule) {
        guard rule.enabled else { return }

        let center = UNUserNotificationCenter.current()

        // Request permission
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
                return
            }

            guard granted else { return }

            // Schedule reminders for each lead day
            for leadDay in rule.leadDays {
                self.scheduleReminder(for: person, leadDay: leadDay, rule: rule)
            }
        }
    }

    private func scheduleReminder(for person: PersonRef, leadDay: Int, rule: ReminderRule) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentYear = calendar.component(.year, from: today)

        // Get next birthday
        var components = calendar.dateComponents([.month, .day], from: person.birthday)
        components.year = currentYear
        var birthday = calendar.date(from: components) ?? person.birthday

        // If birthday already passed this year, use next year
        if birthday < today {
            components.year = currentYear + 1
            birthday = calendar.date(from: components) ?? birthday
        }

        // Calculate notification date
        let notificationDate = calendar.date(byAdding: .day, value: -leadDay, to: birthday) ?? birthday

        // Check quiet hours
        let hour = calendar.component(.hour, from: notificationDate)
        if hour >= rule.quietHoursStart || hour < rule.quietHoursEnd {
            // Adjust to morning
            var adjustedComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
            adjustedComponents.hour = 9
            adjustedComponents.minute = 0
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "\(person.displayName)s Geburtstag"
        content.body = "In \(leadDay) Tagen! Zeit für ein Geschenk."
        content.sound = .default

        // Create trigger
        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: "birthday_\(person.id.uuidString)_\(leadDay)",
            content: content,
            trigger: trigger
        )

        // Add request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelReminders(for person: PersonRef) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let idsToRemove = requests
                .filter { $0.identifier.contains("birthday_\(person.id.uuidString)") }
                .map { $0.identifier }

            center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
    }
}
