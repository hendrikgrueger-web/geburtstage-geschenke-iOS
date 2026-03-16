import SwiftUI
import SwiftData

enum BudgetRange: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case premium = "premium"

    var localizedName: String {
        switch self {
        case .low: return String(localized: "Klein (bis 25€)")
        case .medium: return String(localized: "Mittel (25-75€)")
        case .high: return String(localized: "Groß (75-150€)")
        case .premium: return String(localized: "Premium (150€+)")
        }
    }

    var min: Double {
        switch self {
        case .low: return 0
        case .medium: return 25
        case .high: return 75
        case .premium: return 150
        }
    }

    var max: Double {
        switch self {
        case .low: return 25
        case .medium: return 75
        case .high: return 150
        case .premium: return 300
        }
    }
}

struct AIGiftSuggestionsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: PersonRef
    @Query private var giftHistory: [GiftHistory]
    @Query private var existingGiftIdeas: [GiftIdea]

    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var suggestions: [GiftSuggestion] = []
    @State private var errorMessage: String?
    @State private var selectedSuggestion: GiftSuggestion?
    @State private var budgetValue: Double = 50
    @State private var qualityViewModel: SuggestionQualityViewModel?
    @State private var showingConsentSheet = false
    @ObservedObject private var consentManager = AIConsentManager.shared

    // Track which suggestions have received feedback
    @State private var feedbackGivenForSuggestions = Set<String>()
    @State private var fetchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Form {
                // Person Details Card
                Section {
                    personDetailsCard
                }

                // Quality Metrics Section (only show when we have data)
                if let viewModel = qualityViewModel, viewModel.metrics.totalFeedback > 0 {
                    qualityMetricsSection(viewModel)
                }

                if isLoading && suggestions.isEmpty {
                    loadingState
                } else if let error = errorMessage, suggestions.isEmpty {
                    errorState(error)
                } else if !suggestions.isEmpty {
                    suggestionsList
                } else {
                    budgetSection
                }
            }
            .onAppear {
                if qualityViewModel == nil {
                    qualityViewModel = SuggestionQualityViewModel(modelContext: modelContext)
                }
            }
            .navigationTitle("KI-Geschenk-Ideen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedSuggestion) { suggestion in
            AddGiftIdeaSheet(
                person: person,
                prefillTitle: suggestion.title,
                prefillNote: suggestion.reason
            )
        }
        .sheet(isPresented: $showingConsentSheet) {
            AIConsentSheet(isPresented: $showingConsentSheet) {
                consentManager.aiEnabled = true
                errorMessage = nil
                loadSuggestions()
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var personDetailsCard: some View {
        HStack(spacing: 16) {
            PersonAvatar(person: person, size: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)

                Text(person.relation)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)

                if !filteredGiftHistory.isEmpty {
                    Text(filteredGiftHistory.count == 1
                         ? String(localized: "\(filteredGiftHistory.count) vergangenes Geschenk")
                         : String(localized: "\(filteredGiftHistory.count) vergangene Geschenke"))
                        .font(.caption)
                        .foregroundStyle(AppColor.textTertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func qualityMetricsSection(_ viewModel: SuggestionQualityViewModel) -> some View {
        let personMetrics = viewModel.metricsFor(personId: person.id)

        return Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("KI-Qualität")
                            .font(.headline)
                            .foregroundStyle(AppColor.textPrimary)

                        Text(personMetrics.ratingText)
                            .font(.subheadline)
                            .foregroundStyle(AppColor.accent)
                    }

                    Spacer()

                    Text(String(localized: "\(personMetrics.totalFeedback)× Feedback"))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColor.primary.opacity(0.1))
                        .foregroundStyle(AppColor.primary)
                        .clipShape(.rect(cornerRadius: 8))
                }

                if personMetrics.totalFeedback >= 5 {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("\(personMetrics.positiveFeedback)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(AppColor.success)
                            Text("Positiv")
                                .font(.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }

                        VStack(alignment: .leading) {
                            Text("\(personMetrics.negativeFeedback)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(AppColor.danger)
                            Text("Negativ")
                                .font(.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(String(format: "%.0f%%", personMetrics.positivityRate * 100))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(AppColor.primary)
                            Text("Akzeptanz")
                                .font(.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Qualitätsmetrik")
        } footer: {
            Text("Dein Feedback hilft, die KI-Vorschläge zu verbessern.")
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var loadingState: some View {
        Section {
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)

                Text("KI denkt nach…")
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
        }
    }

    private var needsConsent: Bool {
        !consentManager.consentGiven || !consentManager.aiEnabled
    }

    private func errorState(_ error: String) -> some View {
        Section {
            VStack(spacing: 16) {
                if needsConsent {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 50))
                        .foregroundStyle(AppColor.primary)

                    Text("Einwilligung erforderlich")
                        .font(.headline)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("Für KI-Vorschläge wird eine Einwilligung zur anonymisierten Datenverarbeitung benötigt.")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        showingConsentSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.shield")
                            Text("Einwilligung erteilen")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(AppColor.accent)

                    Text("Fehler")
                        .font(.headline)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)

                    Button("Erneut versuchen") {
                        loadSuggestions()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
    }

    private var suggestionsList: some View {
        let filteredSuggestions = suggestions.filter { suggestion in
            !existingGiftIdeaTitles.contains(suggestion.title.lowercased().trimmingCharacters(in: .whitespaces))
        }

        return Section {
            if filteredSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColor.textSecondary.opacity(0.4))

                    Text("Keine neuen Vorschläge")
                        .font(.headline)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("Alle Vorschläge existieren bereits als Geschenkideen.")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else {
                ForEach(Array(filteredSuggestions.enumerated()), id: \.offset) { index, suggestion in
                    VStack(alignment: .leading, spacing: 0) {
                        suggestionCard(suggestion: suggestion, index: index)

                        // Feedback section
                        if !feedbackGivenForSuggestions.contains(suggestion.title) {
                            SuggestionFeedbackView(
                                suggestion: suggestion,
                                personId: person.id,
                                onFeedback: { isPositive in
                                    handleFeedback(for: suggestion, isPositive: isPositive)
                                }
                            )
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppColor.success)
                                Text("Feedback gespeichert")
                                    .font(.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Always allow saving as gift idea
                        selectedSuggestion = suggestion
                        HapticFeedback.medium()
                    }
                }
            }
            if suggestions.count < 30 {
                Button {
                    loadMoreSuggestions()
                } label: {
                    HStack {
                        if isLoadingMore {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("5 weitere generieren")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoadingMore)
                .padding(.vertical, 4)
            }
        } header: {
            Text("Vorschläge (\(filteredSuggestions.count))")
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tippe auf einen Vorschlag, um ihn als Geschenkidee zu speichern.")
                if suggestions.count != filteredSuggestions.count {
                    let diff = suggestions.count - filteredSuggestions.count
                    Text(diff == 1
                         ? String(localized: "\(diff) Vorschlag bereits vorhanden.")
                         : String(localized: "\(diff) Vorschläge bereits vorhanden."))
                }
                Text("\(suggestions.count)/30 Vorschläge generiert")
            }
            .font(.caption)
            .foregroundStyle(AppColor.textSecondary)
        }
    }

    private func suggestionCard(suggestion: GiftSuggestion, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(suggestion.title)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppColor.primary)
            }

            Text(suggestion.reason)
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }

    private var budgetSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Budget")
                    Spacer()
                    Text(budgetLabel)
                        .foregroundStyle(.secondary)
                }

                Slider(
                    value: $budgetValue,
                    in: 0...500,
                    step: 5
                )
                .accessibilityLabel("Budget")
                .accessibilityValue(budgetLabel)
            }

            generateButton
        } header: {
            Text("KI-Assistent")
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "cloud.fill")
                        .foregroundStyle(AppColor.primary)
                    Text("Cloud-KI via OpenRouter · Daten werden verschlüsselt übertragen.")
                        .foregroundStyle(AppColor.primary)
                }

                if !filteredGiftHistory.isEmpty {
                    Text(filteredGiftHistory.count == 1
                         ? String(localized: "Basiert auf \(filteredGiftHistory.count) vergangenen Geschenk.")
                         : String(localized: "Basiert auf \(filteredGiftHistory.count) vergangenen Geschenken."))
                        .foregroundStyle(AppColor.accent)
                }
            }
            .font(.caption)
            .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var budgetLabel: String {
        if budgetValue == 0 {
            return String(localized: "Egal")
        }
        return String(localized: "bis") + " " + CurrencyManager.shared.formatAmount(budgetValue)
    }

    private var generateButton: some View {
        Button(action: {
            loadSuggestions()
        }) {
            HStack {
                Image(systemName: "sparkles")
                Text("KI-Vorschläge generieren")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    private var filteredGiftHistory: [GiftHistory] {
        giftHistory
            .filter { $0.personId == person.id && $0.giftDirection == .given }
            .sorted { $0.year > $1.year }
            .prefix(5)
            .map { $0 }
    }

    private var existingGiftIdeaTitles: Set<String> {
        Set(existingGiftIdeas
            .filter { $0.personId == person.id }
            .map { $0.title.lowercased().trimmingCharacters(in: .whitespaces) })
    }

    private func loadSuggestions() {
        isLoading = true
        errorMessage = nil
        suggestions = []
        HapticFeedback.light()
        fetchSuggestions()
    }

    private func loadMoreSuggestions() {
        guard suggestions.count < 30, !isLoadingMore else { return }
        isLoadingMore = true
        errorMessage = nil
        HapticFeedback.light()
        fetchSuggestions()
    }

    private func fetchSuggestions() {
        fetchTask?.cancel()
        let maxBudget = budgetValue
        let history = filteredGiftHistory
        let existingTitles = suggestions.map { $0.title }
        let p = person
        fetchTask = Task { @MainActor in
            do {
                let newSuggestions = try await AIService.shared.generateGiftIdeas(
                    for: p,
                    budgetMin: 0,
                    budgetMax: maxBudget == 0 ? 500 : maxBudget,
                    tags: [],
                    pastGifts: history,
                    excludeTitles: existingTitles
                )
                // Deduplizieren und anhängen
                let existingSet = Set(suggestions.map { $0.title.lowercased() })
                let unique = newSuggestions.filter { !existingSet.contains($0.title.lowercased()) }
                suggestions.append(contentsOf: unique)
                // Max 30
                if suggestions.count > 30 {
                    suggestions = Array(suggestions.prefix(30))
                }
                isLoading = false
                isLoadingMore = false
                HapticFeedback.success()
            } catch {
                isLoading = false
                isLoadingMore = false
                errorMessage = error.localizedDescription
                HapticFeedback.error()
            }
        }
    }

    private func handleFeedback(for suggestion: GiftSuggestion, isPositive: Bool) {
        qualityViewModel?.recordFeedback(
            personId: person.id,
            suggestion: suggestion,
            isPositive: isPositive
        )

        feedbackGivenForSuggestions.insert(suggestion.title)
    }
}
