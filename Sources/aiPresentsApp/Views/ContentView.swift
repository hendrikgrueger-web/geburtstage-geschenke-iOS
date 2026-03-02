import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [PersonRef]

    @State private var selectedTab: MainTab = .timeline
    @State private var showingContactsImport = false
    @State private var birthdaysTodayCount: Int = 0

    enum MainTab: String, CaseIterable {
        case timeline = "Geburtstage"
        case settings = "Einstellungen"
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
            updateBirthdaysTodayCount()
            // Show contacts import on first launch if no contacts
            if people.isEmpty && !UserDefaults.standard.bool(forKey: "hasShownContactsImport") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingContactsImport = true
                }
                UserDefaults.standard.set(true, forKey: "hasShownContactsImport")
            }
        }
        .onChange(of: people) { oldValue, newValue in
            // Recalculate birthdays today count when people data changes
            updateBirthdaysTodayCount()
        }
    }

    private func updateBirthdaysTodayCount() {
        let today = Calendar.current.startOfDay(for: Date())
        birthdaysTodayCount = people.filter { person in
            BirthdayCalculator.isBirthdayToday(for: person.birthday, from: today)
        }.count
    }
}
