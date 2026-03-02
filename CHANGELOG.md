# Changelog

All notable changes to ai-presents-app-ios will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **Zodiac Symbols Bug**: Corrected zodiac sign symbols in BirthdayDateHelper
  - All zodiac signs were incorrectly displaying as '♈' (Aries)
  - Fixed: ♉ Stier, ♊ Zwilling, ♋ Krebs, ♌ Löwe
  - Fixed: ♍ Jungfrau, ♎ Waage, ♏ Skorpion, ♐ Schütze
  - Fixed: ♑ Steinbock, ♒ Wassermann, ♓ Fische
  - Impact: Zodiac signs now display correctly across the app
- **Build-Fehler behoben (~50+ Compile-Errors über 34 Dateien)**
  - **AppLogger**: `AppLoggerCategory` Struct mit `.ui`, `.data`, `.forms`, `.reminder`, `.notifications` hinzugefügt; Typo `.appingPathComponent` → `.appendingPathComponent`
  - **CloudKitContainer + aiPresentsApp**: `ModelConfiguration(identifier:)` → positional Parameter; `cloudKitDatabase: nil` → `.none`
  - **ContactsService**: `await` → `try await` für `requestAccess`; `.granted` entfernt (Bool direkt)
  - **ReminderManager**: `@MainActor` auf `ModelContext.placeholder`; `nonisolated(unsafe)` auf statische Properties
  - **SampleDataService**: `contactIdentifier: ""` ergänzt; `status:`/`tags:` Reihenfolge korrigiert; `deleteContainer()` → `delete(model:)`
  - **FormValidator**: `FormState` → `AppFormState` umbenannt (Namenskollision mit SwiftUI)
  - **AIGiftSuggestionsSheet**: `-> View` → `-> some View` (8 Computed Properties + Funktionen); `Identifiable` auf `GiftSuggestion`
  - **Section-Syntax**: `Section("title") { } footer:` → `Section { } header: { } footer: { }` (6 Stellen in 4 Dateien)
  - **symbolEffect**: `.pulse`/`.bounce` Ternary-Typ-Mismatch → `.symbolEffect(.bounce, isActive:)` (5 Dateien)
  - **Alert message-Closures**: Conditional Logic in Computed Properties extrahiert (4 Sheet-Views)
  - **Duplikate entfernt**: `PressableButtonStyle`, `accessibleButton`, `exportAsText`, `DevSettingsView` (je 2× definiert)
  - **AccessibilityConfiguration**: `Date.Style` → `DateFormatter.Style`; `.isNotEnabled` → `.isStaticText`
  - **SmartInputField**: `TimeInterval.milliseconds(300)` → `0.3`; Parameter-Reihenfolge korrigiert
  - **PersonAvatar**: `LinearGradient` als Shadow-Color → `AppColor.primary`
  - **TimelineView**: Optional-Unwrap korrigiert; Body in Sub-Views aufgeteilt (Type-Check-Timeout)
  - **EditGiftIdeaSheet**: Body in Sub-Views aufgeteilt (Type-Check-Timeout)
  - **GiftIdeaRow**: `budgetString` (String) in `Text()` gewrappt
  - **BirthdayDateHelper**: `calendar.daysBetween` → `dateComponents([.day], ...)`
  - **Debouncer**: Fehlendes `import SwiftUI` ergänzt
  - **GiftIdea**: `CaseIterable` auf `GiftStatus` Enum ergänzt

### Added
- **Phase 4: TestFlight Documentation**
  - **Privacy Policy (Deutsch & Englisch)**: Complete data protection documentation
    - Data collection overview (contacts, user data, notifications, iCloud sync)
    - AI features data handling (optional, minimal context only)
    - No tracking, analytics, or advertising commitment
    - User rights (access, deletion, correction, portability, withdrawal)
    - Data retention and security measures
    - GDPR and privacy law compliance
  - **Terms of Service (Deutsch & Englisch)**: Comprehensive usage terms
    - Eligibility and user responsibilities
    - Intellectual property and open-source licensing
    - Disclaimer and liability limits
    - AI features usage terms (use at own risk)
    - Support availability and beta phase notes
    - Dispute resolution and governing law (Germany)
  - **Documentation Updates**:
    - Updated `Docs/INDEX.md` with legal documentation links
    - Updated `README.md` to reference privacy policy and terms of service
    - Updated `RELEASE_CHECKLIST.md` to mark legal documentation as completed
    - Updated `TESTFLIGHT.md` to reference legal documentation
- **Phase 3: Logging & Analytics Foundation**
  - **AppLogger Utility**: Centralized logging system with structured logging
    - Multiple log levels (debug, info, warning, error)
    - Category-specific logging (AI, CloudKit, Contacts)
    - Release-optimized (minimal logs in production)
    - Optional file persistence for debugging
    - Performance metrics logging
    - Network request logging
    - User action tracking
  - **AppLoggerTests**: 25 tests covering all logger functionality
    - Log level filtering tests
    - Context formatting tests
    - Category-specific logging tests
    - File logging tests
    - Performance tests
- **Phase 3: AI Quality Enhancements**
  - AI Context Helper with age and milestone detection
  - Enhanced demo suggestions with milestone-specific gift ideas (18, 30, 40+)
  - Personalized birthday message generation feature
  - Age-aware gift suggestions based on life stage
  - Birthday message drafts with warm, appreciative tone
  - Zodiac sign context for AI prompts
  - Birthday timing context (today, tomorrow, X days)
  - **AIBirthdayMessageSheet**: New UI for generating personalized birthday messages
  - **PersonDetailView Integration**: "Geburtstagsnachricht" button for quick access
  - **Birthday Message Features**: Copy to clipboard, share, regenerate messages
  - **Person Details Card**: Shows age, milestone status, and birthday timing in message sheet
  - **Loading States**: Animated spinner with status text during message generation
  - **Error Handling**: User-friendly error messages with retry option
  - **Demo Mode Fallback**: Alert notification when API key is not configured
- **Phase 3: Suggestion Quality Metrics System**
  - **SuggestionFeedback Model**: SwiftData model for tracking user feedback per AI suggestion
  - **SuggestionQualityViewModel**: @MainActor ObservableObject for managing feedback state
    - `recordFeedback()`: Save feedback with haptic feedback
    - `loadMetrics()`: Load global quality metrics
    - `metricsFor(personId:)`: Person-specific metrics
    - `feedbackFor(personId:)`: Get all feedback for a person
    - `clearAllFeedback()`: Reset functionality
  - **SuggestionFeedbackView**: Compact thumbs up/down feedback interface
    - "War das hilfreich?" prompt
    - Disabled state after feedback given
    - Haptic feedback on button press
  - **Quality Metrics Integration**: Added to AIGiftSuggestionsSheet
    - Quality metrics section (shows when data exists)
    - Person-specific rating display
    - Feedback UI under each suggestion
    - Smart interaction: Can save suggestions even after feedback
    - Visual feedback checkmark after feedback
  - **Rating System**: 5-level quality scale with star ratings
    - ⭐⭐⭐⭐⭐ Ausgezeichnet (80-100% positive)
    - ⭐⭐⭐⭐ Gut (60-79% positive)
    - ⭐⭐⭐ Akzeptabel (40-59% positive)
    - ⭐⭐ Verbesserungswürdig (20-39% positive)
    - ⭐ Kritisch (0-19% positive)
- **Tests**
  - Tests for milestone-based gift suggestions (18th, 30th birthday)
  - Tests for birthday message generation across age groups
  - Tests for birthday message structure and past gifts context
  - **AIBirthdayMessageSheetTests**: 18 new tests covering:
    - View initialization for different age groups and milestones
    - Person data binding with various relationships
    - BirthdayMessage structure validation
    - Age group detection (under 18, 18-29, 30-49, 50+)
    - Milestone detection (18, 30, 40, etc.)
    - Zodiac sign calculation
  - **SuggestionQualityViewModelTests**: 15 tests covering:
    - Feedback recording (positive, negative, mixed)
    - Metrics calculation for all 5 rating levels
    - No data scenario
    - Person-specific tracking
    - Clear feedback functionality
    - SuggestionQualityMetrics initialization and factory method
- TestFlight preparation documentation (TESTFLIGHT.md) with comprehensive checklist
- TestFlight release notes (German & English) for v0.2.0 Beta
- App Store Connect setup guide and build process documentation
- Test coverage statistics in README (29 test files, 636+ test methods)
- Beta Tester Guide (BETA_TESTERS.md) with detailed testing checklist
- Test focus areas for core functionality and accessibility
- Known issues and workarounds section for beta testers
- SmartInputField integration in Add/Edit sheets for enhanced UX
- Real-time debounced validation (300ms) for all form inputs
- Visual feedback with icons, colors, and error messages in forms
- Auto-https normalization for URL fields
- Debouncer utility integration in TimelineView for search performance
- QuickActionCard integration in EmptyStateView for better action hierarchy
- Consistent design system across all forms and empty states

### Changed
- AI prompts now include age, milestone, zodiac, and timing context
- Demo mode suggestions are now personalized based on age and milestones
- Gift suggestions are more relevant to person's life stage and relationship
- PersonDetailView footer now includes birthday message button alongside AI suggestions
- TimelineView: Replaced manual Task.sleep debouncing with Debouncer utility
- EmptyStateView: Use QuickActionCard for improved action presentation
- AddGiftIdeaSheet: SmartInputField for title, notes, URL with validation
- AddGiftHistorySheet: SmartInputField for title, category, notes, URL
- EditGiftIdeaSheet: SmartInputField for title, notes, URL
- EditGiftHistorySheet: SmartInputField for title, category, notes, URL
- AIGiftSuggestionsSheet: Allow saving suggestions as gift ideas even after feedback given

### Improved
- AI suggestions are now more context-aware and personalized
- Birthday messages can be generated automatically with personalized drafts
- Demo mode provides better, more relevant suggestions for different age groups
- Milestone birthdays (18, 21, 30, 40, 50...) get special attention in suggestions
- Birthday message generation with Apple-style UI, haptic feedback, and accessibility support
- Form validation now provides real-time feedback instead of submit-time alerts
- Search debouncing uses dedicated utility for better performance and maintainability
- Empty state actions have better visual hierarchy and discoverability
- All form inputs have consistent validation behavior and visual feedback
- URL fields automatically add https:// prefix when missing scheme

### Changed
- EmptyStateView: Respects reduced motion for icon animations (bounce → pulse when reduced)
- TimelineView: Respects reduced motion for list animations and empty state icons
- BirthdayRow: Enhanced accessibility hints for quick-add button
- AddGiftIdeaSheet: Improved accessible toggle for budget slider
- PersonDetailView: Enhanced accessibility labels for delete button and menu options
- Better accessibility support across key views (SettingsView, PersonDetailView, TimelineView)

### Improved
- AccessibilityConfiguration provides centralized accessibility helpers
- Reduced Motion is automatically detected from UIAccessibility
- All symbol effects respect user's motion preferences
- VoiceOver navigation improved with better element grouping and labels

### Added
- Pull-to-refresh gesture for TimelineView to manually refresh birthday calculations
- Toast notifications for SettingsView actions (permission changes, reminders, data reset, feedback)
- Finalized App Icon design with Gift Box + Calendar concept
- AppIcon.md with complete design specifications and Figma/Sketch template
- Comprehensive tests for BirthdayCalculator.clearCache() functionality
- Category validation in ValidationHelper with empty field check
- URL normalization helper to auto-add https:// to URLs without scheme
- Tag sanitization helper to clean up tag arrays
- BirthdayCalculator.age() caching for better performance

### Improved
- Better user feedback with toast notifications for all SettingsView actions
- Manual refresh capability for TimelineView after contact imports
- BirthdayCalculator cache management with clearCache() method for refresh scenarios
- Improved UX with immediate visual feedback for settings changes
- Better accessibility in SettingsView with improved feedback messages
- Category validation now checks for empty fields (FormValidator)
- URL validation now accepts URLs without http/https prefix
- Tags validation automatically filters out empty tags
- Performance improvements for age calculations in BirthdayRow
- Better user feedback for CSV export operations with success/error/warning toasts
- Enhanced accessibility coverage for gift idea and history editing forms
- Clearer hints for VoiceOver users on all form inputs

### Fixed
- DevSettingsView for debug mode with sample data creation and data clearing
- ReminderManagerTests for comprehensive reminder rule testing
- Data statistics display in DevSettingsView
- Alert system for dev operations feedback
- Comprehensive form validation across all data entry sheets
- Visual feedback for form validation errors (red text, alerts)
- FormState integration with proper error tracking
- Tags validation (max 10 tags, max 30 chars per tag)
- Category validation (max 50 chars)
- Budget validation with real-time feedback
- URL validation with alert guidance for invalid entries
- BirthdayCalculator caching with 5s TTL for better performance
- BirthdayCalculator cache validation tests
- FormatterHelperTests: 50+ tests for date, currency, budget, list, and duration formatting
- AccessibilityHelperTests: 40+ tests for accessibility labels and formatting
- AppConfigTests: comprehensive tests for app configuration constants
- HapticFeedbackTests: non-crash tests for all haptic feedback methods
- ValidationHelperTests: 60+ tests covering all validation methods
- AnimationHelperTests: tests for all animation utilities and factories
- AppColorTests: comprehensive tests for color system and gradients
- Toast notification system for non-intrusive user feedback
- ToastItem with success/error/warning/info types
- ToastView with smooth slide-in/fade-out animations
- Auto-dismiss with configurable duration
- View modifier for easy toast integration

### Changed
- Replace all print() statements with proper AppLogger for consistent logging
- Add error handling callbacks to all URL opening operations
- Improved TimelineView rendering performance with cached birthday calculations

### Fixed
- Missing DevSettingsView referenced in SettingsView
- Navigation to non-existent DevSettingsView in DEBUG builds
- Form validation gaps in Add/Edit sheets for gifts and history
- Missing validation feedback for tags and categories
- Insufficient error messages when saving with invalid data
- Save button disabled too aggressively (only for title, not for other fields)
- Missing visual feedback for budget validation errors
- URL opening without error handling in all sheet views (Add/Edit GiftIdea, Add/Edit GiftHistory, Settings)

## [0.1.0] - 2026-03-02

### Initial MVP Release

#### Features
- **Geburtstag-Timeline**: Heute / 7 Tage / 30 Tage Ansicht
- **Personenansicht**: Countdown, Geschenkideen, Historie pro Kontakt
- **Geschenkideen-CRUD**: Anlegen, Bearbeiten, Löschen, Duplizieren
- **Geschenk-Verlauf**: Historie mit Jahr, Kategorie, Budget
- **Erinnerungs-Regeln**: Konfigurierbare Vorwarnungen (30/14/7/2 Tage)
- **Ruhestunden**: Keine Benachrichtigungen in definiertem Zeitraum
- **Kontakte-Import**: Import aus iOS Adressbuch
- **Demo-Daten**: Sample Daten für Tests und Onboarding
- **iCloud Sync**: Automatische Synchronisation über CloudKit/SwiftData
- **KI-Vorschläge**: OpenRouter Integration (opt-in, Demo-Mode verfügbar)
- **Swipe Actions**: Schnelle Aktionen in Listen
- **Share**: Teilen von Geschenkideen und Personen
- **Export als CSV**: Export von Geschenkideen pro Kontakt
- **Filter**: Nach Geschenkideen und Beziehung filtern
- **Suche**: Volltext-Suche nach Namen und Beziehungen
- **Quick Stats**: Überblick über Kontakte, Ideen, bevorstehende Geburtstage
- **Haptic Feedback**: Haptisches Feedback für Interaktionen
- **Empty States**: Hilfreiche Zustände bei leeren Listen
- **Onboarding**: Einführungstour für neue Benutzer
- **Settings**: Umfassende Einstellungsansicht
- **Privacy & Legal**: Datenschutz- und Impressum-Seiten
- **Widgets**: Birthday Widget Vorschau
- **Accessibility**: VoiceOver-Labels und Hinweise

#### Data Models
- **PersonRef**: Kontakt mit Geburtstag, Beziehung
- **GiftIdea**: Geschenkidee mit Titel, Budget, Status, Tags, Link, Notiz
- **GiftHistory**: Geschenk-Verlauf mit Jahr, Kategorie, Budget, Notiz, Link
- **ReminderRule**: Erinnerungs-Konfiguration

#### Services
- **ContactsService**: iOS Kontakte Import
- **SampleDataService**: Demo-Daten Generierung
- **AIService**: KI-Vorschläge via OpenRouter
- **ReminderManager**: iOS Benachrichtigungen Scheduling

#### Utilities
- **HapticFeedback**: Tactile Feedback
- **URLValidator**: URL Validierung und Sanitisierung
- **FormValidator**: Formular-Validierung mit Fehlerbehandlung
- **AppColor**: Apple-natives Farbschema mit Gradienten

#### UI Components
- **TimelineView**: Hauptansicht für Geburtstage
- **PersonDetailView**: Detailansicht für Kontakte
- **BirthdayRow**: Geburtstags-Zeile mit Avatar
- **BirthdayCountdownBadge**: Countdown Badge mit Animation
- **QuickStatsView**: Schnelle Statistik-Übersicht
- **GiftIdeaRow**: Geschenkidee-Zeile
- **GiftHistoryRow**: Geschenk-Verlauf-Zeile
- **GiftSummaryView**: Zusammenfassung pro Person
- **EmptyStateView**: Leere Zustände
- **PersonAvatar**: Avatar mit Gradient
- **SettingsView**: Einstellungen
- **OnboardingView**: Einführung

#### Testing
- **ModelValidationTests**: Tests für alle Models
- **URLValidatorTests**: URL Validierung Tests
- **FormValidatorTests**: Formular-Validierung Tests
- **BirthdayCalculationTests**: Geburtstags-Berechnung Tests
- **ReminderManagerTests**: Erinnerungs-Management Tests

#### Documentation
- **README.md**: Projektübersicht und Schnellstart
- **PRD.md**: Produktanforderungen
- **ARCHITECTURE.md**: Technische Architektur
- **ROADMAP.md**: Entwicklungspfad
- **EXECUTION-PLAN-4-WEEKS.md**: 4-Wochen Umsetzungsplan
- **DEVELOPMENT.md**: Entwicklungs- und QA-Workflow
- **LEGAL-OSS-REUSE.md**: OSS Lizenzregeln

---

## Future Releases

### Planned (v0.2.0)
- Home Screen Widget (iOS 17+)
- App Intents für Siri Integration
- Widget Konfiguration
- WatchOS Companion App
- TestFlight Beta

### Planned (v0.3.0)
- KI Prompt Optimierung
- Kontext-basierte Vorschläge
- Geschenk-Budget Tracker
- Dark Mode Verbesserungen
- iPad Optimierung

### Planned (v0.4.0)
- Multi-Device Sync Tests
- Performance Optimierung
- Analytics (opt-in)
- Crash Reporting
- In-App Feedback

---

## Notes
- Version follows [Semantic Versioning](https://semver.org/)
- Breaking changes will be indicated by Major version bump
- Features will be indicated by Minor version bump
- Bug fixes will be indicated by Patch version bump
