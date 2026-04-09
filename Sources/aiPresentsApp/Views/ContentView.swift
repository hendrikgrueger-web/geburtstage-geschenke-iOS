import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var people: [PersonRef]
    @Binding var deepLinkPersonID: UUID?
    @Binding var screenshotShowChat: Bool

    @State private var showingContactsImport = false
    @State private var selectedPerson: PersonRef?
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var compactPresentedPerson: PersonRef?

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            TimelineView(
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
                    .id(person.id)
            } else {
                emptyDetailView
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingContactsImport) {
            ContactsImportView()
        }
        .fullScreenCover(item: $compactPresentedPerson, onDismiss: {
            guard horizontalSizeClass == .compact else { return }
            selectedPerson = nil
        }) { person in
            NavigationStack {
                PersonDetailView(person: person)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                compactPresentedPerson = nil
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
            }
        }
        .onChange(of: deepLinkPersonID) { _, newID in
            guard let id = newID,
                  let person = people.first(where: { $0.id == id }) else { return }

            if horizontalSizeClass == .compact {
                compactPresentedPerson = person
            } else {
                selectedPerson = person
            }
            deepLinkPersonID = nil
        }
        .onChange(of: selectedPerson?.id) { _, _ in
            guard horizontalSizeClass == .compact,
                  let person = selectedPerson else { return }
            compactPresentedPerson = person
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
