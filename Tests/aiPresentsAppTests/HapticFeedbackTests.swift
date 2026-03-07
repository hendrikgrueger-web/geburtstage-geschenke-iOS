import XCTest
@testable import aiPresentsApp

@MainActor
final class HapticFeedbackTests: XCTestCase {

    // MARK: - Impact Feedback Tests

    func testLightImpactFeedbackDoesNotCrash() {
        // This test verifies that calling light impact doesn't crash
        // Note: We can't verify actual haptic feedback in unit tests
        XCTAssertNoThrow(
            HapticFeedback.light(),
            "Light impact feedback should not throw"
        )
    }

    func testMediumImpactFeedbackDoesNotCrash() {
        XCTAssertNoThrow(
            HapticFeedback.medium(),
            "Medium impact feedback should not throw"
        )
    }

    func testHeavyImpactFeedbackDoesNotCrash() {
        XCTAssertNoThrow(
            HapticFeedback.heavy(),
            "Heavy impact feedback should not throw"
        )
    }

    // MARK: - Notification Feedback Tests

    func testSuccessNotificationFeedbackDoesNotCrash() {
        XCTAssertNoThrow(
            HapticFeedback.success(),
            "Success notification feedback should not throw"
        )
    }

    func testWarningNotificationFeedbackDoesNotCrash() {
        XCTAssertNoThrow(
            HapticFeedback.warning(),
            "Warning notification feedback should not throw"
        )
    }

    func testErrorNotificationFeedbackDoesNotCrash() {
        XCTAssertNoThrow(
            HapticFeedback.error(),
            "Error notification feedback should not throw"
        )
    }

    // MARK: - Selection Feedback Tests

    func testSelectionChangedFeedbackDoesNotCrash() {
        XCTAssertNoThrow(
            HapticFeedback.selectionChanged(),
            "Selection changed feedback should not throw"
        )
    }

    // MARK: - Multiple Feedback Calls Tests

    func testMultipleFeedbackCallsDoNotCrash() {
        XCTAssertNoThrow({
            HapticFeedback.light()
            HapticFeedback.medium()
            HapticFeedback.heavy()
            HapticFeedback.success()
            HapticFeedback.warning()
            HapticFeedback.error()
            HapticFeedback.selectionChanged()
        }(), "Multiple feedback calls should not throw")
    }

    func testRapidFeedbackCallsDoNotCrash() {
        XCTAssertNoThrow({
            for _ in 0..<10 {
                HapticFeedback.selectionChanged()
            }
        }(), "Rapid feedback calls should not throw")
    }

    // MARK: - Feedback Sequence Tests

    func testFeedbackSequenceDoesNotCrash() {
        // Test a typical user interaction sequence
        XCTAssertNoThrow({
            HapticFeedback.light() // User taps a button
            HapticFeedback.selectionChanged() // User changes selection
            HapticFeedback.success() // Operation completes successfully
        }(), "Feedback sequence should not throw")
    }

    func testErrorFeedbackSequenceDoesNotCrash() {
        // Test an error scenario
        XCTAssertNoThrow({
            HapticFeedback.light() // User taps a button
            HapticFeedback.error() // Operation fails
            HapticFeedback.warning() // Warning shown
        }(), "Error feedback sequence should not throw")
    }
}
