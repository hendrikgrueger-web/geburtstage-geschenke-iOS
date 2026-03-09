# ai-presents-app-ios

![Swift](https://img.shields.io/badge/Swift-6.0-orange) ![iOS](https://img.shields.io/badge/iOS-26%2B-blue) ![WidgetKit](https://img.shields.io/badge/WidgetKit-supported-green) ![License](https://img.shields.io/badge/License-Private-red)

iPhone-App für Geburtstags- und Geschenkeverwaltung: Kontakte nutzen, Ideen speichern, zeitgerecht erinnert werden – Apple-nativ, iCloud-synchronisiert, KI-unterstützt (opt-in).

---

## Features

- **Geburtstags-Timeline** – Chronologische Ansicht mit Countdown (Heute / 7 Tage / 30 Tage)
- **Geschenkideen-Management** – Anlegen, bearbeiten, löschen, duplizieren, mit Tags und Budget-Rahmen
- **Geschenk-Historie** – "Früher verschenkt" und "Von mir erhalten" pro Person
- **Intelligente Erinnerungen** – Anpassbar (Standard: 30/14/7/2 Tage vor Geburtstag)
- **KI-Assistent** – Chat-basiert, Geschenkvorschläge & Glückwünsche (OpenRouter / Google Gemini, opt-in)
- **iCloud-Sync** – SwiftData + CloudKit Synchronisierung zwischen Geräten
- **Kontakt-Fotos** – Echte Kontaktbilder oder Initialen-Avatar mit Fallback
- **Widget** – WidgetKit (Medium & Large) mit Deep-Linking in die App
- **Dark Mode** – Native iOS 26 Liquid Glass, System-Farben, HIG-konform
- **Accessibility** – VoiceOver-Support, Semantic Colors
- **Lokalisierung** – Deutsch & Englisch (Swift String Catalogs)

---

## Screenshots & Demo

> Hinweis: Für Screenshots siehe TestFlight-Builds oder öffne die App im Simulator.

**Hauptbildschirm:** TimelineView mit Stats (heute, diese Woche, nächster Monat), Suchfeld, chronologische Liste aller Geburtstage.
**Personendetail:** Name + Avatar, Beziehungstyp, Hobbies, skipGift-Toggle, Geschenkideen-Verwaltung, Historie.
**KI-Chat:** Floating Action Button (unten rechts, Sparkles-Icon) öffnet Chat-Sheet mit Multi-Turn-Dialog, Action-Buttons unter KI-Responses.
**Widget:** Medium (3 Einträge) und Large (7 Einträge) mit Countdown und Status-Badges.

---

## Tech Stack

| Bereich | Technologie |
|---------|-------------|
| **Sprache** | Swift 6.0 |
| **UI Framework** | SwiftUI |
| **Daten** | SwiftData + CloudKit |
| **Widget** | WidgetKit (iOS 26+) |
| **AI** | OpenRouter API → Google Gemini 3.1 Flash Lite |
| **Kontakte** | Contacts.framework + ContactsUI |
| **Erinnerungen** | EventKit (UserNotifications) |
| **Deployment** | Cloudflare Worker Proxy (API-Key Management) |
| **Minimum iOS** | iOS 26+ |
| **Package Manager** | Xcode 26+ (xcodeproj + XcodeGen) |
| **Architektur** | MVVM + Services |

---

## Architektur

**Einstieg:** `aiPresentsApp.swift` initialisiert SwiftData Container (mit CloudKit oder Fallback), ReminderManager, AIConsentManager via `.environmentObject()`.

**Datenfluss:**
```
UI Views (TimelineView, PersonDetailView, AIChatView)
    ↓
ViewModels (@Observable, State Management)
    ↓
Services (ContactsService, ReminderManager, AIService, WidgetDataService)
    ↓
SwiftData Models (PersonRef, GiftIdea, GiftHistory, ReminderRule)
    ↓
CloudKit Container (iCloud Sync) / Local Store Fallback
```

**Besonderheiten:**
- **Kein TabView** – ein einziger Screen (TimelineView) mit Settings-Sheet (Gear-Icon)
- **ReminderManager** – `@MainActor` Singleton, wird via Umgebungsobjekt durchgereicht
- **AIService** – Cloud-basiert via Cloudflare Worker Proxy (API-Key bleibt server-seitig)
- **WidgetDataService** – Snapshots per App-Group UserDefaults (Widget hat keinen SwiftData-Zugriff)
- **ContactPhotoService** – On-Demand Laden mit Memory-Cache, Fallback auf Initialen
- **Swift 6 Concurrency** – @MainActor Services, Sendable Models, TaskLocal Context

---

## Projektstruktur

```
Sources/aiPresentsApp/
├── Models/
│   ├── PersonRef.swift           # SwiftData Person, contactIdentifier-basiert
│   ├── GiftIdea.swift            # Geschenkidee mit Status und Tags
│   ├── GiftHistory.swift         # Früher verschenkt / erhalten
│   ├── ReminderRule.swift        # Erinnerungsregel
│   └── SuggestionFeedback.swift  # Feedback zur KI-Qualität

├── Services/
│   ├── ContactsService.swift             # Contacts.framework Integration
│   ├── ContactPhotoService.swift         # Kontaktfotos mit Memory-Cache
│   ├── ReminderManager.swift             # EventKit + UserNotifications
│   ├── AIService.swift                   # OpenRouter API via Worker Proxy
│   ├── AIConsentManager.swift            # DSGVO-Einwilligung (UserDefaults)
│   ├── SpeechRecognitionService.swift    # SFSpeechRecognizer (on-device)
│   ├── SampleDataService.swift           # Demo-Daten für Debug
│   └── WidgetDataService.swift           # App-Group Snapshots

├── ViewModels/
│   ├── AIChatViewModel.swift    # KI-Chat State, System-Prompt Caching
│   └── SuggestionQualityViewModel.swift  # Feedback-Logik

├── Utilities/
│   ├── AppLogger.swift          # Logging (ui, data, forms, reminder, notifications)
│   ├── AppConfig.swift          # Configuration, AppConfig.AI für Proxy-Secret
│   ├── FormState.swift          # ObservableObject für Forms
│   ├── FormValidator.swift      # AppFormState (@Observable) + Validierung
│   ├── Accessibility.swift      # Accessibility Labels + Helpers
│   ├── Debouncer.swift          # @MainActor Debouncer für Search
│   ├── BirthdayCalculator.swift # Alter, Countdown, Zodiac (cached)
│   ├── RelationOptions.swift    # 8 vordefinierte + custom Beziehungen
│   └── GiftDirection.swift      # Enum: .given / .received

├── Views/
│   ├── Timeline/
│   │   ├── TimelineView.swift           # Hauptscreen: Stats → Search → BirthdayList
│   │   ├── BirthdayRow.swift           # Row mit Avatar, Countdown, Status-Badge
│   │   └── BirthdayCountdownBadge.swift # Badge-Styling

│   ├── Person/
│   │   ├── PersonDetailView.swift  # Relation, Hobbies, GiftIdeas, Historie
│   │   ├── PersonAvatar.swift      # Avatar mit Kontaktfoto oder Initialen
│   │   ├── AllContactsView.swift   # Import-Quelle
│   │   └── ContactsImportView.swift # Kontakt-Auswahl + Mapping

│   ├── Gift/
│   │   ├── GiftIdeaRow.swift           # GiftIdea mit Status und Tags
│   │   ├── GiftHistoryRow.swift        # GiftHistory (gegeben/empfangen)
│   │   ├── GiftSummaryView.swift       # Stats per Person
│   │   ├── AddGiftIdeaSheet.swift      # Sheet zum Erstellen
│   │   └── EditGiftIdeaSheet.swift     # Sheet zum Bearbeiten

│   ├── AI/
│   │   ├── AIChatView.swift            # Multi-Turn Chat Sheet
│   │   ├── ChatBubbleView.swift        # User / Assistant Bubble
│   │   ├── ChatInputBar.swift          # Text + Sprache-Input
│   │   ├── AIGiftSuggestionsSheet.swift # "5 weitere" Button, Akkumulation
│   │   ├── AIBirthdayMessageSheet.swift # Glückwunsch-Generator
│   │   └── AIConsentSheet.swift        # DSGVO-Einwilligung

│   ├── Settings/
│   │   ├── SettingsView.swift         # Gear-Icon Sheet: alle Optionen
│   │   ├── ReminderSettingsView.swift # Reminder-Tage konfigurieren
│   │   ├── PrivacyView.swift          # Datenschutz (Info)
│   │   ├── LegalView.swift            # Rechtliches (Info)
│   │   └── DevSettingsView.swift      # Debug-Optionen (Daten löschen, Logging)

│   ├── Onboarding/
│   │   └── OnboardingView.swift  # First-Launch-Wizard

│   ├── Components/
│   │   ├── HobbiesChipView.swift        # Chip-Editor (max. 10)
│   │   ├── RelationPickerView.swift     # Relation-Picker (8 + Sonstige)
│   │   ├── FlowLayout.swift             # Custom Layout für Chips
│   │   ├── CompactPersonAvatar.swift    # Kleine Avatar-Variante
│   │   ├── TypingIndicator.swift       # Animate Dots für KI-Thinking
│   │   └── GiftHistoryDirectionSegmented.swift # Verschenkt / Erhalten

│   └── (Root)/
│       ├── ContentView.swift            # App Root (keine TabView)
│       ├── ShareSheetView.swift         # System Share-Sheet Wrapper
│       └── LaunchScreen.swift           # Splash Screen

├── Resources/
│   └── AppColor.swift  # Design Tokens: accent, danger, success, etc.

├── Widgets/
│   └── BirthdayWidgetView.swift  # In-App Widget Hero View

└── aiPresentsApp.swift  # App Entry Point + Container Setup

Sources/BirthdayWidget/  # WidgetKit Extension (separates Target)
├── BirthdayWidget.swift              # Widget Bundle + Timeline Provider
├── BirthdayWidgetViews.swift         # Medium + Large Views
└── WidgetSharedTypes.swift           # WidgetBirthdayEntry, DataReader
```

---

## Setup & Build

### Voraussetzungen

- Xcode 26+
- iPhone mit iOS 26+ (oder Simulator)
- CocoaPods / SPM (falls externe Dependencies)

### Quick Start

```bash
# Repo klonen
git clone https://github.com/hendrikgrueger-web/geburtstage-geschenke-iOS.git
cd ai-presents-app-ios

# Xcode öffnen
open ai-presents-app-ios.xcodeproj

# Signing Team einstellen (Target → Signing & Capabilities)
# Capabilities prüfen:
#   - Contacts
#   - Notifications
#   - iCloud (CloudKit)
#   - App Groups (für Widget)

# Build
xcodebuild -project ai-presents-app-ios.xcodeproj \
  -scheme aiPresentsApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

### XcodeGen (falls Projektstruktur geändert wird)

```bash
# Swift Package Dependencies oder neue Source-Dateien hinzufügen?
# → project.yml anpassen, dann:
xcodegen generate

# Für Secrets (AI Proxy):
# 1. App/Secrets.xcconfig.example → App/Secrets.xcconfig kopieren
# 2. AI_PROXY_SECRET eintragen (von Cloudflare Worker)
```

---

## KI-Features & DSGVO

### Aktivierung

1. **Proxy-Secret eintragen** (`App/Secrets.xcconfig`)
   ```
   AI_PROXY_SECRET = <dein-app-secret>
   ```

2. **Consent geben** (in-app Settings oder bei Chat-Nutzung)
   ```
   AIConsentManager.shared.giveConsent()
   ```

3. **API-Verfügbarkeit prüfen**
   ```swift
   if await AIService.isAvailable {
       // KI-Features verfügbar
   }
   ```

### Cloudflare Worker Proxy

Der OpenRouter API-Key liegt **nicht** in der App. Stattdessen läuft ein Cloudflare Worker:

```
App (AI_PROXY_SECRET)
  → POST /chat
  → Cloudflare Worker (OPENROUTER_API_KEY)
  → OpenRouter
  → Google Gemini 3.1 Flash Lite
```

**Worker URL:** `ai-presents-proxy.hendrikgrueger.workers.dev`

**Deploy:**
```bash
cd Proxy
npm install
wrangler secret put OPENROUTER_API_KEY
wrangler secret put APP_SECRET  # ← muss APP/Secrets.xcconfig entsprechen
wrangler deploy
```

### DSGVO-Compliance

**Einwilligung erforderlich:** Ja (Art. 6 Abs. 1 lit. a DSGVO)

**Übertragene Daten:**
- Vorname, berechnetes Alter, Beziehungstyp, Sternzeichen
- Hobbies/Interessen, Tags, Budget-Rahmen, Geschenktitel

**NICHT übertragen:**
- Volles Geburtsdatum, Links, Notizen, Telefonnummer

**Auftragsverarbeiter:** OpenRouter Inc. → Google LLC (beide USA)
**Drittlandübermittlung:** Standardvertragsklauseln (Art. 46 DSGVO)

Weitere Details: `Docs/DSGVO-AI.md`

### Intent-Typen (KI-Chat)

Der AI-Chat erkennt 7 Intents:
- `create_gift_idea` – Idee als Geschenkidee speichern
- `query` – Fragen beantworten
- `update_gift_status` – Geschenk-Status ändern
- `open_suggestions` – Vorschläge-Generator
- `clarify_person` – Person erfragen
- `off_topic` – Off-Topic (freundlich ablehnen)
- `none` – Keine Action nötig

---

## Widget

### Architektur

**Daten-Sharing:** App-Group UserDefaults (JSON-Snapshot), kein SwiftData im Widget

- **App Group:** `group.com.hendrikgrueger.ai-presents`
- **Refresh:** Täglich 00:00 + on-demand via `WidgetCenter.shared.reloadAllTimelines()`
- **Families:** `.systemMedium` (3 Einträge), `.systemLarge` (7 Einträge)
- **Deep-Linking:** `aipresents://person/{UUID}` → PersonDetailView

### Daten-Update

`WidgetDataService` schreibt Snapshot bei:
- App-Start
- Hintergrund-Wechsel
- Pull-to-Refresh (TimelineView)
- Geschenk-Status-Änderung

---

## Tests

**Gesamtzahl:** 726 Tests
**Bestanden:** 725 (99,9%)
**Skipped:** 99 (SwiftData/Simulator-Inkompatibilität)

**Struktur:**
- Service Layer (AIService, ReminderManager, etc.) – 100% Coverage
- Utilities (BirthdayCalculator, FormValidator, etc.) – 100% Coverage
- Models – SwiftData Tests skipped im Test Host Mode (XCTSkip)
- Accessibility – 100% Coverage

**Laufen:**
```bash
xcodebuild -project ai-presents-app-ios.xcodeproj \
  -scheme aiPresentsApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

---

## Version & Roadmap

**Aktuelle Version:** 0.9.1 (Build 13)

**Meilensteine:**
1. ✅ MVP Stabilität & QA-Härtung (2026-03)
2. ✅ iOS 26 HIG-Compliance & Widget Overhaul
3. 🔄 TestFlight Vorbereitung (v0.2.0 Beta)
4. Custom Relation Types (UserDefaults-persistiert, Swipe-to-Delete)
5. App Store Submission (Post-Beta)

Vollständiger Launch-Plan: `Docs/LAUNCH-PLAN.md`

---

## Dokumentation

- **`Docs/LAUNCH-PLAN.md`** – 8-Phasen Launch mit Revenue-Prognose
- **`Docs/ARCHITECTURE.md`** – Technische Deep-Dives
- **`Docs/DSGVO-AI.md`** – Datenschutz & KI-Compliance
- **`Docs/PRIVACY.md`** – Privacy Policy (DE)
- **`Docs/PRIVACY_EN.md`** – Privacy Policy (EN)
- **`Docs/TERMS.md`** – Nutzungsbedingungen (DE)
- **`Docs/TERMS_EN.md`** – Terms of Service (EN)
- **`CLAUDE.md`** – Interne Entwicklungs-Konventionen

---

## Bekannte Einschränkungen

- **Proxy-Secret erforderlich** – Ohne `AI_PROXY_SECRET` funktionieren KI-Features nicht (Fehlermeldung, nicht Fallback)
- **Initiale App-Generierung** – Code wurde mit KI generiert, Code-Qualität variiert (wird kontinuierlich verbessert)
- **Keine Premium-Unterscheidung** – Alle Features sind für alle User freigeschaltet
- **RelationOptions DB-Werte** – Deutsche Werte in SwiftData gespeichert, UI-Layer lokalisiert (künftige Migration auf englische Keys möglich)

---

## Lizenz

Privat. Bei Übernahme externer OSS-Komponenten siehe `Docs/LEGAL-OSS-REUSE.md`.

---

## Contributing

Für Fragen oder Verbesserungen: GitHub Issues oder Discussions.

---

**Gebaut mit:** Swift 6, SwiftUI, SwiftData, OpenRouter, Cloudflare Workers

**GitHub:** [`hendrikgrueger-web/geburtstage-geschenke-iOS`](https://github.com/hendrikgrueger-web/geburtstage-geschenke-iOS)
