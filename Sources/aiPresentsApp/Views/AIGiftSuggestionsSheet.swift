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
    @State private var suggestions: [GiftSuggestion] = []
    @State private var errorMessage: String?
    @State private var selectedSuggestion: GiftSuggestion?
    @State private var selectedBudget: BudgetRange = .medium
    @State private var showDemoModeNotice = false

    var body: some View {
        NavigationStack {
            Form {
                // Person Details Card
                Section {
                    personDetailsCard
                }

                if isLoading {
                    loadingState
                } else if let error = errorMessage {
                    errorState(error)
                } else if !suggestions.isEmpty {
                    suggestionsList
                } else {
                    budgetSection
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
            .alert("Demo-Mode", isPresented: $showDemoModeNotice) {
                Button("OK") {
                    loadSuggestions()
                }
            } message: {
                Text("Da kein API-Key konfiguriert ist, werden Demo-Vorschläge angezeigt.")
            }
        }
    }

    private var personDetailsCard: View {
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

    private var loadingState: View {
        Section {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(AppColor.primary.opacity(0.2), lineWidth: 4)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            AppColor.primary,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
                }

                VStack(spacing: 4) {
                    Text("KI denkt nach...")
                        .font(.headline)
                        .foregroundColor(AppColor.textPrimary)

                    Text("Das kann ein paar Sekunden dauern")
                        .font(.caption)
                        .foregroundColor(AppColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
    }

    private func errorState(_ error: String) -> View {
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
                .buttonStyle(.pressable)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
    }

    private var suggestionsList: View {
        let filteredSuggestions = suggestions.filter { suggestion in
            !existingGiftIdeaTitles.contains(suggestion.title.lowercased().trimmingCharacters(in: .whitespaces))
        }

        Section {
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
                    suggestionCard(suggestion: suggestion, index: index)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSuggestion = suggestion
                            HapticFeedback.medium()
                        }
                }
            }
        } header: {
            Text("Vorschläge (\(filteredSuggestions.count))")
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("💡 Tippe auf einen Vorschlag, um ihn als Geschenkidee zu speichern.")
                if suggestions.count != filteredSuggestions.count {
                    Text("ℹ️ \(suggestions.count - filteredSuggestions.count) Vorschlag\(suggestions.count - filteredSuggestions.count == 1 ? "" : "e") bereits vorhanden.")
                }
                if suggestions.count >= 3 {
                    Text("✨ Möchtest du mehr Vorschläge? Tippe oben auf 'Aktualisieren'.")
                }
            }
            .font(.caption)
            .foregroundColor(AppColor.textSecondary)
        }
    }

    private func suggestionCard(suggestion: GiftSuggestion, index: Int) -> View {
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

    private var budgetSection: View {
        Section {
            budgetPicker
            generateButton
        } header: {
            Text("KI-Assistent")
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Die KI analysiert vergangene Geschenke und die Beziehung, um passende Vorschläge zu generieren.")

                if !filteredGiftHistory.isEmpty {
                    Text("📋 Basiert auf \(filteredGiftHistory.count) vergangenen Geschenk\(filteredGiftHistory.count == 1 ? "" : "en").")
                        .foregroundColor(AppColor.accent)
                }
            }
            .font(.caption)
            .foregroundColor(AppColor.textSecondary)
        }
    }

    private var budgetPicker: View {
        Picker("Budget-Bereich", selection: $selectedBudget) {
            ForEach(BudgetRange.allCases, id: \.self) { budget in
                Text(budget.rawValue).tag(budget)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Budget-Bereich wählen")
    }

    private var generateButton: View {
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
        .buttonStyle(.pressable)
    }

    private var filteredGiftHistory: [GiftHistory] {
        giftHistory
            .filter { $0.personId == person.id }
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

        Task {
            do {
                let newSuggestions = try await AIService.shared.generateGiftIdeas(
                    for: person,
                    budgetMin: selectedBudget.min,
                    budgetMax: selectedBudget.max,
                    tags: [],
                    pastGifts: filteredGiftHistory
                )

                await MainActor.run {
                    isLoading = false
                    suggestions = newSuggestions
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    HapticFeedback.error()
                }
            }
        }
    }
}
