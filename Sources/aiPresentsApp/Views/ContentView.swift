import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [PersonRef]

    @State private var selectedTab: MainTab = .timeline
    @State private var showingContactsImport = false

    enum MainTab: String, CaseIterable {
        case timeline = "Geburtstage"
        case settings = "Einstellungen"
    }

    private var birthdaysTodayCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return people.filter { person in
            guard let nextBirthday = nextBirthday(for: person, from: today) else {
                return false
            }

            let daysUntil = calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0
            return daysUntil == 0
        }.count
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TimelineView()
                .tabItem {
                    Label("Geburtstage", systemImage: selectedTab == .timeline ? "gift.fill" : "gift")
                        .badge(birthdaysTodayCount > 0 ? birthdaysTodayCount : 0)
                }
                .tag(MainTab.timeline)
                .accessibilityLabel("Geburtstage")

            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: selectedTab == .settings ? "gearshape.fill" : "gearshape")
                }
                .tag(MainTab.settings)
                .accessibilityLabel("Einstellungen")
        }
        .sheet(isPresented: $showingContactsImport) {
            ContactsImportView()
        }
        .onAppear {
            // Show contacts import on first launch if no contacts
            if people.isEmpty && !UserDefaults.standard.bool(forKey: "hasShownContactsImport") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingContactsImport = true
                }
                UserDefaults.standard.set(true, forKey: "hasShownContactsImport")
            }
        }
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
}
