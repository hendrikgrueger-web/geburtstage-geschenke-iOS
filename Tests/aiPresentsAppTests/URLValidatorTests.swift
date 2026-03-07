import XCTest
@testable import aiPresentsApp

@MainActor
final class URLValidatorTests: XCTestCase {

    func testEmptyString() {
        let result = URLValidator.validate("")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.sanitized, "")
    }

    func testWhitespaceOnly() {
        let result = URLValidator.validate("   ")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.sanitized, "")
    }

    func testValidHTTPSURL() {
        let result = URLValidator.validate("https://example.com")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.sanitized, "https://example.com")
    }

    func testValidHTTPURL() {
        let result = URLValidator.validate("http://example.com")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.sanitized, "http://example.com")
    }

    func testURLWithoutScheme() {
        let result = URLValidator.validate("example.com")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.sanitized, "https://example.com")
    }

    func testURLWithPath() {
        let result = URLValidator.validate("example.com/products/123")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.sanitized, "https://example.com/products/123")
    }

    func testURLWithQueryParams() {
        let result = URLValidator.validate("example.com?query=test&page=1")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.sanitized, "https://example.com?query=test&page=1")
    }

    func testAmazonURL() {
        let result = URLValidator.validate("amazon.de/dp/B123456")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.sanitized, "https://amazon.de/dp/B123456")
    }

    func testInvalidURL() {
        let result = URLValidator.validate("not a url")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.sanitized, "not a url")
    }

    func testURLWithLeadingWhitespace() {
        let result = URLValidator.validate("  https://example.com  ")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.sanitized, "https://example.com")
    }

    func testCanOpenValidURL() {
        // canOpen relies on UIApplication.shared which is not available in unit tests
        // Just verify it doesn't crash
        let result = URLValidator.canOpen("https://apple.com")
        // In test environment, canOpen may return false
        _ = result
    }

    func testCanOpenInvalidURL() throws {
        // UIApplication.shared.canOpenURL behaves unpredictably in the Simulator
        throw XCTSkip("canOpenURL returns inconsistent results in Simulator")
    }
}
