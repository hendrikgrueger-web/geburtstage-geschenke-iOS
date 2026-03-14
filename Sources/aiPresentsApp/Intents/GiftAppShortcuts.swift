import AppIntents

struct GiftAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: UpcomingBirthdaysIntent(),
                phrases: [
                    "Wer hat bald Geburtstag in \(.applicationName)",
                    "Nächste Geburtstage in \(.applicationName)",
                    "Who has a birthday coming up in \(.applicationName)",
                    "Upcoming birthdays in \(.applicationName)"
                ],
                shortTitle: "Nächste Geburtstage",
                systemImageName: "gift"
            ),
            AppShortcut(
                intent: AddGiftIdeaIntent(),
                phrases: [
                    "Neue Geschenkidee für \(\.$person) in \(.applicationName)",
                    "Geschenkidee für \(\.$person) in \(.applicationName)",
                    "Add gift idea for \(\.$person) in \(.applicationName)",
                    "Gift idea for \(\.$person) in \(.applicationName)"
                ],
                shortTitle: "Geschenkidee eintragen",
                systemImageName: "plus.circle"
            ),
            AppShortcut(
                intent: OpenPersonIntent(),
                phrases: [
                    "Öffne \(\.$person) in \(.applicationName)",
                    "Zeig mir \(\.$person) in \(.applicationName)",
                    "Open \(\.$person) in \(.applicationName)",
                    "Show \(\.$person) in \(.applicationName)"
                ],
                shortTitle: "Kontakt öffnen",
                systemImageName: "person"
            )
        ]
    }
}
