import SwiftUI
import SwiftData

/// Hobbies & Interessen Section mit HobbiesChipView.
struct PersonDetailHobbiesSection: View {
    let person: PersonRef

    var body: some View {
        Section {
            HobbiesChipView(
                hobbies: Binding(
                    get: { person.hobbies },
                    set: { person.hobbies = $0 }
                ),
                isEditable: true
            )
        } header: {
            Text("Hobbies & Interessen")
        } footer: {
            Text("Wird für bessere KI-Vorschläge genutzt")
        }
    }
}
