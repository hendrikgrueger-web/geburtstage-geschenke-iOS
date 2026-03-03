# CLAUDE.md — ai-presents-app-ios

## Projekt-Übersicht

iOS-App für Geburtstags- und Geschenkeverwaltung. Generiert von Open Claw (n8n/Telegram Bot), manuell gefixt und weiterentwickelt.

## Tech Stack

- **Swift 6.0**, SwiftUI, SwiftData (iOS 26+)
- **Architektur:** MVVM mit Services
- **Daten:** SwiftData + iCloud Sync (CloudKit)
- **KI:** Apple Foundation Models (Apple Intelligence, vollständig lokal, kein Netzwerk)
- **Target:** iPhone 16e Simulator / iOS 26+

## Build

```bash
xcodebuild -scheme aiPresentsApp -destination 'platform=iOS Simulator,name=iPhone 16e' build
```

## Projektstruktur

```
Sources/aiPresentsApp/
├── Models/          # SwiftData Models: PersonRef, GiftIdea, GiftHistory, ReminderRule, SuggestionFeedback
├── Services/        # CloudKitContainer, ContactsService, ReminderManager, AIService, SampleDataService
├── Utilities/       # AppLogger, AppConfig, FormState, FormValidator, Accessibility, Debouncer, BirthdayCalculator
├── Views/           # SwiftUI Views (Sheets, Components, Settings, Timeline)
├── ViewModels/      # AppViewModel, SuggestionQualityViewModel
├── Resources/       # AppColor
├── Widgets/         # BirthdayWidgetView
└── aiPresentsApp.swift  # App Entry Point
```

## KI-Architektur (AIService)

**Vollständig lokal** — kein OpenRouter, kein API-Key, kein Netzwerk.

| Pfad | Voraussetzung | Daten |
|---|---|---|
| Apple Intelligence | iOS 26+, A17 Pro / A18 | Alles lokal, nichts verlässt das Gerät |
| Demo-Modus | immer verfügbar | Vollständig offline, keine KI |

**Verfügbarkeit prüfen:** `AIService.isAvailable` → `Bool`

```swift
// In Views: Apple Intelligence Status anzeigen
private var isUsingAppleIntelligence: Bool { AIService.isAvailable }
```

**Prompts:** Da alles lokal, können Name und exaktes Alter im Prompt verwendet werden.

**`#if canImport(FoundationModels)`:** Sicherheits-Guard falls Xcode < 26. Mit Xcode 26 wird das Framework direkt kompiliert.

## Wichtige Patterns & Konventionen

### SwiftData Models
- `PersonRef` erwartet `contactIdentifier:` als required Parameter
- `GiftIdea` Init-Reihenfolge: `status` VOR `tags`
- `GiftStatus` ist `CaseIterable` + `Codable`

### ModelConfiguration
- Positional String statt `identifier:` Label: `ModelConfiguration("name", ...)`
- Für CloudKit-disabled: `cloudKitDatabase: .none` (nicht `nil`)

### SwiftUI Views
- Computed properties: **`some View`** (nie bare `View`)
- Funktions-Returns: **`-> some View`** (nie `-> View`)
- `Section("title") { } footer: { }` ist UNGÜLTIG — verwende: `Section { } header: { Text("title") } footer: { }`
- `Section("title") { }` ohne footer/header ist OK
- `.symbolEffect`: Verschiedene Effect-Typen können nicht in Ternary gemischt werden → `.symbolEffect(.bounce, isActive: condition)`
- Alert `message:` Closures müssen IMMER einen View liefern — Logic in computed property auslagern

### Swift 6 Concurrency
- Tasks, die SwiftData-Models senden: `let p = person` lokale Kopie vor Task, dann `Task { @MainActor in ... }`
- `ContactsService` ist `@MainActor`
- `BirthdayCalculator.cache` braucht `nonisolated(unsafe)` (mutable static state)
- `ReminderManager` ist `@MainActor` — lock Properties brauchen `nonisolated(unsafe)`

### AppLogger Kategorien
```swift
AppLogger.ui.debug("...")
AppLogger.data.info("...")
AppLogger.forms.error("...", error: error)
AppLogger.reminder.warning("...")
AppLogger.notifications.info("...")
```

### Löschen aller Daten (kein `deleteContainer()`)
```swift
try context.delete(model: SuggestionFeedback.self)
try context.delete(model: ReminderRule.self)
try context.delete(model: GiftHistory.self)
try context.delete(model: GiftIdea.self)
try context.delete(model: PersonRef.self)
```

### FormState Naming
- `FormState` in `FormState.swift` = ObservableObject-Version (für FormField, FormSubmitButton)
- `AppFormState` in `FormValidator.swift` = @Observable-Version (für Sheet-Views)

## Bekannte Einschränkungen

- Foundation Models läuft im Simulator nur, wenn Apple Intelligence im Simulator aktiviert (Xcode 26 Feature)
- App wurde initial von KI generiert — Code-Qualität variiert

## GitHub

- Repo: `harryhirsch1878/ai-presents-app-ios`
- Branch: `main`
