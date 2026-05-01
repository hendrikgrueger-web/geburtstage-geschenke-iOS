# Architektur-Details — ai-presents-app-ios

## Projektstruktur

```
Sources/aiPresentsApp/
├── Models/          # PersonRef, GiftIdea, GiftHistory, ReminderRule, SuggestionFeedback
├── Services/        # ContactsService, ContactPhotoService, ReminderManager, AIService,
│                    # AIConsentManager, SpeechRecognitionService, SampleDataService, WidgetDataService
├── Utilities/       # AppLogger, AppConfig (inkl. AppConfig.AI), FormState, FormValidator,
│                    # Accessibility, Debouncer, BirthdayCalculator, RelationOptions,
│                    # GiftDirection, GenderInference, AgeObfuscator,
│                    # PersonDetailTypes (GiftSortOption, GiftStatusFilter)
├── Views/
│   ├── Timeline/    # TimelineView, BirthdayRow (mit Status-Badge), BirthdayCountdownBadge
│   ├── Person/      # PersonDetailView (Container), PersonDetailHeaderSection,
│   │                # PersonDetailHobbiesSection, PersonDetailGiftIdeasSection,
│   │                # PersonDetailGiftHistorySection, PersonAvatar,
│   │                # AllContactsView, ContactsImportView
│   ├── Gift/        # GiftIdeaRow, GiftHistoryRow, GiftSummaryView, Add/Edit Sheets
│   ├── AI/          # AIChatView, ChatBubbleView, ChatInputBar,
│   │                # AIGiftSuggestionsSheet, AIBirthdayMessageSheet, AIConsentSheet
│   ├── Settings/    # SettingsView, ReminderSettingsView, PrivacyView, LegalView, DevSettingsView
│   ├── Onboarding/  # OnboardingView
│   ├── Components/  # HobbiesChipView, RelationPickerView, FlowLayout, etc.
│   └── (Root)       # ContentView (kein TabView), ShareSheetView, LaunchScreen
├── ViewModels/      # AppViewModel, AIChatViewModel, SuggestionQualityViewModel
├── Resources/       # AppColor
├── Widgets/         # BirthdayWidgetView (In-App Hero View)
└── aiPresentsApp.swift

Sources/BirthdayWidget/  # WidgetKit Extension (separates Target)
├── BirthdayWidget.swift           # Widget Entry Point + WidgetBundle
├── BirthdayTimelineProvider.swift # TimelineProvider (liest JSON aus App Group)
├── BirthdayWidgetViews.swift      # Views für Medium + Large
└── WidgetSharedTypes.swift        # WidgetBirthdayEntry + WidgetDataReader
```

## KI-Chat ("Geschenke-Assistent")

**Einstieg:** Floating Action Button (lila, `sparkles.bubble.fill`) unten rechts auf TimelineView.

**Flow:** `AIChatView` (Sheet) → `AIChatViewModel` (@Observable, gecachter System-Prompt) → `AIService.callOpenRouterChat()` (Multi-Turn)

**Features:**
- Natürlichsprachlicher Chat mit Kontextdaten aller Kontakte
- 7 Intent-Typen: `create_gift_idea`, `query`, `update_gift_status`, `open_suggestions`, `clarify_person`, `off_topic`, `none`
- Structured Output: JSON `{ message, action: { type, data } }`
- Spracheingabe via SFSpeechRecognizer (on-device bevorzugt)
- Welcome-State mit dynamischen Beispiel-Chips
- Action-Buttons unter Assistant-Bubbles ("Als Geschenkidee speichern")
- System-Prompt: Short-IDs nur in action-Feldern, nächstes Alter, Hobbies, Geschenk-Historie
- Chat ist flüchtig (kein persistierter Verlauf)

**DSGVO Consent:**
- v2 erforderlich (erweiterte Daten: Geburtstag Monat/Tag, Geschenk-Status, IDs)
- v1-Bestandsnutzer müssen bei Chat-Nutzung erneut zustimmen
- `AIConsentManager.canUseChat` prüft v2-Consent

## KI-Datenfluss & Anonymisierung

```
App → Cloudflare Worker (X-App-Secret) → OpenRouter → Google Gemini
```

**Übertragene Daten:** Vorname, Geschlecht (lokal via `GenderInference`), Altersgruppe (via `AgeObfuscator`, z.B. "Mitte 30"), Beziehungstyp, Sternzeichen, Hobbies, Tags, Budget, Geschenktitel, Tage bis Geburtstag

**NICHT übertragen:** Nachname, Geburtsdatum, exaktes Alter, Links, Notizen, Telefonnummer

**Vollständige DSGVO-Doku:** `docs/DSGVO-AI.md`

## Widget-Architektur

**Daten-Sharing:** JSON-Snapshot via App Group UserDefaults (kein SwiftData im Widget)
- App Group: `group.com.hendrikgrueger.birthdays-presents-ai`
- URL-Scheme: `aipresents://person/{UUID}` für Deep-Linking
- `WidgetDataService` schreibt Snapshot bei: App-Start, Hintergrund-Wechsel, Pull-to-Refresh
- Timeline-Refresh: Täglich Mitternacht + `WidgetCenter.shared.reloadAllTimelines()`
- `.systemMedium` (3 Einträge), `.systemLarge` (7 Einträge)
- Shared Types im Widget dupliziert (~30 Zeilen) — Widget hat keinen App-Target-Zugriff

## UI-Architektur

**Kein TabView** — NavigationSplitView (iPad: Sidebar + Detail, iPhone: kollabiert zu NavigationStack)

**ContentView:** `NavigationSplitView(columnVisibility: .doubleColumn)`, `.balanced` Style, Sidebar 320–440pt, Empty Detail State mit Gift-Icon

**TimelineView:** Stats-Leiste → Suchfeld → chronologische Liste aller Geburtstage

**BirthdayRow:** Avatar, Name, Countdown, Geschenk-Status-Badge (skipGift/gekauft/geplant/Ideen). Swipe links → "Kein Geschenk" Toggle

**PersonDetailView:** Name+Avatar → Relation Picker → Hobbies → skipGift-Toggle → Gift-Ideen → Geschenk-Historie → "Aus App entfernen" (mit Confirmation Alert)

**GiftHistory Add/Edit Sheet:** Segmented Control ("Verschenkt"/"Erhalten") oben → Titel (Pflicht), Jahr (Pflicht), Kategorie, Wert, Notiz. Link nur bei "Verschenkt".

**AIGiftSuggestionsSheet:** "5 weitere generieren", Akkumulation bis max. 30 Vorschläge, nutzt Hobbies + Tags im Prompt.

## UI-Komponenten

- **HobbiesChipView:** FlowLayout mit Chips. Return-Taste → neuer Chip, ✕ → löschen. Max. 10.
- **RelationPickerView:** Navigation-basierter Picker (List mit Sections): Vordefinierte | Custom (Swipe-to-Delete) | "Sonstige" + Add-Button. Sofortiges Dismiss bei Auswahl.
- **FlowLayout:** Custom Layout (wrapping, centered, spacing) für Hobbies, Tags, Chips.
- **GiftHistoryDirectionSegmented:** Segmented Control → `GiftHistory.direction`
- **ContactPhotoService:** On-Demand Kontaktfotos per `contactIdentifier`. Memory-Caching. Fallback auf Initialen-Circle. `PersonAvatar` + `CompactPersonAvatar`.

## App-Start Fehlerbehandlung

- **CloudKit-Fehler:** Automatischer Fallback auf lokalen Store
- **Lokaler Store-Fehler:** In-Memory-Fallback + `ContentUnavailableView`
- Alle Fehler via `AppLogger.data.error()`

## Website / Landingpage

- **Pfad:** `website/index.html` — Self-Contained HTML (Stitch "Aura Editorial")
- **Screenshots:** `website/screenshots/` (Symlinks zu `Screenshots/marketing/`)
- **Design:** Warm-Cream (#F9F9F7), Orange/Coral-Gradient, Epilogue + Manrope
- **Deploy:** Noch nicht deployed — Vercel oder Alfahosting möglich
