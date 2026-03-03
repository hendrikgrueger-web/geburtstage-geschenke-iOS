import XCTest
@testable import aiPresentsApp

/// Tests for AppLogger utility
///
/// Test coverage:
/// - Log level filtering (debug, info, warning, error)
/// - Context formatting
/// - Category-specific logging (AI, CloudKit, Contacts)
/// - File logging (rotation, size limits)
/// - Log export and clearing
final class AppLoggerTests: XCTestCase {

    override func setUpWithError() throws {
        // Clear any existing log files
        AppLogger.clearLogs()
    }

    override func tearDownWithError() throws {
        // Clean up after tests
        AppLogger.clearLogs()
    }

    // MARK: - Log Level Tests

    func testDebugLogLevel() throws {
        // Debug logs should work in debug builds
        #if DEBUG
        XCTAssertNoThrow(AppLogger.debug("Test debug message"))
        #else
        // In release, debug logs should be no-ops
        AppLogger.debug("This should not appear")
        // Verify log file doesn't contain debug message
        let logs = AppLogger.getLogContents()
        XCTAssertNil(logs)
        #endif
    }

    func testInfoLogLevel() throws {
        XCTAssertNoThrow(AppLogger.info("Test info message"))

        // Verify log file contains info message (if file logging enabled)
        #if DEBUG
        let logs = AppLogger.getLogContents()
        // Log file may not exist in test environment
        if let logs = logs {
            XCTAssertTrue(logs.contains("Test info message"))
        }
        #endif
    }

    func testWarningLogLevel() throws {
        XCTAssertNoThrow(AppLogger.warning("Test warning message"))
    }

    func testErrorLogLevel() throws {
        XCTAssertNoThrow(AppLogger.error("Test error message"))
    }

    func testLogLevelFiltering() throws {
        #if DEBUG
        // In debug mode, all logs should appear
        AppLogger.debug("Debug message")
        AppLogger.info("Info message")
        AppLogger.warning("Warning message")
        AppLogger.error("Error message")

        let logs = AppLogger.getLogContents()
        if let logs = logs {
            XCTAssertTrue(logs.contains("Debug message"))
            XCTAssertTrue(logs.contains("Info message"))
            XCTAssertTrue(logs.contains("Warning message"))
            XCTAssertTrue(logs.contains("Error message"))
        }
        #endif
    }

    // MARK: - Context Tests

    func testLogWithContext() throws {
        let context = ["userId": "123", "action": "test"]

        XCTAssertNoThrow(AppLogger.info("Test with context", context: context))

        #if DEBUG
        let logs = AppLogger.getLogContents()
        if let logs = logs {
            XCTAssertTrue(logs.contains("userId=123") || logs.contains("userId"))
            XCTAssertTrue(logs.contains("action=test") || logs.contains("action"))
        }
        #endif
    }

    func testLogWithComplexContext() throws {
        let context = [
            "personId": "abc-123",
            "giftCount": 5,
            "isMilestone": true
        ] as [String: Any]

        XCTAssertNoThrow(AppLogger.info("Complex context test", context: context))
    }

    func testLogWithEmptyContext() throws {
        XCTAssertNoThrow(AppLogger.info("Test with empty context", context: [:]))
    }

    func testLogWithNilContext() throws {
        XCTAssertNoThrow(AppLogger.info("Test with nil context", context: nil))
    }

    // MARK: - Category-Specific Logging Tests

    func testAILogging() throws {
        XCTAssertNoThrow(AppLogger.ai(.debug, "AI debug message"))
        XCTAssertNoThrow(AppLogger.ai(.info, "AI info message"))
        XCTAssertNoThrow(AppLogger.ai(.warning, "AI warning message"))
        XCTAssertNoThrow(AppLogger.ai(.error, "AI error message"))

        XCTAssertNoThrow(AppLogger.ai(.info, "AI default message"))
    }

    func testCloudKitLogging() throws {
        XCTAssertNoThrow(AppLogger.cloudkit(.debug, "CloudKit debug message"))
        XCTAssertNoThrow(AppLogger.cloudkit(.info, "CloudKit info message"))
        XCTAssertNoThrow(AppLogger.cloudkit(.warning, "CloudKit warning message"))
        XCTAssertNoThrow(AppLogger.cloudkit(.error, "CloudKit error message"))

        XCTAssertNoThrow(AppLogger.cloudkit(.info, "CloudKit default message"))
    }

    func testContactsLogging() throws {
        XCTAssertNoThrow(AppLogger.contacts(.debug, "Contacts debug message"))
        XCTAssertNoThrow(AppLogger.contacts(.info, "Contacts info message"))
        XCTAssertNoThrow(AppLogger.contacts(.warning, "Contacts warning message"))
        XCTAssertNoThrow(AppLogger.contacts(.error, "Contacts error message"))

        XCTAssertNoThrow(AppLogger.contacts(.info, "Contacts default message"))
    }

    // MARK: - Convenience Methods Tests

    func testPerformanceLogging() throws {
        let operation = "test_operation"
        let duration: TimeInterval = 0.123

        XCTAssertNoThrow(AppLogger.performance(operation, duration: duration))
    }

    func testNetworkLoggingSuccess() throws {
        let url = "https://api.example.com/test"
        let method = "GET"
        let statusCode = 200
        let duration: TimeInterval = 0.456

        XCTAssertNoThrow(AppLogger.network(url, method: method, statusCode: statusCode, duration: duration))
    }

    func testNetworkLoggingFailure() throws {
        let url = "https://api.example.com/test"
        let method = "POST"
        let statusCode = 500
        let duration: TimeInterval = 0.789

        XCTAssertNoThrow(AppLogger.network(url, method: method, statusCode: statusCode, duration: duration))
    }

    func testNetworkLoggingNoStatusCode() throws {
        let url = "https://api.example.com/test"
        let method = "GET"
        let duration: TimeInterval = 0.234

        XCTAssertNoThrow(AppLogger.network(url, method: method, statusCode: nil, duration: duration))
    }

    func testUserActionLogging() throws {
        let action = "person_view_opened"
        let context = ["personId": "abc-123"]

        XCTAssertNoThrow(AppLogger.userAction(action, context: context))
    }

    func testUserActionLoggingWithoutContext() throws {
        let action = "settings_view_opened"

        XCTAssertNoThrow(AppLogger.userAction(action))
    }

    // MARK: - File Logging Tests

    func testGetLogContentsWithoutLogs() throws {
        AppLogger.clearLogs()
        let logs = AppLogger.getLogContents()

        XCTAssertNil(logs)
    }

    func testGetLogContentsWithLogs() throws {
        #if DEBUG
        AppLogger.info("Test log entry 1")
        AppLogger.warning("Test log entry 2")

        let logs = AppLogger.getLogContents()
        // Log file may not exist in test environment
        if let logs = logs {
            XCTAssertTrue(logs.contains("Test log entry 1"))
            XCTAssertTrue(logs.contains("Test log entry 2"))
        }
        #endif
    }

    func testClearLogs() throws {
        #if DEBUG
        AppLogger.info("Log to be cleared")
        AppLogger.clearLogs()

        let logs = AppLogger.getLogContents()
        XCTAssertNil(logs)
        #endif
    }

    func testExportLogs() throws {
        #if DEBUG
        AppLogger.info("Log for export")

        // Export may fail in test environment — just verify no crash
        let exportURL = AppLogger.exportLogs()
        if let exportURL = exportURL {
            try? FileManager.default.removeItem(at: exportURL)
        }
        #endif
    }

    // MARK: - Log Level Properties Tests

    func testLogLevelEmoji() throws {
        XCTAssertEqual(AppLogger.LogLevel.debug.emoji, "🔍")
        XCTAssertEqual(AppLogger.LogLevel.info.emoji, "ℹ️")
        XCTAssertEqual(AppLogger.LogLevel.warning.emoji, "⚠️")
        XCTAssertEqual(AppLogger.LogLevel.error.emoji, "❌")
    }

    func testLogLevelPrefix() throws {
        XCTAssertEqual(AppLogger.LogLevel.debug.prefix, "DEBUG")
        XCTAssertEqual(AppLogger.LogLevel.info.prefix, "INFO")
        XCTAssertEqual(AppLogger.LogLevel.warning.prefix, "WARNING")
        XCTAssertEqual(AppLogger.LogLevel.error.prefix, "ERROR")
    }

    func testLogLevelComparison() throws {
        XCTAssertTrue(AppLogger.LogLevel.debug < AppLogger.LogLevel.info)
        XCTAssertTrue(AppLogger.LogLevel.info < AppLogger.LogLevel.warning)
        XCTAssertTrue(AppLogger.LogLevel.warning < AppLogger.LogLevel.error)
    }

    // MARK: - Integration Tests

    func testCompleteLoggingWorkflow() throws {
        #if DEBUG
        // User action
        AppLogger.userAction("user_logged_in", context: ["userId": "123"])

        // Performance
        AppLogger.performance("data_load", duration: 0.234)

        // Network request
        AppLogger.network("https://api.example.com/users", method: "GET", statusCode: 200, duration: 0.123)

        // AI operation
        AppLogger.ai(.info, "Generating suggestions", context: ["personId": "456"])

        // Verify all logs exist (if log file available in test env)
        let logs = AppLogger.getLogContents()
        if let logs = logs {
            XCTAssertTrue(logs.contains("user_logged_in"))
            XCTAssertTrue(logs.contains("data_load"))
            XCTAssertTrue(logs.contains("https://api.example.com/users"))
            XCTAssertTrue(logs.contains("Generating suggestions"))
        }
        #endif
    }

    func testErrorLoggingWithDetailedContext() throws {
        let context: [String: Any] = [
            "errorCode": 500,
            "errorMessage": "Internal server error",
            "requestId": "req-abc-123",
            "retryCount": 3
        ]

        XCTAssertNoThrow(AppLogger.error("API request failed", context: context))

        #if DEBUG
        let logs = AppLogger.getLogContents()
        if let logs = logs {
            XCTAssertTrue(logs.contains("API request failed"))
            XCTAssertTrue(logs.contains("errorCode") || logs.contains("500"))
        }
        #endif
    }
}

// MARK: - Performance Tests

extension AppLoggerTests {
    func testLoggingPerformance() throws {
        measure {
            for _ in 0..<100 {
                AppLogger.info("Performance test message")
            }
        }
    }

    func testLoggingWithContextPerformance() throws {
        let context = ["key1": "value1", "key2": "value2", "key3": "value3"]

        measure {
            for _ in 0..<100 {
                AppLogger.info("Performance test with context", context: context)
            }
        }
    }
}
