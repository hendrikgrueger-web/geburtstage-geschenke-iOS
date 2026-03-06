import Foundation
import SwiftData

/// Feedback model for tracking AI suggestion quality
@Model
final class SuggestionFeedback {
    var id: UUID
    var personId: UUID
    var suggestionTitle: String
    var suggestionReason: String
    var isPositive: Bool
    var timestamp: Date

    init(
        id: UUID = UUID(),
        personId: UUID,
        suggestionTitle: String,
        suggestionReason: String,
        isPositive: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.personId = personId
        self.suggestionTitle = suggestionTitle
        self.suggestionReason = suggestionReason
        self.isPositive = isPositive
        self.timestamp = timestamp
    }
}

/// Quality metrics for AI suggestion performance
struct SuggestionQualityMetrics {
    var totalFeedback: Int = 0
    var positiveFeedback: Int = 0
    var negativeFeedback: Int = 0
    var positivityRate: Double {
        guard totalFeedback > 0 else { return 0.0 }
        return Double(positiveFeedback) / Double(totalFeedback)
    }

    var ratingText: String {
        switch positivityRate {
        case 0.8...1.0:
            return "⭐⭐⭐⭐⭐ " + String(localized: "Ausgezeichnet")
        case 0.6..<0.8:
            return "⭐⭐⭐⭐ " + String(localized: "Gut")
        case 0.4..<0.6:
            return "⭐⭐⭐ " + String(localized: "Akzeptabel")
        case 0.2..<0.4:
            return "⭐⭐ " + String(localized: "Verbesserungswürdig")
        case 0.0..<0.2:
            return "⭐ " + String(localized: "Kritisch")
        default:
            return String(localized: "Keine Daten")
        }
    }

    static func from(feedbacks: [SuggestionFeedback]) -> SuggestionQualityMetrics {
        let total = feedbacks.count
        let positive = feedbacks.filter { $0.isPositive }.count
        let negative = total - positive

        return SuggestionQualityMetrics(
            totalFeedback: total,
            positiveFeedback: positive,
            negativeFeedback: negative
        )
    }
}
