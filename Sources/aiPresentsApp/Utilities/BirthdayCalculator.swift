import Foundation

/// Utility for calculating birthdays and upcoming dates
struct BirthdayCalculator {
    /// Calculates the next occurrence of a birthday from a reference date
    /// - Parameters:
    ///   - birthday: The person's birthday
    ///   - from: The reference date (defaults to today)
    /// - Returns: The next birthday date, or nil if calculation fails
    static func nextBirthday(for birthday: Date, from referenceDate: Date = Date()) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let currentYear = calendar.component(.year, from: today)

        var components = calendar.dateComponents([.month, .day], from: birthday)
        components.year = currentYear

        guard var nextBirthday = calendar.date(from: components) else {
            return nil
        }

        // If the birthday this year has already passed, use next year
        if nextBirthday < today {
            components.year = currentYear + 1
            nextBirthday = calendar.date(from: components) ?? nextBirthday
        }

        return nextBirthday
    }

    /// Calculates days until the next birthday
    /// - Parameters:
    ///   - birthday: The person's birthday
    ///   - from: The reference date (defaults to today)
    /// - Returns: Days until birthday (0 if today), or nil if calculation fails
    static func daysUntilBirthday(for birthday: Date, from referenceDate: Date = Date()) -> Int? {
        guard let nextBirthday = nextBirthday(for: birthday, from: referenceDate) else {
            return nil
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let daysUntil = calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0

        return max(0, daysUntil)
    }

    /// Determines if a birthday is today
    /// - Parameters:
    ///   - birthday: The person's birthday
    ///   - from: The reference date (defaults to today)
    /// - Returns: True if the birthday is today
    static func isBirthdayToday(for birthday: Date, from referenceDate: Date = Date()) -> Bool {
        return daysUntilBirthday(for: birthday, from: referenceDate) == 0
    }

    /// Determines if a birthday is within a certain number of days
    /// - Parameters:
    ///   - birthday: The person's birthday
    ///   - days: The maximum number of days
    ///   - from: The reference date (defaults to today)
    /// - Returns: True if the birthday is within the specified days
    static func isBirthdayWithinDays(for birthday: Date, days: Int, from referenceDate: Date = Date()) -> Bool {
        guard let daysUntil = daysUntilBirthday(for: birthday, from: referenceDate) else {
            return false
        }
        return daysUntil >= 0 && daysUntil <= days
    }

    /// Calculates age for a given birthday on a specific date
    /// - Parameters:
    ///   - birthday: The person's birthday
    ///   - on: The date to calculate age for (defaults to today)
    /// - Returns: The age, or nil if calculation fails
    static func age(for birthday: Date, on date: Date = Date()) -> Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        var components = calendar.dateComponents([.year, .month, .day], from: birthday)
        let currentComponents = calendar.dateComponents([.year, .month, .day], from: today)

        guard let birthYear = components.year,
              let currentYear = currentComponents.year,
              let birthMonth = components.month,
              let currentMonth = currentComponents.month,
              let birthDay = components.day,
              let currentDay = currentComponents.day else {
            return nil
        }

        var age = currentYear - birthYear

        // Subtract one if birthday hasn't occurred yet this year
        if (currentMonth < birthMonth) || (currentMonth == birthMonth && currentDay < birthDay) {
            age -= 1
        }

        return age
    }
}
