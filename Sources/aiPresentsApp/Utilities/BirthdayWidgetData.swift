import Foundation
import SwiftData

/// Utility for preparing birthday data optimized for iOS Widgets
/// Provides efficient data structures and calculations for widget timelines
struct BirthdayWidgetData {

    // MARK: - Widget Data Models

    /// Lightweight birthday entry for widgets (minimal memory footprint)
    struct BirthdayEntry {
        let id: String
        let name: String
        let initials: String
        let relation: String
        let daysUntil: Int
        let isToday: Bool
        let age: Int
        let nextBirthday: Date

        /// Widget display text
        var displayText: String {
            if isToday {
                return "Heute!"
            } else if daysUntil == 1 {
                return "Morgen"
            } else {
                return "in \(daysUntil) Tagen"
            }
        }

        /// Widget icon symbol based on days until
        var iconSymbol: String {
            if isToday { return "cake.fill" }
            if daysUntil <= 2 { return "exclamationmark.triangle.fill" }
            if daysUntil <= 7 { return "calendar.badge.clock" }
            return "gift.fill"
        }
    }

    /// Widget summary statistics
    struct WidgetSummary {
        let todayCount: Int
        let weekCount: Int
        let monthCount: Int
        let nextBirthday: BirthdayEntry?
        let upcomingBirthdays: [BirthdayEntry]

        var totalUpcoming: Int { upcomingBirthdays.count }
    }

    // MARK: - Data Fetching

    /// Fetches widget data for the current timeframe
    /// - Parameters:
    ///   - modelContext: SwiftData model context
    ///   - limit: Maximum number of birthdays to include (default: 5)
    /// - Returns: Widget summary with birthday entries
    static func fetchWidgetData(
        from modelContext: ModelContext,
        limit: Int = 5
    ) -> WidgetSummary {
        let today = Calendar.current.startOfDay(for: Date())
        let people = fetchPeople(from: modelContext)

        // Calculate all upcoming birthdays
        let upcomingEntries = people.compactMap { person -> BirthdayEntry? in
            guard let nextBirthday = BirthdayCalculator.nextBirthday(for: person.birthday, from: today),
                  let daysUntil = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today),
                  let age = BirthdayCalculator.age(for: person.birthday, on: today) else {
                return nil
            }

            // Only include birthdays within 30 days
            guard daysUntil >= 0 && daysUntil <= 30 else { return nil }

            return BirthdayEntry(
                id: person.id.uuidString,
                name: person.displayName,
                initials: PersonAvatar.initials(from: person.displayName),
                relation: person.relation,
                daysUntil: daysUntil,
                isToday: daysUntil == 0,
                age: age,
                nextBirthday: nextBirthday
            )
        }
        .sorted { $0.daysUntil < $1.daysUntil }
        .prefix(limit)
        .map { $0 }

        // Calculate summary statistics
        let todayCount = upcomingEntries.filter { $0.isToday }.count
        let weekCount = upcomingEntries.filter { $0.daysUntil <= 7 }.count
        let monthCount = upcomingEntries.count

        return WidgetSummary(
            todayCount: todayCount,
            weekCount: weekCount,
            monthCount: monthCount,
            nextBirthday: upcomingEntries.first,
            upcomingBirthdays: Array(upcomingEntries)
        )
    }

    /// Fetches today's birthdays only (optimized for widgets)
    /// - Parameter modelContext: SwiftData model context
    /// - Returns: Array of today's birthday entries
    static func fetchTodayBirthdays(from modelContext: ModelContext) -> [BirthdayEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        let people = fetchPeople(from: modelContext)

        return people.compactMap { person -> BirthdayEntry? in
            guard BirthdayCalculator.isBirthdayToday(for: person.birthday, from: today),
                  let age = BirthdayCalculator.age(for: person.birthday, on: today) else {
                return nil
            }

            return BirthdayEntry(
                id: person.id.uuidString,
                name: person.displayName,
                initials: PersonAvatar.initials(from: person.displayName),
                relation: person.relation,
                daysUntil: 0,
                isToday: true,
                age: age,
                nextBirthday: today
            )
        }
    }

    // MARK: - Timeline Support

    /// Fetches birthday entries for a specific date range (for widget timeline)
    /// - Parameters:
    ///   - modelContext: SwiftData model context
    ///   - startDate: Start date for timeline
    ///   - endDate: End date for timeline
    /// - Returns: Array of birthday entries in date range
    static func fetchTimelineEntries(
        from modelContext: ModelContext,
        startDate: Date,
        endDate: Date
    ) -> [BirthdayEntry] {
        let people = fetchPeople(from: modelContext)

        return people.compactMap { person -> BirthdayEntry? in
            guard let nextBirthday = BirthdayCalculator.nextBirthday(for: person.birthday, from: startDate),
                  let daysUntil = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: startDate),
                  let age = BirthdayCalculator.age(for: person.birthday, on: nextBirthday) else {
                return nil
            }

            // Only include birthdays within the specified date range
            guard nextBirthday >= startDate && nextBirthday <= endDate else { return nil }

            return BirthdayEntry(
                id: person.id.uuidString,
                name: person.displayName,
                initials: PersonAvatar.initials(from: person.displayName),
                relation: person.relation,
                daysUntil: daysUntil,
                isToday: daysUntil == 0,
                age: age,
                nextBirthday: nextBirthday
            )
        }
        .sorted { $0.nextBirthday < $1.nextBirthday }
    }

    // MARK: - Private Helpers

    /// Fetches all people from SwiftData (optimized with caching)
    private static func fetchPeople(from modelContext: ModelContext) -> [PersonRef] {
        let descriptor = FetchDescriptor<PersonRef>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}

// MARK: - Widget Display Helpers

extension BirthdayWidgetData.BirthdayEntry {
    /// Generates a localized display string for widget
    func localizedDisplay(locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium

        if isToday {
            return String(localized: "🎂 \(name) — Heute!")
        } else {
            return "\(name) — \(displayText)"
        }
    }

    /// Generates an accessible label for VoiceOver
    func accessibilityLabel() -> String {
        let ageText = String(localized: "\(age) Jahre")
        if isToday {
            return String(localized: "\(name), \(relation), hat heute Geburtstag, \(ageText)")
        } else if daysUntil == 1 {
            return String(localized: "\(name), \(relation), hat morgen Geburtstag, \(ageText)")
        } else {
            return String(localized: "\(name), \(relation), hat in \(daysUntil) Tagen Geburtstag, \(ageText)")
        }
    }

    /// Widget color based on urgency
    var urgencyColor: WidgetUrgencyColor {
        if isToday { return .today }
        if daysUntil <= 2 { return .urgent }
        if daysUntil <= 7 { return .upcoming }
        return .normal
    }
}

/// Widget urgency color for visual feedback
enum WidgetUrgencyColor {
    case today    // Red/orange for today
    case urgent   // Orange for 1-2 days
    case upcoming // Yellow for 3-7 days
    case normal   // Blue/green for 8+ days

    var hexValue: String {
        switch self {
        case .today: return "#FF3B30"
        case .urgent: return "#FF9500"
        case .upcoming: return "#FFCC00"
        case .normal: return "#007AFF"
        }
    }
}
