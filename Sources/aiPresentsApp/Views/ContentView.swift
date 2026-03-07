import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [PersonRef]
    @Binding var deepLinkPersonID: UUID?

    @State private var showingContactsImport = false

    var body: some View {
        NavigationStack {
            TimelineView(deepLinkPersonID: $deepLinkPersonID)
        }
        .sheet(isPresented: $showingContactsImport) {
            ContactsImportView()
        }
        .onAppear {
            if people.isEmpty && !UserDefaults.standard.bool(forKey: "hasShownContactsImport") {
                UserDefaults.standard.set(true, forKey: "hasShownContactsImport")
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.5))
                    showingContactsImport = true
                }
            }
        }
    }
}
