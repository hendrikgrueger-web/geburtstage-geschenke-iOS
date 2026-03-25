import XCTest
@testable import aiPresentsApp

final class SubscriptionAccessPolicyTests: XCTestCase {
    func testHasFullAccessIsTrueDuringFreeLaunchWithoutPurchaseOrTrial() {
        XCTAssertTrue(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: [],
                trialStartDate: nil
            )
        )
    }

    func testHasFullAccessRequiresPurchaseOrTrialWhenFreeLaunchDisabled() {
        XCTAssertFalse(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: [],
                trialStartDate: nil,
                freeLaunchEnabled: false
            )
        )

        XCTAssertTrue(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: ["com.hendrikgrueger.birthdays-presents-ai.monthly"],
                trialStartDate: nil,
                freeLaunchEnabled: false
            )
        )
    }

    func testIsInTrialIsFalseWhenSubscribed() {
        let trialStartDate = Date()

        XCTAssertFalse(
            SubscriptionAccessPolicy.isInTrial(
                purchasedProductIDs: ["com.hendrikgrueger.birthdays-presents-ai.yearly"],
                trialStartDate: trialStartDate
            )
        )
    }

    func testTrialEndDateUsesFourteenDays() {
        let calendar = Calendar(identifier: .gregorian)
        let trialStartDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 24))!

        let trialEndDate = SubscriptionAccessPolicy.trialEndDate(
            trialStartDate: trialStartDate,
            calendar: calendar
        )

        XCTAssertEqual(trialEndDate, calendar.date(byAdding: .day, value: 14, to: trialStartDate))
    }
}
