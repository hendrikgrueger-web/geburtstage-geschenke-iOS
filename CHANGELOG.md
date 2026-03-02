# Changelog

All notable changes to ai-presents-app-ios will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- DevSettingsView for debug mode with sample data creation and data clearing
- ReminderManagerTests for comprehensive reminder rule testing
- Data statistics display in DevSettingsView
- Alert system for dev operations feedback

### Fixed
- Missing DevSettingsView referenced in SettingsView
- Navigation to non-existent DevSettingsView in DEBUG builds

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
