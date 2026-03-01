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

    @State private var isLoading = false
    @State private var suggestions: [GiftSuggestion] = []
    @State private var errorMessage: String?
    @State private var selectedSuggestion: GiftSuggestion?
    @State private var selectedBudget: BudgetRange = .medium

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Empfänger")
                        Spacer()
                        Text(person.displayName)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Beziehung")
                        Spacer()
                        Text(person.relation)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Details")
                }

                if isLoading {
                    Section {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text("KI denkt nach...")
                                    .font(.subheadline)
                                Text("Das kann ein paar Sekunden dauern")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    }
                } else if let error = errorMessage {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)

                            Text("Fehler")
                                .font(.headline)

                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Button("Erneut versuchen") {
                                loadSuggestions()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    }
                } else if !suggestions.isEmpty {
                    Section {
                        ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(suggestion.title)
                                    .font(.headline)

                                Text(suggestion.reason)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSuggestion = suggestion
                            }
                        }
                    } header: {
                        Text("Vorschläge")
                    } footer: {
                        Text("Tippe auf einen Vorschlag, um ihn als Geschenkidee zu speichern")
                    }
                } else {
                    Section("Budget") {
                        Picker("Budget-Bereich", selection: $selectedBudget) {
                            ForEach(BudgetRange.allCases, id: \.self) { budget in
                                Text(budget.rawValue).tag(budget)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Budget-Bereich wählen")
                    }

                    Section {
                        Button(action: loadSuggestions) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("KI-Vorschläge generieren")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    } header: {
                        Text("KI-Assistent")
                    } footer: {
                        Text("Die KI analysiert vergangene Geschenke und schlägt neue Ideen vor.")
                    }
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

    private var filteredGiftHistory: [GiftHistory] {
        giftHistory
            .filter { $0.personId == person.id }
            .sorted { $0.year > $1.year }
            .prefix(5)
            .map { $0 }
    }

    private func loadSuggestions() {
        isLoading = true
        errorMessage = nil
        suggestions = []

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
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
