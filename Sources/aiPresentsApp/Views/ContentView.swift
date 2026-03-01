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

    var body: some View {
        TabView(selection: $selectedTab) {
            TimelineView()
                .tabItem {
                    Label("Geburtstage", systemImage: selectedTab == .timeline ? "gift.fill" : "gift")
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
}
