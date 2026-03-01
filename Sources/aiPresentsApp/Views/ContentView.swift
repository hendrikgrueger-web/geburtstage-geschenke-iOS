import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [PersonRef]

    var body: some View {
        NavigationStack {
            TimelineView()
        }
    }
}
