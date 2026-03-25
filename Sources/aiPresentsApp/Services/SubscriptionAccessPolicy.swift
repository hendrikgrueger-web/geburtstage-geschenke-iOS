import Foundation

enum SubscriptionAccessPolicy {
    static let trialStartKey = "subscriptionTrialStartDate"
    static let trialDurationDays = 14
    static let isFreeLaunchEnabled = true

    static func trialStartDate(userDefaults: UserDefaults = .standard) -> Date? {
        userDefaults.object(forKey: trialStartKey) as? Date
    }

    static func trialEndDate(
        trialStartDate: Date?,
        calendar: Calendar = .current
    ) -> Date? {
        guard let trialStartDate else { return nil }
        return calendar.date(byAdding: .day, value: trialDurationDays, to: trialStartDate)
    }

    static func isInTrial(
        purchasedProductIDs: Set<String>,
        trialStartDate: Date?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard purchasedProductIDs.isEmpty else { return false }
        guard let trialEndDate = trialEndDate(trialStartDate: trialStartDate, calendar: calendar) else {
            return false
        }
        return now < trialEndDate
    }

    static func hasFullAccess(
        purchasedProductIDs: Set<String>,
        trialStartDate: Date?,
        now: Date = Date(),
        calendar: Calendar = .current,
        freeLaunchEnabled: Bool = isFreeLaunchEnabled
    ) -> Bool {
        if freeLaunchEnabled {
            return true
        }

        return !purchasedProductIDs.isEmpty || isInTrial(
            purchasedProductIDs: purchasedProductIDs,
            trialStartDate: trialStartDate,
            now: now,
            calendar: calendar
        )
    }
}
