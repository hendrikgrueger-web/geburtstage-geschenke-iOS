# Changelog

All notable changes to ai-presents-app-ios will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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
- TimelineView: Replaced manual Task.sleep debouncing with Debouncer utility
- EmptyStateView: Use QuickActionCard for improved action presentation
- AddGiftIdeaSheet: SmartInputField for title, notes, URL with validation
- AddGiftHistorySheet: SmartInputField for title, category, notes, URL
- EditGiftIdeaSheet: SmartInputField for title, notes, URL
- EditGiftHistorySheet: SmartInputField for title, category, notes, URL

### Improved
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
