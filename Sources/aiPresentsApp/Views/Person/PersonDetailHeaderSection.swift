import SwiftUI
import SwiftData

/// Oberer Bereich der PersonDetailView: Avatar, Name, Geburtstag, Countdown, Beziehungs-Picker, skipGift-Toggle.
struct PersonDetailHeaderSection: View {
    let person: PersonRef
    @Binding var showingEditRelation: Bool

    var body: some View {
        Section {
            avatarRow

            HStack {
                Text("Name")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(person.displayName)
                    .fontWeight(.medium)
            }
            .accessibilityElement(children: .combine)

            HStack {
                Text("Geburtstag")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(birthdayString)
                    .fontWeight(.medium)
            }
            .accessibilityElement(children: .combine)

            HStack {
                Text("Nächster Geburtstag")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(nextBirthdayInfo)
                    .fontWeight(.medium)
                    .foregroundStyle(daysUntilBirthday <= 7 ? AppColor.accent : Color.primary)
            }
            .accessibilityElement(children: .combine)

            HStack {
                Text("Beziehung")
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showingEditRelation = true
                    HapticFeedback.light()
                } label: {
                    HStack {
                        Text(person.relation)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Beziehung: \(person.relation)"))
                .accessibilityHint(String(localized: "Tippen, um die Beziehung zu ändern"))
            }

            Toggle("Kein Geschenk nötig", isOn: Binding(
                get: { person.skipGift },
                set: { newValue in
                    person.skipGift = newValue
                    HapticFeedback.selectionChanged()
                }
            ))
            .disabled(false)
        }
    }

    // MARK: - Private Computed Properties

    private var avatarRow: some View {
        HStack {
            PersonAvatar(person: person, size: 60)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var birthdayString: String {
        FormatterHelper.formatBirthday(person.birthday, birthYearKnown: person.birthYearKnown)
    }

    private var daysUntilBirthday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) ?? 0
    }

    private var nextBirthdayInfo: String {
        if daysUntilBirthday == 0 {
            return "🎉 " + String(localized: "Heute!")
        } else if daysUntilBirthday == 1 {
            return String(localized: "Morgen")
        } else if daysUntilBirthday == 365 {
            return String(localized: "Nächstes Jahr")
        } else if daysUntilBirthday < 7 {
            return String(localized: "In \(daysUntilBirthday) Tagen")
        } else {
            return String(localized: "\(daysUntilBirthday) Tage")
        }
    }
}
