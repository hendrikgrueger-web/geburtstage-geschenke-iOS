import XCTest
@testable import aiPresentsApp

final class ToastViewTests: XCTestCase {

    // MARK: - ToastType Tests

    func testToastTypeSuccessIcon() {
        XCTAssertEqual(ToastType.success.icon, "checkmark.circle.fill")
    }

    func testToastTypeErrorIcon() {
        XCTAssertEqual(ToastType.error.icon, "xmark.circle.fill")
    }

    func testToastTypeWarningIcon() {
        XCTAssertEqual(ToastType.warning.icon, "exclamationmark.triangle.fill")
    }

    func testToastTypeInfoIcon() {
        XCTAssertEqual(ToastType.info.icon, "info.circle.fill")
    }

    func testToastTypeSuccessColor() {
        XCTAssertNotNil(ToastType.success.color)
    }

    func testToastTypeErrorColor() {
        XCTAssertNotNil(ToastType.error.color)
    }

    func testToastTypeWarningColor() {
        XCTAssertNotNil(ToastType.warning.color)
    }

    func testToastTypeInfoColor() {
        XCTAssertNotNil(ToastType.info.color)
    }

    // MARK: - ToastItem Tests

    func testToastItemInitialization() {
        let item = ToastItem(
            type: .success,
            title: "Test Title",
            message: "Test Message",
            duration: 5.0
        )

        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.type, .success)
        XCTAssertEqual(item.title, "Test Title")
        XCTAssertEqual(item.message, "Test Message")
        XCTAssertEqual(item.duration, 5.0)
    }

    func testToastItemUniqueIDs() {
        let item1 = ToastItem(type: .success, title: "Test")
        let item2 = ToastItem(type: .success, title: "Test")

        XCTAssertNotEqual(item1.id, item2.id, "Each ToastItem should have a unique ID")
    }

    func testToastItemWithNilMessage() {
        let item = ToastItem(
            type: .success,
            title: "Test Title",
            message: nil
        )

        XCTAssertNil(item.message)
    }

    // MARK: - ToastItem Convenience Initializers

    func testToastItemSuccess() {
        let item = ToastItem.success("Success Title", message: "Success Message")

        XCTAssertEqual(item.type, .success)
        XCTAssertEqual(item.title, "Success Title")
        XCTAssertEqual(item.message, "Success Message")
    }

    func testToastItemError() {
        let item = ToastItem.error("Error Title", message: "Error Message")

        XCTAssertEqual(item.type, .error)
        XCTAssertEqual(item.title, "Error Title")
        XCTAssertEqual(item.message, "Error Message")
    }

    func testToastItemWarning() {
        let item = ToastItem.warning("Warning Title", message: "Warning Message")

        XCTAssertEqual(item.type, .warning)
        XCTAssertEqual(item.title, "Warning Title")
        XCTAssertEqual(item.message, "Warning Message")
    }

    func testToastItemInfo() {
        let item = ToastItem.info("Info Title", message: "Info Message")

        XCTAssertEqual(item.type, .info)
        XCTAssertEqual(item.title, "Info Title")
        XCTAssertEqual(item.message, "Info Message")
    }

    func testToastItemConvenienceWithoutMessage() {
        let item = ToastItem.success("Title")

        XCTAssertEqual(item.title, "Title")
        XCTAssertNil(item.message)
    }

    // MARK: - Default Duration Tests

    func testDefaultDurationIsThreeSeconds() {
        let item = ToastItem.success("Test")

        XCTAssertEqual(item.duration, 3.0)
    }

    func testConvenienceInitializersUseDefaultDuration() {
        let items = [
            ToastItem.success("Test"),
            ToastItem.error("Test"),
            ToastItem.warning("Test"),
            ToastItem.info("Test")
        ]

        for item in items {
            XCTAssertEqual(item.duration, 3.0)
        }
    }

    // MARK: - Edge Cases

    func testEmptyTitle() {
        let item = ToastItem.success("", message: "Message")

        XCTAssertEqual(item.title, "")
        XCTAssertEqual(item.message, "Message")
    }

    func testVeryLongTitle() {
        let longTitle = String(repeating: "A", count: 1000)
        let item = ToastItem.success(longTitle)

        XCTAssertEqual(item.title, longTitle)
    }

    func testVeryLongMessage() {
        let longMessage = String(repeating: "A", count: 1000)
        let item = ToastItem.success("Title", message: longMessage)

        XCTAssertEqual(item.message, longMessage)
    }

    func testVeryShortDuration() {
        let item = ToastItem(type: .success, title: "Test", duration: 0.1)

        XCTAssertEqual(item.duration, 0.1)
    }

    func testVeryLongDuration() {
        let item = ToastItem(type: .success, title: "Test", duration: 1000)

        XCTAssertEqual(item.duration, 1000)
    }

    func testZeroDuration() {
        let item = ToastItem(type: .success, title: "Test", duration: 0)

        XCTAssertEqual(item.duration, 0)
    }

    // MARK: - Consistency Tests

    func testAllToastTypesHaveIcons() {
        let types: [ToastType] = [.success, .error, .warning, .info]

        for type in types {
            XCTAssertNotNil(type.icon, "Toast type \(type) should have an icon")
        }
    }

    func testAllToastTypesHaveColors() {
        let types: [ToastType] = [.success, .error, .warning, .info]

        for type in types {
            XCTAssertNotNil(type.color, "Toast type \(type) should have a color")
        }
    }

    func testAllConvenienceInitializersExist() {
        XCTAssertNoThrow(ToastItem.success(""))
        XCTAssertNoThrow(ToastItem.error(""))
        XCTAssertNoThrow(ToastItem.warning(""))
        XCTAssertNoThrow(ToastItem.info(""))
    }

    // MARK: - ToastType Enum Cases

    func testToastTypeHasExactlyFourCases() {
        let allCases: [ToastType] = [.success, .error, .warning, .info]

        XCTAssertEqual(allCases.count, 4, "ToastType should have exactly 4 cases")
    }

    func testToastTypeIconsAreUnique() {
        let types: [ToastType] = [.success, .error, .warning, .info]
        let icons = Set(types.map { $0.icon })

        XCTAssertEqual(icons.count, types.count, "All toast type icons should be unique")
    }
}
