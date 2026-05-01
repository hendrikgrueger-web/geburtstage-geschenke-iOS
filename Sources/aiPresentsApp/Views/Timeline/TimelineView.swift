import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [PersonRef]
    @Query private var giftIdeas: [GiftIdea]
    @Binding var screenshotShowChat: Bool

    @Environment(SubscriptionManager.self) private var subscriptionManager: SubscriptionManager?
    @State private var showingContactsImport = false

    @State private var showingSettings = false
    @State private var filterRelation: String? = nil
    @State private var showingAddGiftIdeaFor: PersonRef?
    @State private var showingAISuggestionsFor: PersonRef?
    @Binding var selectedPerson: PersonRef?
    @State private var isRefreshing = false
    @State private var showingAIChat = false

    private static let scrollTopAnchorID = "timeline-top"

    var body: some View {
        ScrollViewReader { proxy in
            List {
                // Stats-Leiste — Anchor fuer Scroll-to-Top
                Section {
                    statsRow
                    if let reassurance = nextBirthdayReassurance {
                        reassurance
                    }
                }
                .id(Self.scrollTopAnchorID)
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
            .overlay(alignment: .bottomTrailing) {
                // Sprung-zu-heute-Button — nur sichtbar wenn die Liste lang genug ist
                if filteredBirthdays.count > 5 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            proxy.scrollTo(Self.scrollTopAnchorID, anchor: .top)
                        }
                        HapticFeedback.selectionChanged()
                    } label: {
                        Image(systemName: "arrow.up.to.line")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(AppColor.accent, in: Circle())
                            .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
                    }
                    .padding(.trailing, 18)
                    .padding(.bottom, 22)
                    .accessibilityLabel(String(localized: "Zu heute springen"))
                    .accessibilityHint(String(localized: "Springt zum Anfang der Geburtstagsliste"))
                }
            }
        }
        .refreshable {
            await refreshTimeline()
        }
        .navigationTitle("Geburtstage")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel(String(localized: "Einstellungen"))
                .keyboardShortcut(",", modifiers: .command)
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

                    Button {
                        showingContactsImport = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .accessibilityLabel(String(localized: "Kontakte importieren"))
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
        }
        .sheet(item: $showingAddGiftIdeaFor) { person in
            AddGiftIdeaSheet(person: person)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $showingAISuggestionsFor) { person in
            AIGiftSuggestionsSheet(person: person)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingAIChat) {
            AIChatView(onPersonSelected: { person in
                selectedPerson = person
            })
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showingContactsImport) {
            ContactsImportView()
        }
        .onChange(of: screenshotShowChat) { _, newValue in
            if newValue {
                showingAIChat = true
                screenshotShowChat = false
            }
        }
        #if DEBUG
        .onAppear {
            if UserDefaults.standard.bool(forKey: "screenshotShowSettings") {
                UserDefaults.standard.removeObject(forKey: "screenshotShowSettings")
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.5))
                    showingSettings = true
                }
            }
            if let idString = UserDefaults.standard.string(forKey: "screenshotShowAddGift"),
               let id = UUID(uuidString: idString) {
                UserDefaults.standard.removeObject(forKey: "screenshotShowAddGift")
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.5))
                    showingAddGiftIdeaFor = people.first(where: { $0.id == id })
                }
            }
        }
        #endif
        .safeAreaInset(edge: .bottom) {
            smartSearchBar
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(
                value: "\(birthdaysToday)",
                label: String(localized: "Heute"),
                icon: "gift.fill",
                isHighlighted: birthdaysToday > 0
            )
            Divider().frame(height: 32)
            statItem(
                value: "\(birthdaysThisWeek)",
                label: String(localized: "Diese Woche"),
                icon: "calendar",
                isHighlighted: birthdaysThisWeek > 0
            )
            Divider().frame(height: 32)
            statItem(
                value: "\(birthdaysThisMonth)",
                label: String(localized: "Diesen Monat"),
                icon: "calendar.badge.clock",
                isHighlighted: birthdaysThisMonth > 0
            )
        }
        .padding(.vertical, 10)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(statsAccessibilityLabel)
    }

    private func statItem(value: String, label: String, icon: String, isHighlighted: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(isHighlighted ? AppColor.accent : AppColor.primary)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(isHighlighted ? AppColor.accent : AppColor.textPrimary)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var birthdaysToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return people.filter { person in
            guard let days = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) else { return false }
            return days == 0
        }.count
    }

    private var birthdaysThisWeek: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return people.filter { person in
            guard let days = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) else { return false }
            return days >= 0 && days <= 7
        }.count
    }

    private var birthdaysThisMonth: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return people.filter { person in
            guard let days = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) else { return false }
            return days >= 0 && days <= 30
        }.count
    }

    private var statsAccessibilityLabel: String {
        String(
            localized: "\(birthdaysToday) Geburtstage heute, \(birthdaysThisWeek) diese Woche, \(birthdaysThisMonth) diesen Monat"
        )
    }

    /// Reassurance-Zeile unter der Stats-Row: zeigt nur, wenn nichts in den
    /// naechsten 30 Tagen ansteht aber Kontakte existieren — dann nennen wir
    /// den naechsten Geburtstag konkret. Vermeidet "stille" Hauptansicht.
    @ViewBuilder
    private var nextBirthdayReassurance: (some View)? {
        if birthdaysThisMonth == 0,
           !people.isEmpty,
           let nextPerson = soonestBirthdayPerson,
           let days = BirthdayCalculator.daysUntilBirthday(
               for: nextPerson.birthday,
               from: Calendar.current.startOfDay(for: Date())
           ) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.circle")
                    .font(.body)
                    .foregroundStyle(AppColor.textSecondary)
                Text(
                    days == 1
                    ? String(localized: "Aktuell ist Ruhe — der naechste Geburtstag ist morgen: \(nextPerson.displayName).")
                    : String(localized: "Aktuell ist Ruhe — der naechste Geburtstag ist in \(days) Tagen: \(nextPerson.displayName).")
                )
                .font(.footnote)
                .foregroundStyle(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private var soonestBirthdayPerson: PersonRef? {
        let today = Calendar.current.startOfDay(for: Date())
        return people
            .compactMap { person -> (PersonRef, Int)? in
                guard let days = BirthdayCalculator.daysUntilBirthday(
                    for: person.birthday, from: today
                ) else { return nil }
                return (person, days)
            }
            .min(by: { $0.1 < $1.1 })?
            .0
    }

    // MARK: - Alle Geburtstage chronologisch

    private var filteredBirthdays: [PersonRef] {
        let today = Calendar.current.startOfDay(for: Date())

        return people.compactMap { person -> (PersonRef, Date)? in
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
        NavigationLink(value: person) {
            BirthdayRow(person: person, giftIdeas: ideasByPerson[person.id] ?? [], onQuickAdd: {
                showingAddGiftIdeaFor = person
            })
        }
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

            if let firstIdea = ideasByPerson[person.id]?.first(where: { $0.status == .idea }) {
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
        WidgetDataService.shared.updateWidgetData(from: modelContext)
        HapticFeedback.success()
    }

    // MARK: - Smart Search Bar

    private var smartSearchBar: some View {
        Button {
            showingAIChat = true
            HapticFeedback.light()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("Suche oder frag die KI…")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "mic")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .accessibilityLabel(String(localized: "Suche oder KI-Assistent öffnen"))
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
        if filterRelation != nil {
            return String(localized: "Keine Ergebnisse")
        }
        return String(localized: "Keine Kontakte")
    }

    private var emptyStateMessage: String {
        if let relation = filterRelation {
            return String(localized: "Keine Kontakte für \"\(relation)\"")
        }
        return String(localized: "Importiere Kontakte über das + oben rechts")
    }
}
