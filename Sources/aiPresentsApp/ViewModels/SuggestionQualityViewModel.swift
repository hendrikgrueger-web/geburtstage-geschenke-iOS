import Foundation
import SwiftData

@MainActor
class SuggestionQualityViewModel: ObservableObject {
    @Published var metrics: SuggestionQualityMetrics = SuggestionQualityMetrics()

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadMetrics()
    }

    /// Record feedback for a suggestion
    func recordFeedback(
        personId: UUID,
        suggestion: GiftSuggestion,
        isPositive: Bool
    ) {
        let feedback = SuggestionFeedback(
            personId: personId,
            suggestionTitle: suggestion.title,
            suggestionReason: suggestion.reason,
            isPositive: isPositive
        )

        modelContext.insert(feedback)
        do {
            try modelContext.save()
            loadMetrics()
            HapticFeedback.success()
        } catch {
            HapticFeedback.error()
            AppLogger.ai.error("Failed to save feedback", error: error)
        }
    }

    /// Load quality metrics from feedback data
    func loadMetrics() {
        let descriptor = FetchDescriptor<SuggestionFeedback>()
        guard let feedbacks = try? modelContext.fetch(descriptor) else {
            metrics = SuggestionQualityMetrics()
            return
        }

        metrics = SuggestionQualityMetrics.from(feedbacks: feedbacks)
    }

    /// Get feedback for a specific person
    func feedbackFor(personId: UUID) -> [SuggestionFeedback] {
        let descriptor = FetchDescriptor<SuggestionFeedback>(
            predicate: #Predicate<SuggestionFeedback> { $0.personId == personId }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Get metrics for a specific person
    func metricsFor(personId: UUID) -> SuggestionQualityMetrics {
        let feedbacks = feedbackFor(personId: personId)
        return SuggestionQualityMetrics.from(feedbacks: feedbacks)
    }

    /// Clear all feedback data (for testing/reset)
    func clearAllFeedback() {
        let descriptor = FetchDescriptor<SuggestionFeedback>()
        guard let feedbacks = try? modelContext.fetch(descriptor) else { return }

        for feedback in feedbacks {
            modelContext.delete(feedback)
        }

        do {
            try modelContext.save()
            loadMetrics()
        } catch {
            AppLogger.ai.error("Failed to clear feedback", error: error)
        }
    }
}
