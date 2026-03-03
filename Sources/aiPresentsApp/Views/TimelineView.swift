import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [PersonRef]

    @State private var selectedTab: TimelineTab = .today
    @State private var showingContactsImport = false
    @State private var searchText = ""
    @State private var filterHasIdeas: Bool? = nil
    @State private var filterRelation: String? = nil
    @State private var showingAddGiftIdeaFor: PersonRef?
    @State private var quickAddPerson: PersonRef?
    @State private var showingAISuggestionsFor: PersonRef?
    @State private var selectedPerson: PersonRef?
    @State private var listAnimation = false
    @State private var isRefreshing = false
    @State private var debouncedSearchText = ""
    @State private var searchDebouncer = Debouncer(delay: 0.3)

    enum TimelineTab: String, CaseIterable {
        case today = "Heute"
        case week = "7 Tage"
        case month = "30 Tage"

        var days: Int {
            switch self {
            case .today: return AppConfig.Timeline.todayDays
            case .week: return AppConfig.Timeline.weekDays
            case .month: return AppConfig.Timeline.monthDays
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Suchfeld
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Suche...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, newValue in
                        searchDebouncer.debounce { debouncedSearchText = newValue }
                    }
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.top, 8)

            // Tab Picker
            Picker("", selection: $selectedTab) {
                ForEach(TimelineTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                        .accessibilityLabel(tab.rawValue + " Geburtstage")
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .accessibilityLabel("Zeitfilter")

            // Birthday Widget
            BirthdayWidgetView()
                .padding(.horizontal)
                .padding(.bottom, 16)

            // Quick Stats
            QuickStatsView()
                .padding(.bottom, 8)

            if filteredBirthdays.isEmpty {
                emptyStateView
            } else {
                birthdayList
            }
        }
        .navigationTitle("Geburtstage")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Menu {
                        Button {
                            filterHasIdeas = nil
                            filterRelation = nil
                            HapticFeedback.selectionChanged()
                        } label: {
                            Label("Alle", systemImage: "list.bullet")
                        }
                        .accessibilityLabel("Alle Kontakte anzeigen")

                        Divider()

                        Button {
                            filterHasIdeas = false
                            HapticFeedback.selectionChanged()
                        } label: {
                            Label("Ohne Ideen", systemImage: "lightbulb.slash")
                        }
                        .accessibilityLabel("Kontakte ohne Geschenkideen anzeigen")

                        Button {
                            filterHasIdeas = true
                            HapticFeedback.selectionChanged()
                        } label: {
                            Label("Mit Ideen", systemImage: "lightbulb.fill")
                        }
                        .accessibilityLabel("Kontakte mit Geschenkideen anzeigen")

                        if !availableRelations.isEmpty {
                            Divider()

                            Menu {
                                Button {
                                    filterRelation = nil
                                    HapticFeedback.selectionChanged()
                                } label: {
                                    Label("Alle Beziehungen", systemImage: "list.bullet")
                                }
                                .accessibilityLabel("Alle Beziehungen")

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
                                    .accessibilityLabel("Beziehung: \(relation)")
                                }
                            } label: {
                                Label("Beziehung", systemImage: "person.2")
                            }
                            .accessibilityLabel("Nach Beziehung filtern")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .symbolVariant(filterHasIdeas != nil || filterRelation != nil ? .fill : .none)
                    }
                    .accessibilityLabel("Filter")
                    .accessibilityHint("Filteroptionen für Kontakte")

                    NavigationLink(destination: ContactsImportView()) {
                        Image(systemName: "person.badge.plus")
                    }
                    .accessibilityLabel("Kontakte importieren")
                }
            }
        }
        .sheet(item: $quickAddPerson) { person in
            AddGiftIdeaSheet(person: person)
        }
    }

    private var filteredBirthdays: [PersonRef] {
        let today = Calendar.current.startOfDay(for: Date())

        return people.compactMap { person -> (PersonRef, Date)? in
            // Apply search text filter (with debouncing)
            if !debouncedSearchText.isEmpty {
                let searchLower = debouncedSearchText.lowercased()
                if !person.displayName.lowercased().contains(searchLower) &&
                   !person.relation.lowercased().contains(searchLower) {
                    return nil
                }
            }

            // Apply gift ideas filter
            if let hasIdeas = filterHasIdeas {
                let personHasIdeas = !(person.giftIdeas?.isEmpty ?? true)
                if hasIdeas != personHasIdeas {
                    return nil
                }
            }

            // Apply relation filter
            if let relation = filterRelation, !relation.isEmpty {
                if person.relation != relation {
                    return nil
                }
            }

            guard let nextBirthday = BirthdayCalculator.nextBirthday(for: person.birthday, from: today) else {
                return nil
            }

            // Bei aktiver Suche: Tab-Filter ignorieren, alle Treffer zeigen
            if !debouncedSearchText.isEmpty {
                return (person, nextBirthday)
            }

            // Apply date filter using BirthdayCalculator
            let daysUntil = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today)

            switch selectedTab {
            case .today:
                if daysUntil == 0 { return (person, nextBirthday) }
            case .week:
                if let days = daysUntil, days >= 0, days <= 7 { return (person, nextBirthday) }
            case .month:
                if let days = daysUntil, days >= 0, days <= 30 { return (person, nextBirthday) }
            }
            return nil
        }
        .sorted { $0.1 < $1.1 }
        .map { $0.0 }
    }

    private var availableRelations: [String] {
        let allRelations = people.map { $0.relation }
        return Array(Set(allRelations)).sorted()
    }

    private func birthdayRow(for person: PersonRef) -> some View {
        BirthdayRow(person: person, onTap: {
            selectedPerson = person
        }, onQuickAdd: {
            quickAddPerson = person
        })
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                showingAISuggestionsFor = person
                HapticFeedback.light()
            } label: {
                Label("KI", systemImage: "sparkles")
            }
            .tint(.orange)

            if let firstIdea = person.giftIdeas?.first,
               firstIdea.status == .idea {
                Button {
                    markAsPlanned(firstIdea)
                } label: {
                    Label("Planen", systemImage: "checkmark.circle.fill")
                }
                .tint(.blue)
            }

            Button {
                showingAddGiftIdeaFor = person
                HapticFeedback.light()
            } label: {
                Label("Idee", systemImage: "plus.circle.fill")
            }
            .tint(.green)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            let days = BirthdayDateHelper.daysUntilBirthday(from: person.birthday) ?? Int.max
            if days <= 7 {
                Button {
                    markAsPlannedFirstIdea(person)
                } label: {
                    Label("Erste Idee planen", systemImage: "checkmark.circle")
                }
                .tint(.blue)
            }
        }
    }

    private var birthdayList: some View {
        List {
            ForEach(filteredBirthdays) { person in
                birthdayRow(for: person)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await refreshTimeline()
        }
        .navigationDestination(item: $selectedPerson) { person in
            PersonDetailView(person: person)
        }
        .sheet(item: $showingAddGiftIdeaFor) { person in
            AddGiftIdeaSheet(person: person)
        }
        .sheet(item: $showingAISuggestionsFor) { person in
            AIGiftSuggestionsSheet(person: person)
        }
    }

    private func refreshTimeline() async {
        isRefreshing = true
        HapticFeedback.light()

        // Clear birthday calculator cache to force recalculation
        BirthdayCalculator.clearCache()

        // Simulate a brief refresh delay for better UX
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        HapticFeedback.success()
        isRefreshing = false
    }

    private func markAsPlanned(_ idea: GiftIdea) {
        idea.status = .planned
        HapticFeedback.success()
        // SwiftData automatically tracks changes
    }

    private func markAsPlannedFirstIdea(_ person: PersonRef) {
        if let firstIdea = person.giftIdeas?.first(where: { $0.status == .idea }) {
            firstIdea.status = .planned
            HapticFeedback.success()
        } else {
            HapticFeedback.error()
        }
    }

    private func daysUntilBirthday(for person: PersonRef) -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) ?? 0
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Icon based on filter/search state
            if !searchText.isEmpty || filterHasIdeas != nil || filterRelation != nil {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(AppColor.textSecondary.opacity(0.4))

            } else {
                Image(systemName: "giftcard")
                    .font(.system(size: 60))
                    .foregroundColor(AppColor.textSecondary.opacity(0.4))
            }

            VStack(spacing: 8) {
                Text("Keine Ergebnisse")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColor.textPrimary)

                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if searchText.isEmpty && filterHasIdeas == nil && filterRelation == nil {
                Button("Kontakte importieren") {
                    showingContactsImport = true
                    HapticFeedback.medium()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Kontakte aus dem Adressbuch importieren")
            }
        }
        .padding()
        .padding(.bottom, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(AppColor.background)
        .sheet(isPresented: $showingContactsImport) {
            ContactsImportView()
        }
    }

    private var emptyStateMessage: String {
        if !debouncedSearchText.isEmpty {
            return "Keine Kontakte finden, die \"\(debouncedSearchText)\" enthalten"
        } else if filterHasIdeas == true {
            return "Keine Kontakte mit Geschenkideen gefunden"
        } else if filterHasIdeas == false {
            return "Keine Kontakte ohne Geschenkideen gefunden"
        } else if let relation = filterRelation {
            return "Keine Kontakte mit Beziehung \"\(relation)\" gefunden"
        }

        switch selectedTab {
        case .today:
            return "Heute keine Geburtstage"
        case .week:
            return "Keine Geburtstage in den nächsten 7 Tagen"
        case .month:
            return "Keine Geburtstage in den nächsten 30 Tagen"
        }
    }
}
