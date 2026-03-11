import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [PersonRef]
    @Query private var giftIdeas: [GiftIdea]
    @Binding var deepLinkPersonID: UUID?

    @State private var showingSettings = false
    @State private var searchText = ""
    @State private var filterRelation: String? = nil
    @State private var showingAddGiftIdeaFor: PersonRef?
    @State private var quickAddPerson: PersonRef?
    @State private var showingAISuggestionsFor: PersonRef?
    @State private var selectedPerson: PersonRef?
    @State private var isRefreshing = false
    @State private var debouncedSearchText = ""
    @State private var searchDebouncer = Debouncer(delay: 0.3)
    @State private var showingAIChat = false

    var body: some View {
        List {
            // Stats-Leiste
            Section {
                statsRow
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Chronologische Liste aller Geburtstage
            if filteredBirthdays.isEmpty {
                Section {
                    emptyStateView
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(filteredBirthdays) { person in
                        birthdayRow(for: person)
                            .swipeActions(edge: .trailing) {
                                Button {
                                    toggleSkipGift(for: person)
                                } label: {
                                    Label(
                                        person.skipGift ? String(localized: "Geschenk nötig") : String(localized: "Kein Geschenk nötig"),
                                        systemImage: person.skipGift ? "gift.fill" : "minus.circle"
                                    )
                                }
                                .tint(person.skipGift ? .blue : .gray)
                            }
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Suche...")
        .onChange(of: searchText) { _, newValue in
            searchDebouncer.debounce { debouncedSearchText = newValue }
        }
        .refreshable {
            await refreshTimeline()
        }
        .navigationTitle("Geburtstage")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedPerson) { person in
            PersonDetailView(person: person)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel(String(localized: "Einstellungen"))
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    if !availableRelations.isEmpty {
                        Menu {
                            Button {
                                filterRelation = nil
                                HapticFeedback.selectionChanged()
                            } label: {
                                Label("Alle", systemImage: "list.bullet")
                            }

                            Divider()

                            ForEach(availableRelations, id: \.self) { relation in
                                Button {
                                    filterRelation = relation
                                    HapticFeedback.selectionChanged()
                                } label: {
                                    if filterRelation == relation {
                                        Label(relation, systemImage: "checkmark")
                                    } else {
                                        Text(relation)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .symbolVariant(filterRelation != nil ? .fill : .none)
                        }
                        .accessibilityLabel(String(localized: "Filter"))
                    }

                    NavigationLink(destination: ContactsImportView()) {
                        Image(systemName: "person.badge.plus")
                    }
                    .accessibilityLabel(String(localized: "Kontakte importieren"))
                }
            }
        }
        .sheet(item: $quickAddPerson) { person in
            AddGiftIdeaSheet(person: person)
        }
        .sheet(item: $showingAddGiftIdeaFor) { person in
            AddGiftIdeaSheet(person: person)
        }
        .sheet(item: $showingAISuggestionsFor) { person in
            AIGiftSuggestionsSheet(person: person)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .sheet(isPresented: $showingAIChat) {
            AIChatView()
        }
        .overlay(alignment: .bottomTrailing) {
            aiFABButton
        }
        .onChange(of: deepLinkPersonID) { _, newID in
            guard let id = newID else { return }
            if let person = people.first(where: { $0.id == id }) {
                selectedPerson = person
            }
            deepLinkPersonID = nil
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: "\(people.count)", label: String(localized: "Kontakte"), icon: "person.2.fill")
            Divider().frame(height: 32)
            statItem(value: "\(birthdaysThisWeek)", label: String(localized: "Diese Woche"), icon: "calendar")
            Divider().frame(height: 32)
            statItem(value: "\(giftIdeas.count)", label: String(localized: "Ideen"), icon: "lightbulb.fill")
        }
        .padding(.vertical, 10)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppColor.primary)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColor.textPrimary)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var birthdaysThisWeek: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return people.filter { person in
            guard let days = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) else { return false }
            return days >= 0 && days <= 7
        }.count
    }

    // MARK: - Alle Geburtstage chronologisch

    private var filteredBirthdays: [PersonRef] {
        let today = Calendar.current.startOfDay(for: Date())

        return people.compactMap { person -> (PersonRef, Date)? in
            // Suchfilter
            if !debouncedSearchText.isEmpty {
                let searchLower = debouncedSearchText.lowercased()
                if !person.displayName.lowercased().contains(searchLower) &&
                   !person.relation.lowercased().contains(searchLower) {
                    return nil
                }
            }

            // Beziehungsfilter
            if let relation = filterRelation, !relation.isEmpty {
                if person.relation != relation {
                    return nil
                }
            }

            guard let nextBirthday = BirthdayCalculator.nextBirthday(for: person.birthday, from: today) else {
                return nil
            }

            return (person, nextBirthday)
        }
        .sorted { $0.1 < $1.1 }
        .map { $0.0 }
    }

    private var availableRelations: [String] {
        Array(Set(people.map { $0.relation })).sorted()
    }

    // MARK: - Gift Ideas Lookup (O(1) pro Person via Dictionary-Grouping)

    private var ideasByPerson: [UUID: [GiftIdea]] {
        Dictionary(grouping: giftIdeas, by: \.personId)
    }

    // MARK: - Birthday Row

    private func birthdayRow(for person: PersonRef) -> some View {
        Button {
            selectedPerson = person
        } label: {
            BirthdayRow(person: person, giftIdeas: ideasByPerson[person.id] ?? [], onQuickAdd: {
                quickAddPerson = person
            })
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                showingAISuggestionsFor = person
            } label: {
                Label("KI-Vorschläge", systemImage: "sparkles")
            }

            Button {
                showingAddGiftIdeaFor = person
            } label: {
                Label("Idee hinzufügen", systemImage: "plus.circle.fill")
            }

            Button {
                toggleSkipGift(for: person)
            } label: {
                Label(
                    person.skipGift ? String(localized: "Geschenk nötig") : String(localized: "Kein Geschenk nötig"),
                    systemImage: person.skipGift ? "gift.fill" : "minus.circle"
                )
            }

            if let firstIdea = person.giftIdeas?.first(where: { $0.status == .idea }) {
                Button {
                    markAsPlanned(firstIdea)
                } label: {
                    Label("Erste Idee planen", systemImage: "checkmark.circle")
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleSkipGift(for person: PersonRef) {
        withAnimation {
            person.skipGift.toggle()
            HapticFeedback.medium()
        }
        WidgetDataService.shared.updateWidgetData(from: modelContext)
    }

    private func refreshTimeline() async {
        isRefreshing = true
        HapticFeedback.light()
        BirthdayCalculator.clearCache()
        try? await Task.sleep(nanoseconds: 500_000_000)
        WidgetDataService.shared.updateWidgetData(from: modelContext)
        HapticFeedback.success()
        isRefreshing = false
    }

    private func markAsPlanned(_ idea: GiftIdea) {
        let dateString = FormatterHelper.shortLogDateFormatter.string(from: Date())
        idea.statusLog.append("\(dateString) - \(String(localized: "Idee")) \u{2192} \(String(localized: "Geplant"))")
        idea.status = .planned
        HapticFeedback.success()
    }

    // MARK: - AI FAB Button

    private var aiFABButton: some View {
        Button {
            showingAIChat = true
            HapticFeedback.medium()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.purple)
            }
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel(String(localized: "KI-Assistent öffnen"))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundStyle(AppColor.textSecondary.opacity(0.6))

            VStack(spacing: 4) {
                Text(emptyStateTitle)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)

                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    private var emptyStateTitle: String {
        if !debouncedSearchText.isEmpty {
            return String(localized: "Keine Treffer")
        } else if filterRelation != nil {
            return String(localized: "Keine Ergebnisse")
        }
        return String(localized: "Keine Kontakte")
    }

    private var emptyStateMessage: String {
        if !debouncedSearchText.isEmpty {
            return String(localized: "Keine Kontakte für \"\(debouncedSearchText)\"")
        } else if let relation = filterRelation {
            return String(localized: "Keine Kontakte für \"\(relation)\"")
        }
        return String(localized: "Importiere Kontakte über das + oben rechts")
    }
}
