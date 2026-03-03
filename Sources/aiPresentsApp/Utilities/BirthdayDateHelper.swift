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

    // MARK: - Birthday Calculations

    /// Calculate age based on birthday
    static func age(from birthday: Date, asOf date: Date = today) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: date)
        return max(0, ageComponents.year ?? 0)
    }

    /// Get the next occurrence of a birthday after a given date
    static func nextBirthday(from birthday: Date, after date: Date = today) -> Date? {
        let calendar = Calendar.current

        var birthdayComponents = calendar.dateComponents([.month, .day], from: birthday)
        var currentYear = calendar.component(.year, from: date)

        // Try this year's birthday
        birthdayComponents.year = currentYear
        if let thisYearBirthday = calendar.date(from: birthdayComponents) {
            if thisYearBirthday >= date {
                return thisYearBirthday
            }
        } else {
            // Schaltjahr-Fallback: 29.02. → 28.02. im Nicht-Schaltjahr
            birthdayComponents.day = 28
            if let fallback = calendar.date(from: birthdayComponents), fallback >= date {
                return fallback
            }
        }

        // If this year's birthday has passed, try next year
        currentYear += 1
        birthdayComponents.year = currentYear
        // 29.02. im nächsten Jahr probieren
        let originalDay = calendar.component(.day, from: birthday)
        birthdayComponents.day = originalDay
        if let nextYear = calendar.date(from: birthdayComponents) {
            return nextYear
        }
        // Fallback: 28.02.
        birthdayComponents.day = 28
        return calendar.date(from: birthdayComponents)
    }

    /// Days until next birthday
    static func daysUntilBirthday(from birthday: Date, asOf date: Date = today) -> Int? {
        guard let next = nextBirthday(from: birthday, after: date) else {
            return nil
        }
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: next)).day
    }

    /// Check if birthday is today
    static func isBirthdayToday(from birthday: Date, asOf date: Date = today) -> Bool {
        daysUntilBirthday(from: birthday, asOf: date) == 0
    }

    /// Check if birthday is tomorrow
    static func isBirthdayTomorrow(from birthday: Date, asOf date: Date = today) -> Bool {
        daysUntilBirthday(from: birthday, asOf: date) == 1
    }

    /// Check if birthday is within the next N days
    static func isBirthdayWithinDays(_ days: Int, from birthday: Date, asOf date: Date = today) -> Bool {
        guard let daysUntil = daysUntilBirthday(from: birthday, asOf: date) else {
            return false
        }
        return daysUntil >= 0 && daysUntil <= days
    }

    /// Get zodiac sign for a birthday
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

    // MARK: - Birthday Milestones

    /// Check if age is a milestone (18, 21, 30, 40, 50, 60, 70, 80, 90, 100)
    static func isMilestoneAge(age: Int) -> Bool {
        [18, 21, 30, 40, 50, 60, 70, 80, 90, 100].contains(age)
    }

    /// Get milestone name for age
    static func milestoneName(for age: Int) -> String? {
        switch age {
        case 18: return "🎉 Volljährigkeit"
        case 21: return "🎉 Große Mehrheit"
        case 30: return "🎉 30. Geburtstag"
        case 40: return "🎉 40. Geburtstag"
        case 50: return "🎉 50. Geburtstag"
        case 60: return "🎉 60. Geburtstag"
        case 70: return "🎉 70. Geburtstag"
        case 80: return "🎉 80. Geburtstag"
        case 90: return "🎉 90. Geburtstag"
        case 100: return "🎉 100. Geburtstag"
        default: return nil
        }
    }

    // MARK: - Formatting

    /// Format birthday for display (day and month only)
    static func formatBirthdayShort(_ birthday: Date, locale: Locale = Locale(identifier: "de_DE")) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.setLocalizedDateFormatFromTemplate("dd.MMM")
        formatter.locale = locale
        return formatter.string(from: birthday)
    }

    /// Format full birthday (with year)
    static func formatBirthdayFull(_ birthday: Date, locale: Locale = Locale(identifier: "de_DE")) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = locale
        return formatter.string(from: birthday)
    }

    /// Format relative date description
    static func relativeDateDescription(from birthday: Date, asOf date: Date = today) -> String {
        guard let daysUntil = daysUntilBirthday(from: birthday, asOf: date) else {
            return "Unbekannt"
        }

        switch daysUntil {
        case 0:
            return "🎉 Heute!"
        case 1:
            return "📅 Morgen"
        case 2...7:
            return "📅 In \(daysUntil) Tagen"
        case 8...30:
            return "📅 \(daysUntil) Tage"
        case 31...60:
            return "📅 In \(daysUntil / 30) Monaten"
        case 61...365:
            return "📅 In \(daysUntil / 30) Monaten"
        case 366...:
            return "📅 Nächstes Jahr"
        default:
            return "Unbekannt"
        }
    }

    /// Format age with optional milestone
    static func formatAge(birthday: Date, asOf date: Date = today) -> String {
        let currentAge = age(from: birthday, asOf: date)

        if let milestone = milestoneName(for: currentAge) {
            return "\(currentAge) \(milestone)"
        }

        return "\(currentAge) Jahre"
    }

    // MARK: - Grouping

    /// Group birthdays by time period (Today, Tomorrow, This Week, This Month, Later)
    enum BirthdayPeriod: String, CaseIterable {
        case today = "Heute"
        case tomorrow = "Morgen"
        case thisWeek = "Diese Woche"
        case thisMonth = "Diesen Monat"
        case later = "Später"
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
        cal.locale = Locale(identifier: "de_DE")
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
