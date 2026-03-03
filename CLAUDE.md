# CLAUDE.md — ai-presents-app-ios

## Projekt-Übersicht

iOS-App für Geburtstags- und Geschenkeverwaltung. Generiert von Open Claw (n8n/Telegram Bot), manuell gefixt und weiterentwickelt.

## Tech Stack

- **Swift 5.9+**, SwiftUI, SwiftData (iOS 17+)
- **Architektur:** MVVM mit Services
- **Daten:** SwiftData + iCloud Sync (CloudKit)
- **KI:** OpenRouter API für Geschenkvorschläge (optional)
- **Target:** iPhone 16e Simulator / iOS 17+

## Build

```bash
xcodebuild -scheme ai-presents-app-ios -destination 'platform=iOS Simulator,name=iPhone 16e' build
```

## Projektstruktur

```
Sources/aiPresentsApp/
├── Models/          # SwiftData Models: PersonRef, GiftIdea, GiftHistory, ReminderRule, SuggestionFeedback
├── Services/        # CloudKitContainer, ContactsService, ReminderManager, AIService, SampleDataService
├── Utilities/       # AppLogger, AppConfig, FormState, FormValidator, Accessibility, Debouncer
├── Views/           # SwiftUI Views (Sheets, Components, Settings, Timeline)
├── ViewModels/      # AppViewModel, SuggestionQualityViewModel
├── Resources/       # AppColor
├── Widgets/         # BirthdayWidgetView
└── aiPresentsApp.swift  # App Entry Point
```

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
- `.symbolEffect`: Verschiedene Effect-Typen (`.pulse`, `.bounce`) können nicht in Ternary gemischt werden → stattdessen: `.symbolEffect(.bounce, isActive: condition)`
- Alert `message:` Closures müssen IMMER einen View liefern — Logic in computed property auslagern

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
try context.delete(model: ReminderRule.self)
try context.delete(model: GiftHistory.self)
try context.delete(model: GiftIdea.self)
try context.delete(model: PersonRef.self)
try context.delete(model: SuggestionFeedback.self)
```

### Actor-Isolation
- `ReminderManager` ist `@MainActor` — shared/lock Properties brauchen `nonisolated(unsafe)`
- `ModelContext.placeholder` Extension braucht `@MainActor`

### FormState Naming
- `FormState` in `FormState.swift` = ObservableObject-Version (für FormField, FormSubmitButton)
- `AppFormState` in `FormValidator.swift` = @Observable-Version (für Sheet-Views)

## Offene Aufgaben

- **App auf Simulator lauffähig machen** → siehe [Docs/PLAN-xcode-project-setup.md](Docs/PLAN-xcode-project-setup.md)
  - Projekt ist nur ein Swift Package (Library) — kein `.app` Bundle
  - Lösung: `.xcodeproj` via xcodegen erstellen

## Bekannte Einschränkungen

- Kein `.xcodeproj` vorhanden — App kann nicht auf Simulator installiert werden (nur Library-Build + Tests)
- OpenRouter API-Key nicht konfiguriert → Demo-Vorschläge
- App wurde initial von KI generiert — Code-Qualität variiert

## GitHub

- Repo: `harryhirsch1878/ai-presents-app-ios`
- Branch: `main`
