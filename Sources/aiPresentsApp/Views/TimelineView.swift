import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [PersonRef]

    @State private var selectedTab: TimelineTab = .today
    @State private var showingContactsImport = false

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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ContactsImportView()) {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
    }

    private var filteredBirthdays: [PersonRef] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return people.compactMap { person -> (PersonRef, Date)? in
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
            }
        }
        .listStyle(.insetGrouped)
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
