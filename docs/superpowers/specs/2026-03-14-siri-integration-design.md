# Design Spec: Siri-Integration via App Intents

> Erstellt: 2026-03-14 | iOS 26+

---

## Ziel

Nutzer können per Siri-Sprachbefehl Geburtstage abfragen, Geschenkideen eintragen und Kontakte öffnen — ohne die App manuell zu öffnen.

## Architektur

Reines `AppIntents` Framework (iOS 16+). Kein SiriKit, keine .intentdefinition, kein spezielles Capability nötig. Nur `import AppIntents`.

---

## Dateien

| Datei | Pfad | Zweck |
|-------|------|-------|
| PersonEntity | `Sources/aiPresentsApp/Intents/PersonEntity.swift` | AppEntity — macht PersonRef für Siri sichtbar |
| UpcomingBirthdaysIntent | `Sources/aiPresentsApp/Intents/UpcomingBirthdaysIntent.swift` | "Wer hat bald Geburtstag?" |
| AddGiftIdeaIntent | `Sources/aiPresentsApp/Intents/AddGiftIdeaIntent.swift` | "Trag X als Idee für Y ein" |
| OpenPersonIntent | `Sources/aiPresentsApp/Intents/OpenPersonIntent.swift` | "Öffne Dennis" → Deep-Link |
| AppShortcutsProvider | `Sources/aiPresentsApp/Intents/GiftAppShortcuts.swift` | Registriert Siri-Phrases |

---

## 1. PersonEntity (AppEntity)

```swift
import AppIntents
import SwiftData

struct PersonEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Kontakt")
    static var defaultQuery = PersonEntityQuery()

    var id: UUID
    var displayName: String
    var relation: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)", subtitle: "\(relation)")
    }
}

struct PersonEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [PersonEntity] {
        // SwiftData fetch by IDs
    }

    func suggestedEntities() async throws -> [PersonEntity] {
        // Alle Personen als Vorschläge
    }

    func entities(matching string: String) async throws -> [PersonEntity] {
        // Name-Suche (case-insensitive contains)
    }
}
```

---

## 2. UpcomingBirthdaysIntent

- **Phrase:** "Wer hat bald Geburtstag?" / "Who has a birthday coming up?"
- **Typ:** Query (kein App-Öffnen nötig)
- **Ergebnis:** IntentDialog mit nächsten 5 Geburtstagen (Name, Tage, Relation)
- **SwiftData:** Liest PersonRef, sortiert nach daysUntilBirthday

---

## 3. AddGiftIdeaIntent

- **Phrase:** "Trag $title als Geschenkidee für $person ein"
- **Parameter:** `person: PersonEntity`, `title: String`
- **Typ:** Action (erstellt Daten)
- **Ergebnis:** Erstellt GiftIdea in SwiftData, bestätigt mit Dialog
- **Disambiguierung:** Bei mehreren Personen mit gleichem Namen fragt Siri automatisch nach (EntityQuery)

---

## 4. OpenPersonIntent

- **Phrase:** "Öffne $person in AI Präsente"
- **Typ:** OpenIntent (öffnet App)
- **Ergebnis:** Setzt deepLinkPersonID → App navigiert zu PersonDetailView

---

## 5. GiftAppShortcuts (AppShortcutsProvider)

```swift
struct GiftAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: UpcomingBirthdaysIntent(),
            phrases: [
                "Wer hat bald Geburtstag in \(.applicationName)",
                "Who has a birthday coming up in \(.applicationName)"
            ],
            shortTitle: "Nächste Geburtstage",
            systemImageName: "gift"
        )
        AppShortcut(
            intent: AddGiftIdeaIntent(),
            phrases: [
                "Trag \(\.$title) als Geschenkidee für \(\.$person) ein in \(.applicationName)",
                "Add \(\.$title) as gift idea for \(\.$person) in \(.applicationName)"
            ],
            shortTitle: "Geschenkidee eintragen",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: OpenPersonIntent(),
            phrases: [
                "Öffne \(\.$person) in \(.applicationName)",
                "Open \(\.$person) in \(.applicationName)"
            ],
            shortTitle: "Kontakt öffnen",
            systemImageName: "person"
        )
    }
}
```

---

## SwiftData-Zugriff in Intents

AppIntents dürfen keinen eigenen Store-Vertrag erfinden. App und Intents müssen denselben SwiftData-Containervertrag verwenden:

- gemeinsame Factory: `AppModelContainerFactory`
- gleiche Store-Namen wie die App (`ai-presents-app`, `ai-presents-app-local`, `ai-presents-app-recovery`)
- gleiche iCloud-vs-lokal Entscheidung über `iCloudSyncEnabled`
- gleicher Fallback-Pfad (primary -> local fallback -> in-memory recovery)

Die Intent-Helferfunktion `makeIntentsModelContainer()` delegiert daher direkt an `AppModelContainerFactory.create()`.

---

## Deep-Linking (OpenPersonIntent)

Bestehender Mechanismus: `ContentView` hat `@State var deepLinkPersonID: UUID?` + URL-Scheme `aipresents://person/{UUID}`. OpenPersonIntent öffnet diese URL.

---

## Lokalisierung

Siri-Phrases müssen in `AppShortcuts.strings` lokalisiert werden (DE + EN mindestens). Die Phrases im Code sind die Default-Sprache.

---

## Was sich NICHT ändert

- Bestehende Views, Services, Models bleiben unverändert
- Kein neues Framework/Dependency
- Keine Änderungen an project.yml oder Entitlements nötig (AppIntents braucht das nicht)
