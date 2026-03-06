import Foundation

/// Utility for birthday-related date calculations and formatting
struct BirthdayDateHelper {

    // MARK: - Date Ranges

    /// Get the start of today (midnight)
    static var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    /// Get the end of today (23:59:59)
    static var endOfToday: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: today) ?? today
    }

    /// Get the start of tomorrow
    static var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
    }

    /// Get a date N days from now
    static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: today) ?? today
    }

    /// Get date range for "upcoming" birthdays (next 30 days)
    static var upcomingRange: ClosedRange<Date> {
        today...daysFromNow(30)
    }

    /// Get date range for "soon" birthdays (next 7 days)
    static var soonRange: ClosedRange<Date> {
        today...daysFromNow(7)
    }

    // MARK: - Birthday Calculations (delegiert an BirthdayCalculator für Cache + Thread-Safety)

    /// Calculate age based on birthday
    static func age(from birthday: Date, asOf date: Date = today) -> Int {
        BirthdayCalculator.age(for: birthday, on: date) ?? 0
    }

    /// Get the next occurrence of a birthday after a given date
    static func nextBirthday(from birthday: Date, after date: Date = today) -> Date? {
        BirthdayCalculator.nextBirthday(for: birthday, from: date)
    }

    /// Days until next birthday
    static func daysUntilBirthday(from birthday: Date, asOf date: Date = today) -> Int? {
        BirthdayCalculator.daysUntilBirthday(for: birthday, from: date)
    }

    /// Check if birthday is today
    static func isBirthdayToday(from birthday: Date, asOf date: Date = today) -> Bool {
        BirthdayCalculator.isBirthdayToday(for: birthday, from: date)
    }

    /// Check if birthday is tomorrow
    static func isBirthdayTomorrow(from birthday: Date, asOf date: Date = today) -> Bool {
        BirthdayCalculator.daysUntilBirthday(for: birthday, from: date) == 1
    }

    /// Check if birthday is within the next N days
    static func isBirthdayWithinDays(_ days: Int, from birthday: Date, asOf date: Date = today) -> Bool {
        BirthdayCalculator.isBirthdayWithinDays(for: birthday, days: days, from: date)
    }

    /// Get zodiac sign for a birthday (German, for API/data compatibility)
    static func zodiacSign(from birthday: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: birthday)
        let month = calendar.component(.month, from: birthday)

        switch (month, day) {
        case (3, 21...31), (4, 1...19): return "♈ Widder"
        case (4, 20...30), (5, 1...20): return "♉ Stier"
        case (5, 21...31), (6, 1...20): return "♊ Zwilling"
        case (6, 21...30), (7, 1...22): return "♋ Krebs"
        case (7, 23...31), (8, 1...22): return "♌ Löwe"
        case (8, 23...31), (9, 1...22): return "♍ Jungfrau"
        case (9, 23...30), (10, 1...22): return "♎ Waage"
        case (10, 23...31), (11, 1...21): return "♏ Skorpion"
        case (11, 22...30), (12, 1...21): return "♐ Schütze"
        case (12, 22...31), (1, 1...19): return "♑ Steinbock"
        case (1, 20...31), (2, 1...18): return "♒ Wassermann"
        case (2, 19...29), (3, 1...20): return "♓ Fische"
        default: return ""
        }
    }

    /// Get localized zodiac sign for a birthday (for UI display)
    static func localizedZodiacSign(from birthday: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: birthday)
        let month = calendar.component(.month, from: birthday)

        switch (month, day) {
        case (3, 21...31), (4, 1...19): return String(localized: "♈ Widder")
        case (4, 20...30), (5, 1...20): return String(localized: "♉ Stier")
        case (5, 21...31), (6, 1...20): return String(localized: "♊ Zwilling")
        case (6, 21...30), (7, 1...22): return String(localized: "♋ Krebs")
        case (7, 23...31), (8, 1...22): return String(localized: "♌ Löwe")
        case (8, 23...31), (9, 1...22): return String(localized: "♍ Jungfrau")
        case (9, 23...30), (10, 1...22): return String(localized: "♎ Waage")
        case (10, 23...31), (11, 1...21): return String(localized: "♏ Skorpion")
        case (11, 22...30), (12, 1...21): return String(localized: "♐ Schütze")
        case (12, 22...31), (1, 1...19): return String(localized: "♑ Steinbock")
        case (1, 20...31), (2, 1...18): return String(localized: "♒ Wassermann")
        case (2, 19...29), (3, 1...20): return String(localized: "♓ Fische")
        default: return ""
        }
    }

    // MARK: - Birthday Milestones

    /// Check if age is a milestone (18, 21, 30, 40, 50, 60, 70, 80, 90, 100)
    static func isMilestoneAge(age: Int) -> Bool {
        [18, 21, 30, 40, 50, 60, 70, 80, 90, 100].contains(age)
    }

    /// Get milestone name for age
    static func milestoneName(for age: Int) -> String? {
        switch age {
        case 18: return "🎉 " + String(localized: "Volljährigkeit")
        case 21: return "🎉 " + String(localized: "Große Mehrheit")
        case 30: return "🎉 " + String(localized: "30. Geburtstag")
        case 40: return "🎉 " + String(localized: "40. Geburtstag")
        case 50: return "🎉 " + String(localized: "50. Geburtstag")
        case 60: return "🎉 " + String(localized: "60. Geburtstag")
        case 70: return "🎉 " + String(localized: "70. Geburtstag")
        case 80: return "🎉 " + String(localized: "80. Geburtstag")
        case 90: return "🎉 " + String(localized: "90. Geburtstag")
        case 100: return "🎉 " + String(localized: "100. Geburtstag")
        default: return nil
        }
    }

    // MARK: - Formatting

    /// Format birthday for display (day and month only)
    static func formatBirthdayShort(_ birthday: Date, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.setLocalizedDateFormatFromTemplate("dd.MMM")
        formatter.locale = locale
        return formatter.string(from: birthday)
    }

    /// Format full birthday (with year)
    static func formatBirthdayFull(_ birthday: Date, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = locale
        return formatter.string(from: birthday)
    }

    /// Format relative date description
    static func relativeDateDescription(from birthday: Date, asOf date: Date = today) -> String {
        guard let daysUntil = daysUntilBirthday(from: birthday, asOf: date) else {
            return String(localized: "Unbekannt")
        }

        let months = daysUntil / 30
        switch daysUntil {
        case 0:
            return "🎉 " + String(localized: "Heute!")
        case 1:
            return "📅 " + String(localized: "Morgen")
        case 2...7:
            return "📅 " + String(localized: "In \(daysUntil) Tagen")
        case 8...30:
            return "📅 " + String(localized: "\(daysUntil) Tage")
        case 31...60:
            return "📅 " + String(localized: "In \(months) Monaten")
        case 61...365:
            return "📅 " + String(localized: "In \(months) Monaten")
        case 366...:
            return "📅 " + String(localized: "Nächstes Jahr")
        default:
            return String(localized: "Unbekannt")
        }
    }

    /// Format age with optional milestone
    static func formatAge(birthday: Date, asOf date: Date = today) -> String {
        let currentAge = age(from: birthday, asOf: date)

        if let milestone = milestoneName(for: currentAge) {
            return "\(currentAge) \(milestone)"
        }

        return String(localized: "\(currentAge) Jahre")
    }

    // MARK: - Grouping

    /// Group birthdays by time period (Today, Tomorrow, This Week, This Month, Later)
    enum BirthdayPeriod: String, CaseIterable {
        case today = "Heute"
        case tomorrow = "Morgen"
        case thisWeek = "Diese Woche"
        case thisMonth = "Diesen Monat"
        case later = "Später"

        var localizedName: String {
            switch self {
            case .today: return String(localized: "Heute")
            case .tomorrow: return String(localized: "Morgen")
            case .thisWeek: return String(localized: "Diese Woche")
            case .thisMonth: return String(localized: "Diesen Monat")
            case .later: return String(localized: "Später")
            }
        }
    }

    /// Get the period for a birthday
    static func period(for birthday: Date, asOf date: Date = today) -> BirthdayPeriod {
        guard let daysUntil = daysUntilBirthday(from: birthday, asOf: date) else {
            return .later
        }

        switch daysUntil {
        case 0:
            return .today
        case 1:
            return .tomorrow
        case 2...7:
            return .thisWeek
        case 8...30:
            return .thisMonth
        default:
            return .later
        }
    }

    /// Check if a birthday falls in a specific period
    static func isInPeriod(_ period: BirthdayPeriod, for birthday: Date, asOf date: Date = today) -> Bool {
        return self.period(for: birthday, asOf: date) == period
    }

    // MARK: - Calendar Helpers

    private static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = .current
        return cal
    }

    /// Days between two dates (inclusive of end date)
    static func daysBetween(from start: Date, to end: Date) -> Int {
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max(0, components.day ?? 0)
    }

    /// Check if two dates are in the same month
    static func isInSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, equalTo: date2, toGranularity: .month)
    }

    /// Check if two dates are in the same year
    static func isInSameYear(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, equalTo: date2, toGranularity: .year)
    }
}

// MARK: - Extensions for Convenience

extension Date {
    /// Age as of this date
    var age: Int {
        BirthdayDateHelper.age(from: self)
    }

    /// Format as short birthday (day and month)
    var birthdayShort: String {
        BirthdayDateHelper.formatBirthdayShort(self)
    }

    /// Format as full birthday
    var birthdayFull: String {
        BirthdayDateHelper.formatBirthdayFull(self)
    }

    /// Relative description until next occurrence
    var relativeToNow: String {
        BirthdayDateHelper.relativeDateDescription(from: self)
    }
}

// MARK: - Tests Preview

#if DEBUG
extension BirthdayDateHelper {
    static var testCases: [(birthday: Date, expectedPeriod: BirthdayPeriod)] {
        let today = Date()
        var cases: [(Date, BirthdayPeriod)] = []

        // Today
        if let todayBirthday = Calendar.current.date(byAdding: .day, value: 0, to: today) {
            cases.append((todayBirthday, .today))
        }

        // Tomorrow
        if let tomorrowBirthday = Calendar.current.date(byAdding: .day, value: 1, to: today) {
            cases.append((tomorrowBirthday, .tomorrow))
        }

        // This week (5 days)
        if let weekBirthday = Calendar.current.date(byAdding: .day, value: 5, to: today) {
            cases.append((weekBirthday, .thisWeek))
        }

        // This month (20 days)
        if let monthBirthday = Calendar.current.date(byAdding: .day, value: 20, to: today) {
            cases.append((monthBirthday, .thisMonth))
        }

        // Later (60 days)
        if let laterBirthday = Calendar.current.date(byAdding: .day, value: 60, to: today) {
            cases.append((laterBirthday, .later))
        }

        return cases
    }
}
#endif
