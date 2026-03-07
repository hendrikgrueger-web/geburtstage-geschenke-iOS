import Foundation

/// Utility for calculating birthdays and upcoming dates
struct BirthdayCalculator {
    /// Internal cache for birthday calculations to improve performance
    /// Protected by cacheLock for thread safety
    nonisolated(unsafe) private static var cache: [String: BirthdayCacheEntry] = [:]
    private static let cacheLock = NSLock()

    /// Cache entry for birthday calculations
    private struct BirthdayCacheEntry {
        let nextBirthday: Date?
        let daysUntil: Int?
        let age: Int?
        let timestamp: Date

        /// Check if cache entry is valid (not older than 5 seconds)
        var isValid: Bool {
            Date().timeIntervalSince(timestamp) < 5.0
        }

        /// Merge new values into this entry, preserving existing non-nil fields
        func merging(nextBirthday: Date?? = nil, daysUntil: Int?? = nil, age: Int?? = nil) -> BirthdayCacheEntry {
            BirthdayCacheEntry(
                nextBirthday: nextBirthday ?? self.nextBirthday,
                daysUntil: daysUntil ?? self.daysUntil,
                age: age ?? self.age,
                timestamp: Date()
            )
        }
    }

    /// Clear the birthday calculation cache
    static func clearCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        cache.removeAll()
        AppLogger.debug("BirthdayCalculator cache cleared")
    }

    /// Calculates the next occurrence of a birthday from a reference date (cached)
    /// - Parameters:
    ///   - birthday: The person's birthday
    ///   - from: The reference date (defaults to today)
    /// - Returns: The next birthday date, or nil if calculation fails
    static func nextBirthday(for birthday: Date, from referenceDate: Date = Date()) -> Date? {
        let cacheKey = generateCacheKey(birthday: birthday, from: referenceDate)

        // Check cache (thread-safe)
        cacheLock.lock()
        if let entry = cache[cacheKey], entry.isValid, let cachedNextBirthday = entry.nextBirthday {
            cacheLock.unlock()
            AppLogger.debug("Cache hit for nextBirthday: \(cacheKey)")
            return cachedNextBirthday
        }
        cacheLock.unlock()

        // Calculate new value (outside lock)
        let nextBirthday = calculateNextBirthday(for: birthday, from: referenceDate)

        // Update cache (thread-safe, merge with existing entry)
        cacheLock.lock()
        if let existing = cache[cacheKey], existing.isValid {
            cache[cacheKey] = existing.merging(nextBirthday: .some(nextBirthday))
        } else {
            cache[cacheKey] = BirthdayCacheEntry(
                nextBirthday: nextBirthday, daysUntil: nil, age: nil, timestamp: Date()
            )
        }
        cacheLock.unlock()

        return nextBirthday
    }

    /// Calculates the next occurrence of a birthday from a reference date (uncached)
    private static func calculateNextBirthday(for birthday: Date, from referenceDate: Date) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let currentYear = calendar.component(.year, from: today)

        var components = calendar.dateComponents([.month, .day], from: birthday)
        components.year = currentYear

        guard var nextBirthday = calendar.date(from: components) else {
            // Schaltjahr-Fallback: 29.02. → 28.02. im Nicht-Schaltjahr
            components.day = 28
            guard var fallback = calendar.date(from: components) else { return nil }
            if fallback < today {
                components.year = currentYear + 1
                components.day = 29
                if let leapYear = calendar.date(from: components) {
                    return leapYear
                }
                components.day = 28
                fallback = calendar.date(from: components) ?? fallback
            }
            return fallback
        }

        // If the birthday this year has already passed, use next year
        if nextBirthday < today {
            components.year = currentYear + 1
            nextBirthday = calendar.date(from: components) ?? nextBirthday
        }

        return nextBirthday
    }

    /// Calculates days until the next birthday (cached)
    /// - Parameters:
    ///   - birthday: The person's birthday
    ///   - from: The reference date (defaults to today)
    /// - Returns: Days until birthday (0 if today), or nil if calculation fails
    static func daysUntilBirthday(for birthday: Date, from referenceDate: Date = Date()) -> Int? {
        let cacheKey = generateCacheKey(birthday: birthday, from: referenceDate)

        // Check cache (thread-safe)
        cacheLock.lock()
        if let entry = cache[cacheKey], entry.isValid, let cachedDaysUntil = entry.daysUntil {
            cacheLock.unlock()
            AppLogger.debug("Cache hit for daysUntilBirthday: \(cacheKey)")
            return cachedDaysUntil
        }
        cacheLock.unlock()

        // Calculate new value (outside lock)
        let daysUntil = calculateDaysUntilBirthday(for: birthday, from: referenceDate)

        // Update cache (thread-safe, merge with existing entry)
        cacheLock.lock()
        if let existing = cache[cacheKey], existing.isValid {
            cache[cacheKey] = existing.merging(daysUntil: .some(daysUntil))
        } else {
            cache[cacheKey] = BirthdayCacheEntry(
                nextBirthday: nil, daysUntil: daysUntil, age: nil, timestamp: Date()
            )
        }
        cacheLock.unlock()

        return daysUntil
    }

    /// Calculates days until the next birthday (uncached)
    private static func calculateDaysUntilBirthday(for birthday: Date, from referenceDate: Date) -> Int? {
        guard let nextBirthday = nextBirthday(for: birthday, from: referenceDate) else {
            return nil
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let daysUntil = calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0

        return max(0, daysUntil)
    }

    /// Generates a unique cache key based on birthday and reference date
    private static func generateCacheKey(birthday: Date, from referenceDate: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let birthdayKey = calendar.startOfDay(for: birthday).timeIntervalSince1970

        return "\(birthdayKey)-\(today.timeIntervalSince1970)"
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

    /// Calculates age for a given birthday on a specific date (cached)
    /// - Parameters:
    ///   - birthday: The person's birthday
    ///   - on: The date to calculate age for (defaults to today)
    /// - Returns: The age, or nil if calculation fails
    static func age(for birthday: Date, on date: Date = Date()) -> Int? {
        let cacheKey = "age-\(generateCacheKey(birthday: birthday, from: date))"

        // Check cache (thread-safe)
        cacheLock.lock()
        if let entry = cache[cacheKey], entry.isValid, let cachedAge = entry.age {
            cacheLock.unlock()
            return cachedAge
        }
        cacheLock.unlock()

        // Calculate new value (outside lock)
        let calculatedAge = calculateAge(for: birthday, on: date)

        // Update cache (thread-safe, merge with existing entry)
        cacheLock.lock()
        if let existing = cache[cacheKey], existing.isValid {
            cache[cacheKey] = existing.merging(age: .some(calculatedAge))
        } else {
            cache[cacheKey] = BirthdayCacheEntry(
                nextBirthday: nil, daysUntil: nil, age: calculatedAge, timestamp: Date()
            )
        }
        cacheLock.unlock()

        return calculatedAge
    }

    /// Calculates age for a given birthday on a specific date (uncached)
    private static func calculateAge(for birthday: Date, on date: Date) -> Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.year, .month, .day], from: birthday)
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
