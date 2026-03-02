import Foundation
import OSLog

/// Centralized logging system for aiPresentsApp
///
/// Features:
/// - Multiple log levels (debug, info, warning, error)
/// - Structured logging with context
/// - Release-optimized (minimal logs in production)
/// - Optional file persistence for debugging
///
/// ## Usage Examples
///
/// ```swift
/// // Simple logging
/// AppLogger.info("User opened PersonDetailView")
///
/// // With context
/// AppLogger.error("Failed to load gifts", context: ["personId": person.id.uuidString])
///
/// // Debug only
/// AppLogger.debug("API request payload", context: ["body": requestBody])
/// ```
struct AppLogger {

    // MARK: - Configuration

    #if DEBUG
    /// Current log level (debug mode: show everything)
    private static let currentLogLevel: LogLevel = .debug
    #else
    /// Current log level (release mode: show warnings and errors only)
    private static let currentLogLevel: LogLevel = .warning
    #endif

    /// Enable file logging for debugging (set to false in production)
    private static let enableFileLogging: Bool = false

    /// Maximum log file size in bytes (5MB)
    private static let maxLogFileSize: UInt64 = 5 * 1024 * 1024

    // MARK: - Log Levels

    enum LogLevel: Int, Comparable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3

        static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }

        var prefix: String {
            switch self {
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warning: return "WARNING"
            case .error: return "ERROR"
            }
        }
    }

    // MARK: - Subsystems

    /// Main app subsystem
    private static let subsystem = "com.aipresents.app"

    /// Subsystem for AI operations
    private static let aiSubsystem = "com.aipresents.app.ai"

    /// Subsystem for CloudKit operations
    private static let cloudkitSubsystem = "com.aipresents.app.cloudkit"

    /// Subsystem for Contacts operations
    private static let contactsSubsystem = "com.aipresents.app.contacts"

    // MARK: - Loggers

    private static let mainLogger = Logger(subsystem: subsystem, category: "Main")
    private static let aiLogger = Logger(subsystem: aiSubsystem, category: "AI")
    private static let cloudkitLogger = Logger(subsystem: cloudkitSubsystem, category: "CloudKit")
    private static let contactsLogger = Logger(subsystem: contactsSubsystem, category: "Contacts")

    // MARK: - Logging Methods

    /// Log debug message (only in debug builds)
    static func debug(_ message: String, context: [String: Any]? = nil) {
        guard currentLogLevel <= .debug else { return }
        log(level: .debug, message, context: context)
    }

    /// Log info message
    static func info(_ message: String, context: [String: Any]? = nil) {
        guard currentLogLevel <= .info else { return }
        log(level: .info, message, context: context)
    }

    /// Log warning message
    static func warning(_ message: String, context: [String: Any]? = nil) {
        guard currentLogLevel <= .warning else { return }
        log(level: .warning, message, context: context)
    }

    /// Log error message (always logged)
    static func error(_ message: String, context: [String: Any]? = nil) {
        log(level: .error, message, context: context)
    }

    // MARK: - Category-Specific Logging

    /// Log AI-related message
    static func ai(_ level: LogLevel = .info, _ message: String, context: [String: Any]? = nil) {
        guard currentLogLevel <= level else { return }
        log(using: aiLogger, level: level, message, context: context)
    }

    /// Log CloudKit-related message
    static func cloudkit(_ level: LogLevel = .info, _ message: String, context: [String: Any]? = nil) {
        guard currentLogLevel <= level else { return }
        log(using: cloudkitLogger, level: level, message, context: context)
    }

    /// Log Contacts-related message
    static func contacts(_ level: LogLevel = .info, _ message: String, context: [String: Any]? = nil) {
        guard currentLogLevel <= level else { return }
        log(using: contactsLogger, level: level, message, context: context)
    }

    // MARK: - Private Logging Implementation

    private static func log(level: LogLevel, _ message: String, context: [String: Any]?) {
        log(using: mainLogger, level: level, message, context: context)
    }

    private static func log(using logger: Logger, level: LogLevel, _ message: String, context: [String: Any]?) {
        let osLogType: OSLogType
        switch level {
        case .debug:
            osLogType = .debug
        case .info:
            osLogType = .info
        case .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        }

        // Build full message with context
        var fullMessage = message
        if let context = context, !context.isEmpty {
            let contextString = context.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            fullMessage += " [\(contextString)]"
        }

        // Log to OSLog
        logger.log(level: osLogType, "\(fullMessage, privacy: .public)")

        // Optionally log to file
        if enableFileLogging {
            logToFile(level: level, message: fullMessage)
        }
    }

    // MARK: - File Logging

    private static func logToFile(level: LogLevel, message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())

        let logLine = "[\(timestamp)] [\(level.prefix)] \(message)\n"

        guard let logURL = logFileURL else { return }

        // Check file size and rotate if needed
        if let fileSize = try? FileManager.default.attributesOfItem(atPath: logURL.path)[.size] as? UInt64,
           fileSize > maxLogFileSize {
            rotateLogFile()
        }

        // Append to log file
        if let handle = try? FileHandle(forWritingTo: logURL) {
            handle.seekToEndOfFile()
            if let data = logLine.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        } else {
            // Create new log file
            try? logLine.write(to: logURL, atomically: true, encoding: .utf8)
        }
    }

    private static var logFileURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent("aipresents.log")
    }

    private static func rotateLogFile() {
        guard let logURL = logFileURL else { return }

        // Move current log to backup
        let backupURL = logURL.deletingLastPathComponent().appendingPathComponent("aipresents.1.log")

        // Delete old backup if exists
        try? FileManager.default.removeItem(at: backupURL)

        // Move current log to backup
        try? FileManager.default.moveItem(at: logURL, to: backupURL)
    }

    // MARK: - Utility Methods

    /// Get log file contents (for debugging/reporting)
    static func getLogContents(maxBytes: Int = 100_000) -> String? {
        guard let logURL = logFileURL,
              let data = try? Data(contentsOf: logURL),
              data.count > 0 else {
            return nil
        }

        // Return last N bytes
        let startOffset = max(0, data.count - maxBytes)
        let truncatedData = data.subdata(in: startOffset..<data.count)

        return String(data: truncatedData, encoding: .utf8)
    }

    /// Clear log file
    static func clearLogs() {
        guard let logURL = logFileURL else { return }
        try? FileManager.default.removeItem(at: logURL)
    }

    /// Export logs to file for sharing
    static func exportLogs() -> URL? {
        guard let logURL = logFileURL else { return nil }

        let exporter = logURL.deletingLastPathComponent().appingPathComponent("aipresents-export-\(Date().timeIntervalSince1970).log")

        // Copy log file
        try? FileManager.default.copyItem(at: logURL, to: exporter)

        return exporter
    }
}

// MARK: - Convenience Extensions

extension AppLogger {
    /// Log performance metrics
    static func performance(_ operation: String, duration: TimeInterval, context: [String: Any]? = nil) {
        #if DEBUG
        let perfContext = (context ?? [:]).merging(["duration_ms": Int(duration * 1000)]) { _, new in new }
        debug("⏱️ \(operation) completed", context: perfContext)
        #endif
    }

    /// Log network request
    static func network(_ url: String, method: String, statusCode: Int?, duration: TimeInterval) {
        let context: [String: Any] = [
            "url": url,
            "method": method,
            "status": statusCode ?? "unknown",
            "duration_ms": Int(duration * 1000)
        ]

        if let status = statusCode, status >= 400 {
            error("Network request failed", context: context)
        } else {
            debug("Network request completed", context: context)
        }
    }

    /// Log user action (for analytics)
    static func userAction(_ action: String, context: [String: Any]? = nil) {
        #if DEBUG
        info("User action: \(action)", context: context)
        #endif
    }
}

// MARK: - Log Level Configuration (Runtime)

#if DEBUG
extension AppLogger {
    /// Set log level at runtime (debug builds only)
    static func setLogLevel(_ level: LogLevel) {
        // Implementation note: This would need to be stored in a mutable variable
        // For now, the level is compile-time configured
        assertionFailure("Runtime log level change not yet implemented")
    }
}
#endif
