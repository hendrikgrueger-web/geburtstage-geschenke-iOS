# CLAUDE.md — ai-presents-app-ios

## Projekt-Übersicht

iOS-App für Geburtstags- und Geschenkeverwaltung. Generiert von Open Claw (n8n/Telegram Bot), manuell gefixt und weiterentwickelt.

## Tech Stack

- **Swift 6.0**, SwiftUI, SwiftData (iOS 26+)
- **Architektur:** MVVM mit Services
- **Daten:** SwiftData + iCloud Sync (CloudKit)
- **KI:** OpenRouter API → Google Gemini 3.1 Flash Lite (Cloud, opt-in, DSGVO-konform)
- **Version:** 0.6.0 (Build 9)
- **Target:** iPhone 17 Pro Simulator / iOS 26+

## Build

```bash
xcodebuild -project ai-presents-app-ios.xcodeproj -scheme aiPresentsApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Projektstruktur

```
Sources/aiPresentsApp/
├── Models/          # SwiftData Models: PersonRef, GiftIdea, GiftHistory, ReminderRule, SuggestionFeedback
├── Services/        # CloudKitContainer, ContactsService, ReminderManager, AIService, AIConsentManager, SampleDataService
├── Utilities/       # AppLogger, AppConfig (inkl. AppConfig.AI), FormState, FormValidator, Accessibility, Debouncer, BirthdayCalculator
├── Views/
│   ├── Timeline/    # TimelineView (eine chronologische Liste), BirthdayRow (mit Status-Badge), BirthdayCountdownBadge
│   ├── Person/      # PersonDetailView (mit skipGift-Toggle), PersonAvatar, AllContactsView, ContactsImportView
│   ├── Gift/        # GiftIdeaRow, GiftHistoryRow, GiftSummaryView, Add/Edit Sheets
│   ├── AI/          # AIGiftSuggestionsSheet (bis 30 Vorschläge sammelbar), AIBirthdayMessageSheet, AIConsentSheet
│   ├── Settings/    # SettingsView (als Sheet via Gear-Icon), ReminderSettingsView, PrivacyView, LegalView, DevSettingsView
│   ├── Onboarding/  # OnboardingView
│   ├── Components/  # Wiederverwendbare UI-Komponenten
│   └── (Root)       # ContentView (kein TabView), ShareSheetView, LaunchScreen
├── ViewModels/      # AppViewModel, SuggestionQualityViewModel
├── Resources/       # AppColor
├── Widgets/         # BirthdayWidgetView
└── aiPresentsApp.swift  # App Entry Point
```

## KI-Architektur (AIService + AIConsentManager)

**Cloud-basiert via OpenRouter** — erfordert explizite DSGVO-Einwilligung.

| Pfad | Voraussetzung | Daten |
|---|---|---|
| OpenRouter → Google Gemini | API-Key + Einwilligung | Vorname, Alter, Relation, Sternzeichen, Tags, Budget-Rahmen, Geschenktitel |
| Demo-Modus | immer (Fallback) | Vollständig offline, keine KI |

### AIService

```swift
// Verfügbarkeit
AIService.isAPIKeyConfigured  // true wenn API-Key in Info.plist vorhanden (nonisolated)
await AIService.isAvailable   // true wenn Key + Einwilligung (@MainActor)

// Aufrufe
let suggestions = try await AIService.shared.generateGiftIdeas(for: person, ...)
let message = try await AIService.shared.generateBirthdayMessage(for: person, ...)
```

### AIConsentManager

```swift
// DSGVO-Einwilligung verwalten
AIConsentManager.shared.consentGiven    // Bool
AIConsentManager.shared.aiEnabled      // Toggle (Boolean Binding möglich)
AIConsentManager.shared.canUseAI       // consentGiven && aiEnabled && isAPIKeyConfigured
AIConsentManager.shared.giveConsent()
AIConsentManager.shared.revokeConsent()
```

### AppConfig.AI

```swift
AppConfig.AI.openRouterAPIKey     // String aus Info.plist
AppConfig.AI.isAPIKeyConfigured   // Bool
AppConfig.AI.model                // "google/gemini-3.1-flash-lite-preview"
AppConfig.AI.openRouterBaseURL    // "https://openrouter.ai/api/v1/chat/completions"
```

## DSGVO — KI-Features

**Übertragene Daten:** Vorname, Alter (berechnet), Beziehungstyp, Sternzeichen, Tags, Budget-Rahmen (Min/Max), Geschenktitel
**NICHT übertragen:** Geburtsdatum, Links, Notizen, Telefonnummer
**Rechtsgrundlage:** Art. 6 Abs. 1 lit. a DSGVO (Einwilligung)
**Auftragsverarbeiter:** OpenRouter Inc. (USA) → Google LLC (USA)
**Drittlandübermittlung:** Standardvertragsklauseln Art. 46 DSGVO
**Vollständige Doku:** `Docs/DSGVO-AI.md`

## Secrets / API-Key

```bash
# App/Secrets.xcconfig (in .gitignore, NICHT committen)
OPENROUTER_API_KEY = sk-or-v1-...

# Template: App/Secrets.xcconfig.example
```

Der Key wird via `project.yml` → `OpenRouterAPIKey` in Info.plist geschrieben und per `Bundle.main.infoDictionary` ausgelesen.

## Wichtige Patterns & Konventionen

### SwiftData Models
- `PersonRef` erwartet `contactIdentifier:` als required Parameter
- `PersonRef.skipGift: Bool = false` — "Kein Geschenk nötig" pro Person
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
- `.sheet()` Modifier NICHT an Sub-Views in List/Section anhängen → SwiftUI dismisst sofort bei Re-Render. Immer auf Top-Level `body` hängen.

### Swift 6 Concurrency
- Tasks, die SwiftData-Models senden: `let p = person` lokale Kopie vor Task, dann `Task { @MainActor in ... }`
- `ContactsService` ist `@MainActor`
- `BirthdayCalculator.cache` braucht `nonisolated(unsafe)` (mutable static state)
- `ReminderManager` ist `@MainActor` — lock Properties brauchen `nonisolated(unsafe)`
- `AIConsentManager` ist `@MainActor` — `AIService.isAvailable` ist daher `@MainActor`

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

## UI-Architektur

- **Kein TabView** — nur ein Screen (TimelineView) mit Settings als Sheet (Gear-Icon links oben)
- **TimelineView:** Stats-Leiste → Suchfeld → chronologische Liste ALLER Geburtstage
- **BirthdayRow:** Avatar, Name, Countdown, Geschenk-Status-Badge (skipGift/gekauft/geplant/Ideen)
- **Swipe-Actions:** Links-Swipe auf BirthdayRow → "Kein Geschenk" Toggle
- **PersonDetailView:** skipGift-Toggle blendet Geschenk- und KI-Sections aus
- **AIGiftSuggestionsSheet:** "5 weitere generieren" Button, Akkumulation bis max. 30 Vorschläge

## Design-Prinzip

Wir orientieren uns immer an Apple HIG (Human Interface Guidelines) — natives Design, Standard-Patterns, SF Symbols, System-Farben.

## Bekannte Einschränkungen

- OpenRouter API-Key muss manuell in `App/Secrets.xcconfig` eingetragen werden
- Ohne Key: Demo-Modus (vollständig offline)
- App wurde initial von KI generiert — Code-Qualität variiert

## GitHub

- Repo: `harryhirsch1878/ai-presents-app-ios`
- Branch: `main`
