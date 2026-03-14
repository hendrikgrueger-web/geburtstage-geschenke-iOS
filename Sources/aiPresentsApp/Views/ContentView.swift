import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var people: [PersonRef]
    @Binding var deepLinkPersonID: UUID?
    @Binding var screenshotShowChat: Bool

    @State private var showingContactsImport = false
    @State private var selectedPerson: PersonRef?
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    #if DEBUG
    @State private var screenshotPerson: PersonRef?
    #endif

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            TimelineView(
                deepLinkPersonID: $deepLinkPersonID,
                screenshotShowChat: $screenshotShowChat,
                selectedPerson: $selectedPerson
            )
            .navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 440)
            .navigationDestination(for: PersonRef.self) { person in
                PersonDetailView(person: person)
            }
        } detail: {
            if let person = selectedPerson {
                PersonDetailView(person: person)
            } else {
                emptyDetailView
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingContactsImport) {
            ContactsImportView()
        }
        #if DEBUG
        .fullScreenCover(item: $screenshotPerson) { person in
            NavigationStack {
                PersonDetailView(person: person)
            }
        }
        .onChange(of: deepLinkPersonID) { _, newID in
            guard let id = newID, horizontalSizeClass == .compact else { return }
            if let person = people.first(where: { $0.id == id }) {
                screenshotPerson = person
                deepLinkPersonID = nil
            }
        }
        #endif
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

    // MARK: - Empty Detail State

    private var emptyDetailView: some View {
        VStack(spacing: 20) {
            Image(systemName: "gift.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColor.primary.opacity(0.3))

            VStack(spacing: 8) {
                Text("Keine Person ausgewählt")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Wähle eine Person aus der Liste, um Details und Geschenkideen zu sehen.")
                    .font(.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
