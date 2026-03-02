import XCTest
@testable import aiPresentsApp

final class AppColorTests: XCTestCase {

    // MARK: - Primary Colors Tests

    func testPrimaryColorExists() {
        XCTAssertNotNil(AppColor.primary)
    }

    func testPrimaryLightColorExists() {
        XCTAssertNotNil(AppColor.primaryLight)
    }

    func testPrimaryDarkColorExists() {
        XCTAssertNotNil(AppColor.primaryDark)
    }

    // MARK: - Secondary Colors Tests

    func testSecondaryColorExists() {
        XCTAssertNotNil(AppColor.secondary)
    }

    func testSecondaryLightColorExists() {
        XCTAssertNotNil(AppColor.secondaryLight)
    }

    // MARK: - Accent Colors Tests

    func testAccentColorExists() {
        XCTAssertNotNil(AppColor.accent)
    }

    func testAccentLightColorExists() {
        XCTAssertNotNil(AppColor.accentLight)
    }

    // MARK: - Status Colors Tests

    func testSuccessColorExists() {
        XCTAssertNotNil(AppColor.success)
    }

    func testWarningColorExists() {
        XCTAssertNotNil(AppColor.warning)
    }

    func testErrorColorExists() {
        XCTAssertNotNil(AppColor.error)
    }

    // MARK: - Birthday Colors Tests

    func testBirthdayTodayColorExists() {
        XCTAssertNotNil(AppColor.birthdayToday)
    }

    func testBirthdaySoonColorExists() {
        XCTAssertNotNil(AppColor.birthdaySoon)
    }

    func testBirthdayUpcomingColorExists() {
        XCTAssertNotNil(AppColor.birthdayUpcoming)
    }

    // MARK: - Background Colors Tests

    func testBackgroundColorExists() {
        XCTAssertNotNil(AppColor.background)
    }

    func testCardBackgroundColorExists() {
        XCTAssertNotNil(AppColor.cardBackground)
    }

    func testSeparatorColorExists() {
        XCTAssertNotNil(AppColor.separator)
    }

    // MARK: - Text Colors Tests

    func testTextPrimaryColorExists() {
        XCTAssertNotNil(AppColor.textPrimary)
    }

    func testTextSecondaryColorExists() {
        XCTAssertNotNil(AppColor.textSecondary)
    }

    func testTextTertiaryColorExists() {
        XCTAssertNotNil(AppColor.textTertiary)
    }

    // MARK: - Gradient Tests

    func testGradientBlueExists() {
        XCTAssertNotNil(AppColor.gradientBlue)
    }

    func testGradientWarmExists() {
        XCTAssertNotNil(AppColor.gradientWarm)
    }

    func testGradientPurpleExists() {
        XCTAssertNotNil(AppColor.gradientPurple)
    }

    func testGradientSuccessExists() {
        XCTAssertNotNil(AppColor.gradientSuccess)
    }

    func testGradientErrorExists() {
        XCTAssertNotNil(AppColor.gradientError)
    }

    // MARK: - Gradient For Relation Tests

    func testGradientForFamilyRelation() {
        let gradient = AppColor.gradientForRelation("familie")

        XCTAssertNotNil(gradient)
    }

    func testGradientForMama() {
        let gradient = AppColor.gradientForRelation("mama")

        XCTAssertNotNil(gradient)
    }

    func testGradientForPapa() {
        let gradient = AppColor.gradientForRelation("papa")

        XCTAssertNotNil(gradient)
    }

    func testGradientForFriend() {
        let gradient = AppColor.gradientForRelation("freund")

        XCTAssertNotNil(gradient)
    }

    func testGradientForColleague() {
        let gradient = AppColor.gradientForRelation("kollege")

        XCTAssertNotNil(gradient)
    }

    func testGradientForPartner() {
        let gradient = AppColor.gradientForRelation("partner")

        XCTAssertNotNil(gradient)
    }

    func testGradientForSpouse() {
        let gradient = AppColor.gradientForRelation("ehepartner")

        XCTAssertNotNil(gradient)
    }

    func testGradientForDefaultRelation() {
        let gradient = AppColor.gradientForRelation("andere")

        XCTAssertNotNil(gradient)
    }

    func testGradientForCaseInsensitive() {
        let gradient1 = AppColor.gradientForRelation("FAMILIE")
        let gradient2 = AppColor.gradientForRelation("familie")

        XCTAssertNotNil(gradient1)
        XCTAssertNotNil(gradient2)
    }

    // MARK: - Gift Status Extension Tests

    func testGiftStatusIdeaColor() {
        let color = GiftStatus.idea.color

        XCTAssertNotNil(color)
    }

    func testGiftStatusIdeaIcon() {
        let icon = GiftStatus.idea.icon

        XCTAssertEqual(icon, "lightbulb")
    }

    func testGiftStatusPlannedColor() {
        let color = GiftStatus.planned.color

        XCTAssertNotNil(color)
    }

    func testGiftStatusPlannedIcon() {
        let icon = GiftStatus.planned.icon

        XCTAssertEqual(icon, "calendar")
    }

    func testGiftStatusPurchasedColor() {
        let color = GiftStatus.purchased.color

        XCTAssertNotNil(color)
    }

    func testGiftStatusPurchasedIcon() {
        let icon = GiftStatus.purchased.icon

        XCTAssertEqual(icon, "bag")
    }

    func testGiftStatusGivenColor() {
        let color = GiftStatus.given.color

        XCTAssertNotNil(color)
    }

    func testGiftStatusGivenIcon() {
        let icon = GiftStatus.given.icon

        XCTAssertEqual(icon, "checkmark.circle.fill")
    }

    // MARK: - Edge Cases

    func testGradientForEmptyString() {
        let gradient = AppColor.gradientForRelation("")

        XCTAssertNotNil(gradient)
    }

    func testGradientForSpecialCharacters() {
        let gradient = AppColor.gradientForRelation("über-schrifft")

        XCTAssertNotNil(gradient)
    }

    func testGradientForVeryLongRelationName() {
        let longRelation = String(repeating: "a", count: 1000)
        let gradient = AppColor.gradientForRelation(longRelation)

        XCTAssertNotNil(gradient)
    }

    // MARK: - Consistency Tests

    func testAllStatusesHaveColors() {
        let statuses: [GiftStatus] = [.idea, .planned, .purchased, .given]

        for status in statuses {
            XCTAssertNotNil(status.color, "Status \(status) should have a color")
            XCTAssertNotNil(status.icon, "Status \(status) should have an icon")
        }
    }

    func testAllStatusesHaveUniqueIcons() {
        let statuses: [GiftStatus] = [.idea, .planned, .purchased, .given]
        let icons = Set(statuses.map { $0.icon })

        XCTAssertEqual(icons.count, statuses.count, "All statuses should have unique icons")
    }

    func testAllColorsAreDefined() {
        let colors = [
            AppColor.primary,
            AppColor.primaryLight,
            AppColor.primaryDark,
            AppColor.secondary,
            AppColor.secondaryLight,
            AppColor.accent,
            AppColor.accentLight,
            AppColor.success,
            AppColor.warning,
            AppColor.error,
            AppColor.birthdayToday,
            AppColor.birthdaySoon,
            AppColor.birthdayUpcoming,
            AppColor.background,
            AppColor.cardBackground,
            AppColor.separator,
            AppColor.textPrimary,
            AppColor.textSecondary,
            AppColor.textTertiary
        ]

        for color in colors {
            XCTAssertNotNil(color, "All colors should be defined")
        }
    }

    func testAllGradientsAreDefined() {
        let gradients = [
            AppColor.gradientBlue,
            AppColor.gradientWarm,
            AppColor.gradientPurple,
            AppColor.gradientSuccess,
            AppColor.gradientError
        ]

        for gradient in gradients {
            XCTAssertNotNil(gradient, "All gradients should be defined")
        }
    }
}
