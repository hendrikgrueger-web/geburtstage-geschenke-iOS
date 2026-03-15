# CLAUDE.md — ai-presents-app-ios

## Projekt-Übersicht

iOS-App für Geburtstags- und Geschenkeverwaltung. Generiert von Open Claw (n8n/Telegram Bot), manuell gefixt und weiterentwickelt.

## Skills-Pflicht

**INTENSIV die Apple iOS Platform Skills nutzen** (148 Skills in `.claude/skills/`) — bei jedem Feature, Bug, Review oder Launch-Schritt den passenden Skill aufrufen. Insbesondere:
- **App Store Skills:** `app-description-writer`, `keyword-optimizer`, `screenshot-planner`, `rejection-handler`, `marketing-strategy`
- **Product Skills:** `prd-generator`, `architecture-spec`, `ux-spec`, `implementation-spec`
- **Growth Skills:** `analytics-interpretation`, `indie-business`
- **Monetization:** `storekit-2` für In-App Purchases
- **Testing:** `tdd-feature`, `tdd-bug-fix`, `snapshot-test-setup`
- **Design:** `animation-patterns`, `liquid-glass`, `ui-review`
- **Generators:** `paywall-generator`, `onboarding-generator`, `push-notifications`, `deep-linking`

Ziel: Brutal gutes Ergebnis durch konsequente Nutzung aller verfügbaren Skills.

## Tech Stack

- **Swift 6.0**, SwiftUI, SwiftData (iOS 26+)
- **Architektur:** MVVM mit Services
- **Daten:** SwiftData + iCloud Sync (CloudKit)
- **KI:** OpenRouter API → Google Gemini 3.1 Flash Lite (Cloud, opt-in, DSGVO-konform, vollständig anonymisiert)
- **Widget:** WidgetKit Birthday Widget (Medium + Large) mit Deep-Linking
- **Version:** 1.0.0 (Build 18)
- **Target:** iPhone + iPad / iOS 26+
- **iPad:** NavigationSplitView (zwei Spalten: Sidebar + Detail), alle 4 Orientierungen

## Build

```bash
# iPhone
xcodebuild -project ai-presents-app-ios.xcodeproj -scheme aiPresentsApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
# iPad
xcodebuild -project ai-presents-app-ios.xcodeproj -scheme aiPresentsApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build
```

## Projektstruktur

```
Sources/aiPresentsApp/
├── Models/          # SwiftData Models: PersonRef, GiftIdea, GiftHistory, ReminderRule, SuggestionFeedback
├── Services/        # ContactsService, ContactPhotoService, ReminderManager, AIService, AIConsentManager, SpeechRecognitionService, SampleDataService, WidgetDataService
├── Utilities/       # AppLogger, AppConfig (inkl. AppConfig.AI), FormState, FormValidator, Accessibility, Debouncer, BirthdayCalculator, RelationOptions, GiftDirection, GenderInference, AgeObfuscator
├── Views/
│   ├── Timeline/    # TimelineView (eine chronologische Liste), BirthdayRow (mit Status-Badge), BirthdayCountdownBadge
│   ├── Person/      # PersonDetailView (mit skipGift-Toggle, Hobbies, Received-Gifts), PersonAvatar, AllContactsView, ContactsImportView
│   ├── Gift/        # GiftIdeaRow, GiftHistoryRow, GiftSummaryView, Add/Edit Sheets
│   ├── AI/          # AIChatView (KI-Chat Sheet), ChatBubbleView, ChatInputBar, AIGiftSuggestionsSheet, AIBirthdayMessageSheet, AIConsentSheet
│   ├── Settings/    # SettingsView (als Sheet via Gear-Icon), ReminderSettingsView, PrivacyView, LegalView, DevSettingsView
│   ├── Onboarding/  # OnboardingView
│   ├── Components/  # Wiederverwendbare UI-Komponenten: HobbiesChipView, RelationPickerView, FlowLayout, etc.
│   └── (Root)       # ContentView (kein TabView), ShareSheetView, LaunchScreen
├── ViewModels/      # AppViewModel, AIChatViewModel, SuggestionQualityViewModel
├── Resources/       # AppColor
├── Widgets/         # BirthdayWidgetView (In-App Hero View)
└── aiPresentsApp.swift  # App Entry Point

Sources/BirthdayWidget/  # WidgetKit Extension (separates Target)
├── BirthdayWidget.swift           # Widget Entry Point + WidgetBundle
├── BirthdayTimelineProvider.swift # TimelineProvider (liest JSON aus App Group)
├── BirthdayWidgetViews.swift      # Views für Medium + Large
└── WidgetSharedTypes.swift        # WidgetBirthdayEntry + WidgetDataReader
```

## KI-Chat ("Geschenke-Assistent")

**Einstieg:** Floating Action Button (lila, `sparkles.bubble.fill`) unten rechts auf der TimelineView.

**Architektur:** `AIChatView` (Sheet) → `AIChatViewModel` (@Observable, mit gecachtem System-Prompt) → `AIService.callOpenRouterChat()` (Multi-Turn)

**Features:**
- Natürlichsprachlicher Chat mit Kontextdaten aller Kontakte
- 7 Intent-Typen: `create_gift_idea`, `query`, `update_gift_status`, `open_suggestions`, `clarify_person`, `off_topic`, `none`
- Structured Output: KI antwortet mit JSON `{ message, action: { type, data } }`
- Spracheingabe via SFSpeechRecognizer (on-device bevorzugt)
- Welcome-State mit dynamischen Beispiel-Chips
- Action-Buttons unter Assistant-Bubbles (z.B. "Als Geschenkidee speichern")
- System-Prompt: Natürliche Sprache ("wie ein guter Freund"), Short-IDs nur in action-Feldern, konkrete Daten (nächstes Alter, Hobbies, Geschenk-Historie)

**DSGVO:**
- Consent v2 erforderlich (erweiterte Daten: Geburtstag Monat/Tag, Geschenk-Status, IDs)
- v1-Bestandsnutzer müssen bei Chat-Nutzung erneut zustimmen
- `AIConsentManager.canUseChat` prüft v2-Consent

**Chat ist flüchtig:** Kein persistierter Verlauf, startet jedes Mal frisch.

## KI-Architektur (AIService + AIConsentManager)

**Cloud-basiert via Cloudflare Worker Proxy → OpenRouter** — erfordert explizite DSGVO-Einwilligung.

| Pfad | Voraussetzung | Daten |
|---|---|---|
| App → CF Worker → OpenRouter → Google Gemini | Proxy-Secret + Einwilligung | **Vorname**, Geschlecht (lokal), Altersgruppe, Relation, Sternzeichen, Hobbies, Tags, Budget, Geschenktitel, Tage bis Geburtstag |

**Anonymisierungs-Pipeline:**
- `GenderInference.swift` — leitet Geschlecht aus Beziehungstyp + Vorname lokal ab (`.male`/`.female`/`.neutral`)
- `AgeObfuscator.swift` — wandelt exaktes Alter in Altersgruppe ("Mitte 30", "Anfang 20" etc.)
- **Vorname** wird für KI-Qualität übertragen; **Nachname** + Geburtsdatum werden NIE an die API gesendet

Kein Demo-Modus — ohne Proxy-Secret oder Einwilligung werden Fehler angezeigt.

### AIService

```swift
// Verfügbarkeit
AIService.isAPIKeyConfigured  // true wenn Proxy-Secret in Info.plist vorhanden (nonisolated)
await AIService.isAvailable   // true wenn Secret + Einwilligung (@MainActor)

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
AppConfig.AI.proxySecret          // String aus Info.plist (AIProxySecret)
AppConfig.AI.isAPIKeyConfigured   // Bool (prüft ob Proxy-Secret gesetzt)
AppConfig.AI.model                // "google/gemini-3.1-flash-lite-preview"
AppConfig.AI.openRouterBaseURL    // https://ai-presents-proxy.hendrikgrueger.workers.dev
```

## DSGVO — KI-Features

**Übertragene Daten:** **Vorname** (für KI-Qualität), Geschlecht (lokal abgeleitet via `GenderInference`), Altersgruppe (z.B. "Mitte 30" via `AgeObfuscator`), Beziehungstyp, Sternzeichen, Hobbies/Interessen, Tags, Budget-Rahmen (Min/Max), Geschenktitel, Tage bis Geburtstag
**NICHT übertragen:** Nachname, Geburtsdatum, exaktes Alter, Links, Notizen, Telefonnummer
**Rechtsgrundlage:** Art. 6 Abs. 1 lit. a DSGVO (Einwilligung)
**Datenweg:** App → Cloudflare Workers (Proxy) → OpenRouter Inc. (USA) → Google Gemini (USA)
**Drittlandübermittlung:** Standardvertragsklauseln Art. 46 DSGVO
**Vollständige Doku:** `docs/DSGVO-AI.md`

## Cloudflare Worker Proxy

Der OpenRouter API-Key liegt **nicht** in der App, sondern im Cloudflare Worker (`Proxy/`).
Die App authentifiziert sich mit einem einfachen App-Secret via `X-App-Secret` Header.

```
App → POST /chat (X-App-Secret) → Cloudflare Worker → OpenRouter API (Bearer API-Key)
```

### Worker Status

**Live:** `ai-presents-proxy.hendrikgrueger.workers.dev`
- OPENROUTER_API_KEY: Konfiguriert
- APP_SECRET: Konfiguriert (muss mit `AI_PROXY_SECRET` in `App/Secrets.xcconfig` übereinstimmen)

### Secrets

```bash
# App/Secrets.xcconfig (in .gitignore, NICHT committen)
AI_PROXY_SECRET = <dein-app-secret>

# Template: App/Secrets.xcconfig.example
```

Das Secret wird via `project.yml` → `AIProxySecret` in Info.plist geschrieben und per `Bundle.main.infoDictionary` ausgelesen.

### Worker Deploy

```bash
cd Proxy && npm install
wrangler secret put OPENROUTER_API_KEY   # echten OpenRouter-Key eingeben
wrangler secret put APP_SECRET           # dasselbe Secret wie in Secrets.xcconfig
wrangler deploy
```

## Wichtige Patterns & Konventionen

### SwiftData Models
- `PersonRef` erwartet `contactIdentifier:` als required Parameter
- `PersonRef.skipGift: Bool = false` — "Kein Geschenk nötig" pro Person
- `PersonRef.hobbies: [String] = []` — dauerhafte Interessen pro Person (max. 10, fließt in KI-Prompt ein)
- `PersonRef.relation: String` — Beziehungstyp (wählbar aus 8 vordefinierte Optionen + benutzerdefinierte + "Sonstige"-Fallback)
- `PersonRef.birthYearKnown: Bool = true` — false wenn Geburtsjahr bei Kontakt-Import unbekannt war; KI-Prompt lässt dann Alter weg
- `GiftIdea` Init-Reihenfolge: `status` VOR `tags`
- `GiftStatus` ist `CaseIterable` + `Codable`
- `GiftHistory.direction: String = "given"` — Richtung: "given" (verschenkt) oder "received" (erhalten); SwiftData speichert als String für Migration
- `GiftDirection` enum: `.given`/`.received`, ist `Sendable` + `Codable` + `CaseIterable` (Utilities, nicht Models)
- **RelationOptions (enum):** Zentrale Verwaltung aller Beziehungstypen
  - `RelationOptions.predefined` — 8 vordefinierte + "Sonstige": Partner/in, Mutter, Vater, Schwester, Bruder, Freund/in, Kollege/in, Kind
  - `RelationOptions.custom` — benutzerdefinierte Typen (UserDefaults key: `"customRelationTypes"`)
  - `RelationOptions.all` — kombinierte Liste: `predefined.filter { != "Sonstige" } + custom + ["Sonstige"]`
  - `RelationOptions.addCustom(_:)` — dedupliziert, getrimmt, ignoriert Duplikate
  - `RelationOptions.removeCustom(_:)` — entfernt aus UserDefaults; wenn aktuell selektiert → Fallback auf "Sonstige"
  - `RelationOptions.localizedDisplayName(for:)` — lokalisiert vordefinierte, gibt custom-Typen unverändert zurück

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

### iPad-Patterns
- **NavigationSplitView** in ContentView — `selectedPerson: PersonRef?` als `@State` in ContentView, `@Binding` in TimelineView
- **Kein `.navigationDestination`** — Detail wird direkt in der detail-Spalte gezeigt
- **UIActivityViewController iPad-Fix:** `popoverPresentationController.sourceView/sourceRect` MUSS gesetzt werden (sonst Crash)
- **ShareSheetView:** `popoverPresentationController.permittedArrowDirections = .any` für iPad-Kompatibilität
- **Sheet-Detents:** `.presentationDetents([.medium, .large])` auf allen Add/Edit-Sheets
- **Hover-Effekte:** `.hoverEffect(.highlight)` auf BirthdayRow, GiftIdeaRow, GiftHistoryRow; `.hoverEffect(.lift)` auf SmartSearchBar
- **Keyboard Shortcuts:** Cmd+, (Settings), Cmd+N (Kontakte), Cmd+I (Neue Idee), Cmd+F (AI-Chat)

### iOS 26 Design-Compliance (Pflicht)
- `.foregroundStyle()` statt `.foregroundColor()` (deprecated seit iOS 17)
- `.clipShape(.rect(cornerRadius:))` statt `.cornerRadius()` (deprecated seit iOS 17)
- AppColor-Tokens statt hardcodierter Farben: `AppColor.accent` statt `.orange`, `AppColor.danger` statt `.red`, `AppColor.success` statt `.green`
- Widget-Target: `UIColor.systemXxx` und `Color.accentColor` (kein AppColor-Zugriff im Widget-Target)

### Swift 6 Concurrency
- Tasks, die SwiftData-Models senden: `let p = person` lokale Kopie vor Task, dann `Task { @MainActor in ... }`
- `ContactsService` ist `@MainActor` — `fetchContactData()` ist `nonisolated` für Background-Kontakt-Enumeration
- `BirthdayCalculator.cache` braucht `nonisolated(unsafe)` (mutable static state)
- `ReminderManager` ist `@MainActor` — wird via `.environmentObject()` von App-Root durchgereicht, NIE neue Instanz in Views erstellen
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

### UI-Komponenten & Patterns
- **HobbiesChipView:** FlowLayout mit Chips (wie Erinnerungen-Tags). Return-Taste → neuer Chip, ✕-Tap → löschen. Max. 10.
- **RelationPickerView:** Navigation-basierter Picker (List mit Sections) für Beziehungstypen.
  - **Struktur:** Vordefinierte Typen (oben) | Eigene Typen (Mitte, Swipe-to-Delete) | "Sonstige" + Add-Button (unten)
  - **Funktionen:** Auswahl via Tipp, sofortiges Dismiss; "Eigenen Typ hinzufügen" öffnet Alert mit TextField
  - **Fallback:** Wenn selektierte Relation gelöscht wird → automatischer Fallback auf "Sonstige"
  - **Persistierung:** Custom-Typen via `RelationOptions.addCustom()` / `removeCustom()` in UserDefaults
- **FlowLayout:** Custom Layout für Chip-Anordnung (wrapping, centered, spacing). Wird für Hobbies, Tags und GiftIdea-Chips verwendet.
- **GiftHistoryDirectionSegmented:** Segmented Control ("Verschenkt" / "Erhalten") — bestimmt `GiftHistory.direction`.
- **ContactPhotoService:** On-Demand Laden von Kontaktfotos per `contactIdentifier`. Memory-Caching. Fallback auf Initialen-Circle wenn keine Foto vorhanden. `PersonAvatar` + `CompactPersonAvatar` zeigen echte Kontaktfotos.

### XcodeGen configFiles Pattern
- `configFiles` **MUSS auf Target-Ebene stehen** (Geschwister von `settings:`, nicht Kind)
- Falsch: `settings: { configFiles: { ... } }`
- Richtig: Target-Definition mit `settings: { ... }` UND `configFiles: { ... }` nebeneinander
- Sonst wird `Secrets.xcconfig` nicht ins Xcode-Projekt eingebunden und Secrets (wie `AI_PROXY_SECRET`) sind leer

## UI-Architektur

- **Kein TabView** — NavigationSplitView (iPad: Sidebar + Detail, iPhone: kollabiert zu NavigationStack)
- **ContentView:** `NavigationSplitView(columnVisibility: .doubleColumn)` mit `selectedPerson` als State. Sidebar-Spalte 320–440pt Breite. Empty Detail State mit Gift-Icon.
- **iPad-spezifisch:** `.balanced` Style, alle 4 Orientierungen, `.hoverEffect(.highlight)` auf Rows, `.hoverEffect(.lift)` auf Search Bar, `.presentationDetents([.medium, .large])` auf Sheets, Keyboard Shortcuts (Cmd+, Cmd+N, Cmd+I, Cmd+F)
- **UIRequiresFullScreen: false** — erlaubt Split View + Slide Over auf iPad
- **TimelineView:** Stats-Leiste → Suchfeld → chronologische Liste ALLER Geburtstage
- **BirthdayRow:** Avatar, Name, Countdown, Geschenk-Status-Badge (skipGift/gekauft/geplant/Ideen)
- **Swipe-Actions:** Links-Swipe auf BirthdayRow → "Kein Geschenk" Toggle
- **PersonDetailView:** Name + Avatar oben → Relation Picker → Hobbies-Section → skipGift-Toggle → Gift-Ideen-Section → "In früheren Jahren verschenkt"-Section → "Von mir erhalten"-Section → "Aus App entfernen"-Button (mit Confirmation Alert)
- **GiftHistory Add/Edit Sheet:** Oben Segmented Control ("Verschenkt" / "Erhalten") — bestimmt direction. Felder: Titel (Pflicht), Jahr (Pflicht), Kategorie, Wert, Notiz. Link-Feld nur bei "Verschenkt".
- **AIGiftSuggestionsSheet:** "5 weitere generieren" Button, Akkumulation bis max. 30 Vorschläge. KI nutzt Hobbies + Tags im Prompt.

## Widget-Architektur

**Daten-Sharing:** JSON-Snapshot via App Group UserDefaults (kein SwiftData im Widget)
- **App Group:** `group.com.hendrikgrueger.birthdays-presents-ai`
- **URL-Scheme:** `aipresents://person/{UUID}` für Deep-Linking
- **WidgetDataService** schreibt Snapshot bei: App-Start, Hintergrund-Wechsel, Pull-to-Refresh
- **Timeline-Refresh:** Täglich um Mitternacht + App-getriggert via `WidgetCenter.shared.reloadAllTimelines()`
- **Supported Families:** `.systemMedium` (3 Einträge), `.systemLarge` (7 Einträge)
- Shared Types sind im Widget dupliziert (~30 Zeilen), da Widget-Extensions keinen Zugriff auf das App-Target haben

## Design-Prinzip

Wir orientieren uns **immer** an Apple HIG (Human Interface Guidelines) — natives Design, Standard-Patterns, SF Symbols, System-Farben.

**iOS 26 Design-Standards (zwingend):**
- **System-Farben:** `UIColor.systemXxx` statt hardcodierter Farben — automatische Dark-Mode-Adaption
- **AppColor-Tokens:** Stets `AppColor.accent`, `AppColor.danger`, `AppColor.success` etc. statt `.orange`, `.red`, `.green`
- **Liquid Glass:** `GlassEffectContainer`, `.glassEffect()` Modifier für unterstützte UI-Elemente (iOS 26+)
- **Deprecated APIs vermeiden:**
  - `.foregroundColor()` → `.foregroundStyle()` (deprecated seit iOS 17)
  - `.cornerRadius()` → `.clipShape(.rect(cornerRadius:))` (deprecated seit iOS 17)
- **SF Symbols 7:** Immer neueste Symbol-Varianten verwenden
- **Semantic Colors:** Kontext-bezogene Systemfarben wie `.primary`, `.secondary`, `.tertiary`, `.placeholder`
- **Kein hardcodierter Code:** Farben, Abstände und Fonts aus System-Definitionen ableiten

## App-Start Fehlerbehandlung

- **CloudKit-Fehler:** Automatischer Fallback auf lokalen Store (ohne iCloud Sync)
- **Lokaler Store-Fehler:** In-Memory-Fallback + `ContentUnavailableView` (kein Crash, aber Daten gehen verloren)
- Alle Container-Fehler werden via `AppLogger.data.error()` geloggt

## Lokalisierung (i18n)

**Sprachen:** Deutsch (Development Language) + Englisch
**Technik:** Swift String Catalogs (.xcstrings) — automatische Extraktion durch Xcode

### Pflicht-Regeln für alle neuen Strings

1. **Alle neuen Strings MÜSSEN zweisprachig sein** (DE + EN)
2. **Niemals `Locale(identifier: "de_DE")` hardcoden** → immer `Locale.current`
3. SwiftUI `Text("...")` mit String-Literal → automatisch `LocalizedStringKey`, kein Wrapping nötig
4. Programmatische Strings → `String(localized: "Deutscher Text")`
5. KI-Prompts → `String(localized: "...", table: "AIContent")`
6. Enum Display-Werte: `localizedName` computed property nutzen, NICHT `rawValue`

### String Catalog Dateien

| Datei | Zweck | Target |
|-------|-------|--------|
| `Sources/aiPresentsApp/Localizable.xcstrings` | UI-Strings der Haupt-App | aiPresentsApp |
| `Sources/aiPresentsApp/AIContent.xcstrings` | KI-Prompts | aiPresentsApp |
| `App/InfoPlist.xcstrings` | Usage Descriptions + Display Name | aiPresentsApp |
| `Sources/BirthdayWidget/Localizable.xcstrings` | Widget UI-Strings | BirthdayWidgetExtension |
| `Sources/BirthdayWidget/InfoPlist.xcstrings` | Widget Display Name | BirthdayWidgetExtension |

### Beispiele

```swift
// SwiftUI Text — automatisch lokalisiert:
Text("Keine Geburtstage")           // ✅ LocalizedStringKey
Section("Beziehung") { ... }        // ✅ LocalizedStringKey
Button("Speichern") { ... }         // ✅ LocalizedStringKey
.navigationTitle("Einstellungen")   // ✅ LocalizedStringKey

// Programmatische Strings — String(localized:) nötig:
let msg = String(localized: "\(name) hat in \(days) Tagen Geburtstag")
return String(localized: "Keine Ergebnisse")

// KI-Inhalte:
let prompt = String(localized: "Generiere 5 Geschenkideen", table: "AIContent")

// Enum Pattern:
enum GiftDirection {
    case given, received
    var localizedName: String {
        switch self {
        case .given: String(localized: "Verschenkt")
        case .received: String(localized: "Erhalten")
        }
    }
}
```

### Bekannte Einschränkungen (i18n)

- **RelationOptions in SwiftData:** Deutsche Werte (vordefinierte + custom) sind in der DB gespeichert. Display-Layer lokalisiert Vordefinierte via `RelationOptions.localizedDisplayName()`, custom-Typen werden as-is angezeigt (nicht lokalisierbar). Spätere Migration kann englische Keys für vordefinierte Typen einführen.
- **SampleDataService:** Demo-Personen haben deutsche Namen — niedrige Prio, nur Debug.

## Bekannte Einschränkungen

- Proxy-Secret muss in `App/Secrets.xcconfig` eingetragen werden (`AI_PROXY_SECRET`)
- Cloudflare Worker muss deployed sein mit `OPENROUTER_API_KEY` + `APP_SECRET` Secrets
- Ohne Proxy-Secret: KI-Features nicht nutzbar (Fehlermeldung statt Fallback)
- App wurde initial von KI generiert — Code-Qualität variiert
- Alle Features (KI, Kontakte, Widget) sind für alle User freigeschaltet (kein Premium-Gating)
- **RelationOptions:** Benutzerdefinierte Beziehungstypen sind in UserDefaults persistiert, nicht iCloud-synced; bei Geräte-Sync verlieren sich custom-Typen

## App Store Setup — Stand 2026-03-09

### Registrierte Identifier (Apple Developer Portal ✅)
| Was | Identifier |
|-----|------------|
| App Bundle ID | `com.hendrikgrueger.birthdays-presents-ai` |
| Widget Bundle ID | `com.hendrikgrueger.birthdays-presents-ai.widget` |
| App Group | `group.com.hendrikgrueger.birthdays-presents-ai` |
| App Store Connect App-ID | `6760319397` ✅ |
| Team (Xcode + App Store) | Gruepi GmbH `CU87QNNB3N` |
| Erster Build | 0.8.1 (13) — hochgeladen ✅ |

### TestFlight Status (2026-03-15)
- Builds hochgeladen: v13–v19 (alt), v27 (aktuell, mit ZDR + DSGVO-Fix)
- **Builds 20-26 fehlten in TestFlight** — Ursache: `buildDistributionAudience` war `null`, jetzt auf `INTERNAL_ONLY` gefixt
- Interne Gruppe: `Testgrupp Geschenke-App Hendrik` (gruepigmbh@gmail.com — INSTALLED)
- Externe Gruppe `Familie-extern`: hendrik187@gmail.com (INSTALLED), maik.vonangern@bv.aok.de (INSTALLED)
- Externe Gruppe `Externe-Tester`: bergen.inga@gmail.com (INVITED)

## Xcode Cloud (CI/CD)

**Status:** Aktiv — Workflow "Deploy to TestFlight" mit automatischer Distribution.

| Komponente | Wert |
|------------|------|
| CI Product ID | `9FAFC09A-4B7E-4FD0-ACD1-2DB6847BEFC8` |
| Workflow | "Deploy to TestFlight" — Push auf `main` → Archive iOS → TestFlight (intern + extern) |
| Scheme | `aiPresentsApp` |
| Distribution | `INTERNAL_ONLY` + Nachaktion: externe Gruppen (Familie-extern, Externe-Tester) |
| ci_scripts | `ci_post_clone.sh` — generiert `Secrets.xcconfig` aus `$AI_PROXY_SECRET` |
| GitHub Repo | `hendrikgrueger-web/geburtstage-geschenke-iOS` (verbunden) |
| GitHub Actions | `.github/workflows/test.yml` — Build + SwiftLint bei Push/PR (Dummy Secrets.xcconfig) |

### Environment Variable (in Xcode Cloud Settings)
- `AI_PROXY_SECRET` — Cloudflare Worker App-Secret (redacted)

### WICHTIG: Secret-Rotation (2026-03-15)
- Cloudflare Worker APP_SECRET wurde rotiert
- Neues Secret muss an 3 Stellen identisch sein: Worker (`wrangler secret put`), `App/Secrets.xcconfig` (lokal), Xcode Cloud Environment Variable
- Xcode Cloud Secret muss manuell aktualisiert werden (API unterstützt kein Setzen von Environment Variables)

### Deployment-Workflow
```
Code ändern → git push origin main → Xcode Cloud baut → TestFlight (intern, sofort)
```

## Launch-Plan

Vollständiger Launch-Plan mit 8 Phasen, Skills-Referenz und Revenue-Prognose: **`docs/LAUNCH-PLAN.md`**

## Backlog

### Offen

1. **PersonDetailView aufteilen** (niedrige Prio) — 1041 Zeilen, sollte in Sub-Views aufgeteilt werden
2. **Custom RelationOptions iCloud-Sync** — UserDefaults sind nicht iCloud-synced; bei Geräte-Sync gehen custom-Typen verloren. Später: evtl. SwiftData-Model oder CloudKit für custom-Typen
3. **Relation-DB-Migration** — Vordefinierte Typen sind deutsch in DB gespeichert; spätere Migration kann englische Keys einführen (aktuell: Display-Layer lokalisiert, DB-Werte deutsch)
4. **Doppelter Loading/Error-State in AI-Sheets** (niedrige Prio) — Shared Components extrahieren
5. **TypingIndicator Avatar** — copy-paste Implementierung; eigene View auslagern

### Bekannte technische Schulden
- `ReminderManager.swift:11` — `nonisolated(unsafe)` Warning auf NSLock (unvermeidbar für deinit-Zugriff)

## GitHub

- Repo: `hendrikgrueger-web/geburtstage-geschenke-iOS`
- Branch: `main`
