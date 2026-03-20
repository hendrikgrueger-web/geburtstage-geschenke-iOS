import SwiftUI
import SwiftData

/// Geschenkideen-Section: Filter-Bar, Status-Bar, GiftIdea-Rows mit swipeActions.
struct PersonDetailGiftIdeasSection: View {
    @Environment(\.modelContext) private var modelContext

    let person: PersonRef
    let giftIdeas: [GiftIdea]
    @Binding var giftSortOption: GiftSortOption
    @Binding var giftStatusFilter: GiftStatusFilter
    @Binding var showingAddGiftIdea: Bool
    @Binding var showingEditGiftIdea: GiftIdea?
    @Binding var showingShareSheet: Bool
    @Binding var shareText: String
    @Binding var showingMarkAllAsGivenConfirmation: Bool
    @Binding var toast: ToastItem?

    var body: some View {
        Section {
            GiftSummaryView(person: person)

            if filteredGiftIdeas.isEmpty {
                emptyStateButton
            } else {
                giftIdeaRows
                addIdeaButton
            }
        } header: {
            headerView
        } footer: {
            footerView
        }
    }

    // MARK: - Sub-Views

    private var emptyStateButton: some View {
        Button {
            showingAddGiftIdea = true
            HapticFeedback.light()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColor.primary)
                Text("Geschenkidee hinzufügen")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .accessibilityLabel(String(localized: "Geschenkidee hinzufügen"))
        .accessibilityHint(String(localized: "Fügt eine neue Geschenkidee hinzu"))
    }

    private var giftIdeaRows: some View {
        ForEach(filteredGiftIdeas) { idea in
            Button {
                showingEditGiftIdea = idea
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    GiftIdeaRow(idea: idea)
                    if !idea.statusLog.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(idea.statusLog, id: \.self) { entry in
                                Text(entry)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.leading, 4)
                    }
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button {
                    advanceStatus(for: idea)
                } label: {
                    Label("Vor", systemImage: "arrow.right.circle.fill")
                }
                .tint(AppColor.primary)
                .accessibilityLabel(String(localized: "Status ändern"))
                .accessibilityHint(String(localized: "Ändert den Status der Geschenkidee zum nächsten Schritt"))
            }
            .contextMenu {
                Button {
                    shareText = idea.exportAsText()
                    showingShareSheet = true
                    HapticFeedback.light()
                } label: {
                    Label("Teilen", systemImage: "square.and.arrow.up")
                }
                .accessibilityLabel(String(localized: "Geschenkidee teilen"))

                Button {
                    duplicateGiftIdea(idea)
                } label: {
                    Label("Duplizieren", systemImage: "doc.on.doc")
                }
                .accessibilityLabel(String(localized: "Geschenkidee duplizieren"))

                Button {
                    advanceStatus(for: idea)
                } label: {
                    Label("Status vorwärts", systemImage: "arrow.right.circle.fill")
                }
                .accessibilityLabel(String(localized: "Status ändern"))

                Button(role: .destructive) {
                    if let index = filteredGiftIdeas.firstIndex(where: { $0.id == idea.id }) {
                        deleteGiftIdeas(at: IndexSet([index]))
                    }
                } label: {
                    Label("Löschen", systemImage: "trash")
                }
                .accessibilityLabel(String(localized: "Geschenkidee löschen"))
            }
        }
        .onDelete(perform: deleteGiftIdeas)
    }

    private var addIdeaButton: some View {
        Button {
            showingAddGiftIdea = true
            HapticFeedback.medium()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColor.primary)
                Text("Idee hinzufügen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .accessibilityLabel(String(localized: "Idee hinzufügen"))
        .accessibilityHint(String(localized: "Fügt eine neue Geschenkidee hinzu"))
    }

    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: 6) {
            Text("Geschenkideen")

            Spacer()

            // Status-Filter
            Menu {
                ForEach(GiftStatusFilter.allCases, id: \.self) { filter in
                    Button {
                        giftStatusFilter = filter
                        HapticFeedback.selectionChanged()
                    } label: {
                        if giftStatusFilter == filter {
                            Label(filter.displayName, systemImage: "checkmark")
                        } else {
                            Text(filter.displayName)
                        }
                    }
                }
            } label: {
                controlPill(
                    icon: "line.3.horizontal.decrease",
                    label: giftStatusFilter == .all ? String(localized: "Filter") : giftStatusFilter.displayName,
                    isActive: giftStatusFilter != .all
                )
            }

            // Sortierung
            Menu {
                ForEach(GiftSortOption.allCases, id: \.self) { option in
                    Button {
                        giftSortOption = option
                        HapticFeedback.selectionChanged()
                    } label: {
                        if giftSortOption == option {
                            Label(option.displayName, systemImage: "checkmark")
                        } else {
                            Text(option.displayName)
                        }
                    }
                }
            } label: {
                controlPill(
                    icon: "arrow.up.arrow.down",
                    label: giftSortOption == .status ? String(localized: "Sortierung") : giftSortOption.displayName,
                    isActive: giftSortOption != .status
                )
            }
        }
    }

    @ViewBuilder
    private var footerView: some View {
        if !filteredGiftIdeas.isEmpty && hasPurchasedGifts {
            Button(action: { showingMarkAllAsGivenConfirmation = true }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColor.success)
                    Text("Alle als verschenkt markieren")
                        .font(.subheadline)
                }
            }
        }
    }

    // MARK: - Computed Properties

    var filteredGiftIdeas: [GiftIdea] {
        let statusOrder: [GiftStatus] = [.idea, .planned, .purchased, .given]

        var ideas = giftIdeas

        switch giftStatusFilter {
        case .all:
            break
        case .idea:
            ideas = ideas.filter { $0.status == .idea }
        case .planned:
            ideas = ideas.filter { $0.status == .planned }
        case .purchased:
            ideas = ideas.filter { $0.status == .purchased }
        case .given:
            ideas = ideas.filter { $0.status == .given }
        }

        return ideas.sorted { idea1, idea2 in
            switch giftSortOption {
            case .status:
                let index1 = statusOrder.firstIndex(of: idea1.status) ?? 0
                let index2 = statusOrder.firstIndex(of: idea2.status) ?? 0
                if index1 != index2 {
                    return index1 < index2
                }
                return idea1.title < idea2.title
            case .budget:
                return idea1.budgetMax > idea2.budgetMax
            case .title:
                return idea1.title < idea2.title
            case .date:
                return idea1.createdAt > idea2.createdAt
            }
        }
    }

    private var hasPurchasedGifts: Bool {
        filteredGiftIdeas.contains { $0.status == .purchased }
    }

    // MARK: - Actions

    private func deleteGiftIdeas(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredGiftIdeas[index])
            }
            HapticFeedback.warning()
        }
        triggerWidgetUpdate()
    }

    private func advanceStatus(for idea: GiftIdea) {
        let dateString = FormatterHelper.shortLogDateFormatter.string(from: Date())
        let oldStatus = idea.status

        switch idea.status {
        case .idea:
            idea.status = .planned
        case .planned:
            idea.status = .purchased
        case .purchased:
            idea.status = .given
        case .given:
            break
        }

        if oldStatus != idea.status {
            idea.statusLog.append("\(dateString) - \(statusDisplayName(oldStatus)) \u{2192} \(statusDisplayName(idea.status))")
            triggerWidgetUpdate()
        }
        HapticFeedback.medium()
    }

    private func duplicateGiftIdea(_ idea: GiftIdea) {
        let existingTitles = giftIdeas
            .map { $0.title.lowercased().trimmingCharacters(in: .whitespaces) }

        let titleWithoutCopy = idea.title
            .replacingOccurrences(of: " (Kopie)", with: "")
            .replacingOccurrences(of: " (Copy)", with: "")
            .trimmingCharacters(in: .whitespaces)

        var newTitle = titleWithoutCopy
        var counter = 1
        while existingTitles.contains(newTitle.lowercased()) {
            counter += 1
            newTitle = "\(titleWithoutCopy) (\(counter))"
        }

        let newIdea = GiftIdea(
            personId: person.id,
            title: newTitle,
            note: idea.note,
            budgetMin: idea.budgetMin,
            budgetMax: idea.budgetMax,
            link: idea.link,
            status: .idea,
            tags: idea.tags
        )
        modelContext.insert(newIdea)
        triggerWidgetUpdate()
        HapticFeedback.success()
    }

    private func statusDisplayName(_ status: GiftStatus) -> String {
        switch status {
        case .idea: return String(localized: "Idee")
        case .planned: return String(localized: "Geplant")
        case .purchased: return String(localized: "Gekauft")
        case .given: return String(localized: "Verschenkt")
        }
    }

    private func triggerWidgetUpdate() {
        WidgetDataService.shared.updateWidgetData(from: modelContext)
    }

    // MARK: - Helper Views

    private func controlPill(icon: String, label: String, isActive: Bool) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
            Text(label)
                .font(.caption2.weight(isActive ? .semibold : .regular))
        }
        .foregroundStyle(isActive ? AppColor.primary : Color.secondary)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            isActive ? AppColor.primary.opacity(0.12) : Color.secondary.opacity(0.1),
            in: Capsule()
        )
    }
}
