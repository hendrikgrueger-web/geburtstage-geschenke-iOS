import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [PersonRef]
    @Query private var giftIdeas: [GiftIdea]
    @Binding var screenshotShowChat: Bool

    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showingPaywall = false
    @State private var showingContactsImport = false

    @State private var showingSettings = false
    @State private var filterRelation: String? = nil
    @State private var showingAddGiftIdeaFor: PersonRef?
    @State private var showingAISuggestionsFor: PersonRef?
    @Binding var selectedPerson: PersonRef?
    @State private var isRefreshing = false
    @State private var showingAIChat = false

    var body: some View {
        List {
            // Stats-Leiste
            Section {
                statsRow
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // ReadOnlyBanner vor den BirthdayRows
            Section {
                ReadOnlyBanner()
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
                                    if subscriptionManager.hasFullAccess {
                                        toggleSkipGift(for: person)
                                    } else {
                                        showingPaywall = true
                                    }
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
                        if subscriptionManager.hasFullAccess {
                            showingContactsImport = true
                        } else {
                            showingPaywall = true
                        }
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
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
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
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
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
                if subscriptionManager.hasFullAccess {
                    showingAddGiftIdeaFor = person
                } else {
                    showingPaywall = true
                }
            })
        }
        .contextMenu {
            Button {
                showingAISuggestionsFor = person
            } label: {
                Label("KI-Vorschläge", systemImage: "sparkles")
            }

            Button {
                if subscriptionManager.hasFullAccess {
                    showingAddGiftIdeaFor = person
                } else {
                    showingPaywall = true
                }
            } label: {
                Label("Idee hinzufügen", systemImage: "plus.circle.fill")
            }

            Button {
                if subscriptionManager.hasFullAccess {
                    toggleSkipGift(for: person)
                } else {
                    showingPaywall = true
                }
            } label: {
                Label(
                    person.skipGift ? String(localized: "Geschenk nötig") : String(localized: "Kein Geschenk nötig"),
                    systemImage: person.skipGift ? "gift.fill" : "minus.circle"
                )
            }

            if let firstIdea = ideasByPerson[person.id]?.first(where: { $0.status == .idea }) {
                Button {
                    if subscriptionManager.hasFullAccess {
                        markAsPlanned(firstIdea)
                    } else {
                        showingPaywall = true
                    }
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
            if subscriptionManager.hasFullAccess {
                showingAIChat = true
            } else {
                showingPaywall = true
            }
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
