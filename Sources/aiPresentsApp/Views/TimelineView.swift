import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [PersonRef]

    @State private var selectedTab: TimelineTab = .today
    @State private var showingContactsImport = false
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    @State private var filterHasIdeas: Bool? = nil
    @State private var filterRelation: String? = nil

    enum TimelineTab: String, CaseIterable {
        case today = "Heute"
        case week = "7 Tage"
        case month = "30 Tage"

        var days: Int {
            switch self {
            case .today: return 0
            case .week: return 7
            case .month: return 30
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("", selection: $selectedTab) {
                ForEach(TimelineTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            if filteredBirthdays.isEmpty {
                emptyStateView
            } else {
                birthdayList
            }
        }
        .navigationTitle("Geburtstage")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Suche...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .symbolVariant(filterHasIdeas != nil || filterRelation != nil ? .fill : .none)
                    }

                    NavigationLink(destination: ContactsImportView()) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet(
                filterHasIdeas: $filterHasIdeas,
                filterRelation: $filterRelation,
                availableRelations: availableRelations,
                onReset: {
                    filterHasIdeas = nil
                    filterRelation = nil
                }
            )
        }
    }

    private var filteredBirthdays: [PersonRef] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return people.compactMap { person -> (PersonRef, Date)? in
            // Apply search text filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                if !person.displayName.lowercased().contains(searchLower) &&
                   !person.relation.lowercased().contains(searchLower) {
                    return nil
                }
            }

            // Apply gift ideas filter
            if let hasIdeas = filterHasIdeas {
                let personHasIdeas = !person.giftIdeas?.isEmpty ?? false
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

            // Apply date filter
            guard let nextBirthday = nextBirthday(for: person, from: today) else {
                return nil
            }

            let daysUntil = calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0

            switch selectedTab {
            case .today:
                if daysUntil == 0 {
                    return (person, nextBirthday)
                }
            case .week:
                if daysUntil <= 7 && daysUntil >= 0 {
                    return (person, nextBirthday)
                }
            case .month:
                if daysUntil <= 30 && daysUntil >= 0 {
                    return (person, nextBirthday)
                }
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

    private func nextBirthday(for person: PersonRef, from today: Date) -> Date? {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: today)

        var components = calendar.dateComponents([.month, .day], from: person.birthday)
        components.year = currentYear

        guard var birthday = calendar.date(from: components) else {
            return nil
        }

        if birthday < today {
            components.year = currentYear + 1
            birthday = calendar.date(from: components) ?? birthday
        }

        return birthday
    }

    private var birthdayList: some View {
        List {
            ForEach(filteredBirthdays) { person in
                NavigationLink(destination: PersonDetailView(person: person)) {
                    BirthdayRow(person: person)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if let firstIdea = person.giftIdeas?.first,
                       firstIdea.status == .idea {
                        Button {
                            markAsPlanned(firstIdea)
                        } label: {
                            Label("Planen", systemImage: "checkmark.circle.fill")
                        }
                        .tint(.orange)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func markAsPlanned(_ idea: GiftIdea) {
        idea.status = .planned
        // SwiftData automatically tracks changes
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "gift.fill")
                .font(.system(size: 70))
                .foregroundColor(AppColor.textSecondary.opacity(0.5))

            Text("Keine Geburtstage")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColor.textPrimary)

            switch selectedTab {
            case .today:
                Text("Heute keine Geburtstage")
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)
            case .week:
                Text("Keine Geburtstage in den nächsten 7 Tagen")
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)
            case .month:
                Text("Keine Geburtstage in den nächsten 30 Tagen")
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)
            }

            Button("Kontakte importieren") {
                showingContactsImport = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
        .sheet(isPresented: $showingContactsImport) {
            ContactsImportView()
        }
    }
}
