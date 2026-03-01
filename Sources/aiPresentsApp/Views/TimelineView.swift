import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [PersonRef]

    @State private var selectedTab: TimelineTab = .today

    enum TimelineTab: String, CaseIterable {
        case today = "Heute"
        case week = "7 Tage"
        case month = "30 Tage"
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
        let todayComponents = calendar.dateComponents([.month, .day], from: today)

        return people.filter { person in
            let birthdayComponents = calendar.dateComponents([.month, .day], from: person.birthday)

            guard birthdayComponents.month == todayComponents.month,
                  birthdayComponents.day == todayComponents.day else {
                return false
            }

            switch selectedTab {
            case .today:
                return true
            case .week:
                return true // TODO: Filter by actual days
            case .month:
                return true // TODO: Filter by actual days
            }
        }
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
        VStack(spacing: 20) {
            Image(systemName: "gift.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Keine Geburtstage")
                .font(.headline)
                .foregroundColor(.gray)

            Text("Importiere Kontakte mit Geburtstagen")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Kontakte importieren") {
                // TODO: Navigate to ContactsImportView
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
