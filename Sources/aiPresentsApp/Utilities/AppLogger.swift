import Foundation
import OSLog

/// App-wide logging utility using Apple's unified logging system
enum AppLogger {
    /// Shared logger instance
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.harryhirsch.ai-presents", category: "App")

    // MARK: - Logging Levels

    /// Logs debug information
    static func debug(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
        #if DEBUG
        logger.debug("\(message) [\(sourceFileName(file)):\(line) \(function)]")
        #endif
    }

    /// Logs informational messages
    static func info(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
        logger.info("\(message)")
    }

    /// Logs errors
    static func error(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
        logger.error("\(message) [\(sourceFileName(file)):\(line) \(function)]")
    }

    /// Logs errors with underlying error
    static func error(_ message: String, error: Error, function: String = #function, file: String = #file, line: Int = #line) {
        logger.error("\(message): \(error.localizedDescription) [\(sourceFileName(file)):\(line) \(function)]")
    }

    /// Logs warnings
    static func warning(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
        logger.warning("\(message) [\(sourceFileName(file)):\(line) \(function)]")
    }

    // MARK: - Helper Methods

    /// Extracts the filename from the full file path
    private static func sourceFileName(_ filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.last ?? filePath
    }
}

// MARK: - Category-specific Loggers

extension AppLogger {
    /// Logger for data operations
    static let data = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.harryhirsch.ai-presents", category: "Data")

    /// Logger for reminder operations
    static let reminder = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.harryhirsch.ai-presents", category: "Reminder")

    /// Logger for sync operations
    static let sync = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.harryhirsch.ai-presents", category: "Sync")

    /// Logger for UI operations
    static let ui = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.harryhirsch.ai-presents", category: "UI")

    /// Logger for network operations
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.harryhirsch.ai-presents", category: "Network")
}
