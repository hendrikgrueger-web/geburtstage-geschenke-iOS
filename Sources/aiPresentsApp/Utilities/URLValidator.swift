import Foundation
import UIKit

@MainActor
enum URLValidator {
    /// Validates and sanitizes a URL string
    /// - Returns: A tuple containing the sanitized URL string and whether it's valid
    nonisolated static func validate(_ urlString: String) -> (sanitized: String, isValid: Bool) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return ("", true)
        }

        var sanitized = trimmed

        // Reject http:// URLs (only https:// allowed)
        if sanitized.lowercased().hasPrefix("http://") {
            return (trimmed, false)
        }

        // Add https:// prefix if missing
        if !sanitized.lowercased().hasPrefix("https://") {
            sanitized = "https://" + sanitized
        }

        // Check if it's a valid HTTPS URL
        guard let url = URL(string: sanitized),
              url.scheme?.lowercased() == "https",
              url.host != nil else {
            return (trimmed, false)
        }

        return (sanitized, true)
    }
    
    /// Quick check if URL can be opened
    static func canOpen(_ urlString: String) -> Bool {
        let (sanitized, isValid) = validate(urlString)
        guard isValid, let url = URL(string: sanitized) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}
