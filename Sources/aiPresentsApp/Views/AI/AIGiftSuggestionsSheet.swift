import SwiftUI
import SwiftData

enum BudgetRange: String, CaseIterable {
    case low = "Klein (bis 25€)"
    case medium = "Mittel (25-75€)"
    case high = "Groß (75-150€)"
    case premium = "Premium (150€+)"

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
    @State private var selectedBudget: BudgetRange = .medium
    @State private var qualityViewModel: SuggestionQualityViewModel?

    // Track which suggestions have received feedback
    @State private var feedbackGivenForSuggestions = Set<String>()

    private var isUsingCloudAI: Bool { AIService.isAvailable }

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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedSuggestion) { suggestion in
                AddGiftIdeaSheet(
                    person: person,
                    prefillTitle: suggestion.title,
                    prefillNote: suggestion.reason
                )
            }
            }
    }

    private var personDetailsCard: some View {
        HStack(spacing: 16) {
            PersonAvatar(person: person, size: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.headline)
                    .foregroundColor(AppColor.textPrimary)

                Text(person.relation)
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)

                if !filteredGiftHistory.isEmpty {
                    Text("\(filteredGiftHistory.count) vergangene Geschenk\(filteredGiftHistory.count == 1 ? "" : "e")")
                        .font(.caption)
                        .foregroundColor(AppColor.textTertiary)
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
                            .foregroundColor(AppColor.textPrimary)

                        Text(personMetrics.ratingText)
                            .font(.subheadline)
                            .foregroundColor(AppColor.accent)
                    }

                    Spacer()

                    Text("\(personMetrics.totalFeedback)× Feedback")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColor.primary.opacity(0.1))
                        .foregroundColor(AppColor.primary)
                        .clipShape(.rect(cornerRadius: 8))
                }

                if personMetrics.totalFeedback >= 5 {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("\(personMetrics.positiveFeedback)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Positiv")
                                .font(.caption)
                                .foregroundColor(AppColor.textSecondary)
                        }

                        VStack(alignment: .leading) {
                            Text("\(personMetrics.negativeFeedback)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Text("Negativ")
                                .font(.caption)
                                .foregroundColor(AppColor.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(String(format: "%.0f%%", personMetrics.positivityRate * 100))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppColor.primary)
                            Text("Akzeptanz")
                                .font(.caption)
                                .foregroundColor(AppColor.textSecondary)
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
                .foregroundColor(AppColor.textSecondary)
        }
    }

    private var loadingState: some View {
        Section {
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)

                Text("KI denkt nach…")
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
        }
    }

    private func errorState(_ error: String) -> some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)

                Text("Fehler")
                    .font(.headline)
                    .foregroundColor(AppColor.textPrimary)

                Text(error)
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Erneut versuchen") {
                    loadSuggestions()
                }
                .buttonStyle(.borderedProminent)
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
                        .foregroundColor(AppColor.textSecondary.opacity(0.4))

                    Text("Keine neuen Vorschläge")
                        .font(.headline)
                        .foregroundColor(AppColor.textPrimary)

                    Text("Alle Vorschläge existieren bereits als Geschenkideen.")
                        .font(.subheadline)
                        .foregroundColor(AppColor.textSecondary)
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
                                    .foregroundColor(.green)
                                Text("Feedback gespeichert")
                                    .font(.caption)
                                    .foregroundColor(AppColor.textSecondary)
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
                    Text("\(suggestions.count - filteredSuggestions.count) Vorschlag\(suggestions.count - filteredSuggestions.count == 1 ? "" : "e") bereits vorhanden.")
                }
                Text("\(suggestions.count)/30 Vorschläge generiert")
            }
            .font(.caption)
            .foregroundColor(AppColor.textSecondary)
        }
    }

    private func suggestionCard(suggestion: GiftSuggestion, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(suggestion.title)
                    .font(.headline)
                    .foregroundColor(AppColor.textPrimary)

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppColor.primary)
            }

            Text(suggestion.reason)
                .font(.subheadline)
                .foregroundColor(AppColor.textSecondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }

    private var budgetSection: some View {
        Section {
            budgetPicker
            budgetDetailCard
            generateButton
        } header: {
            Text("KI-Assistent")
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: isUsingCloudAI ? "cloud.fill" : "sparkles")
                        .foregroundColor(isUsingCloudAI ? .blue : .orange)
                    Text(isUsingCloudAI
                         ? "Cloud-KI via OpenRouter · Daten werden verschlüsselt übertragen."
                         : "Demo-Modus — kein API-Key konfiguriert oder KI nicht aktiviert.")
                        .foregroundColor(isUsingCloudAI ? .blue : .orange)
                }

                if !filteredGiftHistory.isEmpty {
                    Text("📋 Basiert auf \(filteredGiftHistory.count) vergangenen Geschenk\(filteredGiftHistory.count == 1 ? "" : "en").")
                        .foregroundColor(AppColor.accent)
                }
            }
            .font(.caption)
            .foregroundColor(AppColor.textSecondary)
        }
    }

    private var budgetPicker: some View {
        Picker("Budget-Bereich", selection: $selectedBudget) {
            ForEach(BudgetRange.allCases, id: \.self) { budget in
                BudgetRangeCompactView(budgetRange: budget, isSelected: selectedBudget == budget)
                    .tag(budget)
            }
        }
        .pickerStyle(.automatic)
        .accessibilityLabel("Budget-Bereich wählen")
    }

    private var budgetDetailCard: some View {
        BudgetRangeView(budgetRange: selectedBudget)
            .padding(.vertical, 4)
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
        let budget = selectedBudget
        let history = filteredGiftHistory
        let existingTitles = suggestions.map { $0.title }
        let p = person
        Task { @MainActor in
            do {
                let newSuggestions = try await AIService.shared.generateGiftIdeas(
                    for: p,
                    budgetMin: budget.min,
                    budgetMax: budget.max,
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
