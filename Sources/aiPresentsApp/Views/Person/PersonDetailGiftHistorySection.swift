import SwiftUI
import SwiftData

/// "Verschenkt" + "Von [Person] erhalten" Sections mit GiftHistory-Rows.
struct PersonDetailGiftHistorySection: View {
    @Environment(\.modelContext) private var modelContext

    let person: PersonRef
    let giftHistory: [GiftHistory]
    @Binding var showingAddGiftHistory: Bool
    @Binding var showingAddReceivedGift: Bool
    @Binding var showingEditGiftHistory: GiftHistory?
    @Binding var showingShareSheet: Bool
    @Binding var shareText: String
    @Binding var toast: ToastItem?

    var body: some View {
        givenSection
        receivedSection
    }

    // MARK: - Verschenkt Section

    private var givenSection: some View {
        Section {
            if givenGiftHistory.isEmpty {
                EmptyStateView(type: .noHistory, action: {
                    showingAddGiftHistory = true
                    HapticFeedback.light()
                })
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else {
                ForEach(givenGiftHistory) { history in
                    Button {
                        showingEditGiftHistory = history
                    } label: {
                        GiftHistoryRow(
                            history: history,
                            onShare: { shareGiftHistory(history) },
                            onReuseAsIdea: { copyToGiftIdea(history) }
                        )
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            copyToGiftIdea(history)
                        } label: {
                            Label("Als Idee", systemImage: "lightbulb.circle.fill")
                        }
                        .tint(AppColor.primary)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            if let index = givenGiftHistory.firstIndex(where: { $0.id == history.id }) {
                                deleteGiftHistory(at: IndexSet([index]))
                            }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }

                Button {
                    showingAddGiftHistory = true
                    HapticFeedback.medium()
                } label: {
                    Label("Eintrag hinzufügen", systemImage: "plus.circle.fill")
                        .foregroundStyle(AppColor.primary)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityLabel(String(localized: "Verschenktes Geschenk hinzufügen"))
                .accessibilityHint(String(localized: "Fügt ein verschenktes Geschenk hinzu"))
            }
        } header: {
            Text("Verschenkt")
        } footer: {
            Text("In früheren Jahren verschenkt")
        }
    }

    // MARK: - Erhalten Section

    private var receivedSection: some View {
        Section {
            if receivedGiftHistory.isEmpty {
                Text("Noch keine erhaltenen Geschenke")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(receivedGiftHistory) { history in
                    Button {
                        showingEditGiftHistory = history
                    } label: {
                        GiftHistoryRow(
                            history: history,
                            onShare: { shareGiftHistory(history) },
                            onReuseAsIdea: nil
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            if let index = receivedGiftHistory.firstIndex(where: { $0.id == history.id }) {
                                deleteReceivedGiftHistory(at: IndexSet([index]))
                            }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }
            }

            Button {
                showingAddReceivedGift = true
                HapticFeedback.medium()
            } label: {
                Label("Eintrag hinzufügen", systemImage: "plus.circle.fill")
                    .foregroundStyle(AppColor.primary)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityLabel(String(localized: "Erhaltenes Geschenk hinzufügen"))
            .accessibilityHint(String(localized: "Fügt ein erhaltenes Geschenk hinzu"))
        } header: {
            Text("Von \(person.displayName) erhalten")
        }
    }

    // MARK: - Computed Properties

    private var givenGiftHistory: [GiftHistory] {
        giftHistory
            .filter { $0.giftDirection == .given }
            .sorted { $0.year > $1.year }
    }

    private var receivedGiftHistory: [GiftHistory] {
        giftHistory
            .filter { $0.giftDirection == .received }
            .sorted { $0.year > $1.year }
    }

    // MARK: - Actions

    private func deleteGiftHistory(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(givenGiftHistory[index])
            }
            HapticFeedback.warning()
        }
    }

    private func deleteReceivedGiftHistory(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(receivedGiftHistory[index])
            }
            HapticFeedback.warning()
        }
    }

    private func copyToGiftIdea(_ history: GiftHistory) {
        let newIdea = GiftIdea(
            personId: person.id,
            title: history.title,
            note: history.note.isEmpty ? String(localized: "Kopiert aus Geschenk-Verlauf (\(history.year))") : history.note,
            budgetMin: history.budget * 0.8,
            budgetMax: history.budget * 1.2,
            link: history.link,
            status: .idea,
            tags: [history.category]
        )
        modelContext.insert(newIdea)
        triggerWidgetUpdate()
        HapticFeedback.success()
    }

    private func shareGiftHistory(_ history: GiftHistory) {
        var text = "🎁 \(history.title) (\(history.year))\n"
        text += "📝 \(history.category)\n"

        if history.budget > 0 {
            text += "💰 \(Int(history.budget))€\n"
        }

        if !history.note.isEmpty {
            text += "📝 \(history.note)\n"
        }

        if !history.link.isEmpty {
            text += "🔗 \(history.link)\n"
        }

        shareText = text
        showingShareSheet = true
        toast = ToastItem.info(String(localized: "Teilen"), message: String(localized: "Teilen-Dialog geöffnet"))
    }

    private func triggerWidgetUpdate() {
        WidgetDataService.shared.updateWidgetData(from: modelContext)
    }
}
