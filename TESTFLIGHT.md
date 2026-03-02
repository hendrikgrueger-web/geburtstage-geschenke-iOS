# TestFlight Vorbereitung & Release

> Checkliste und Prozess für die Veröffentlichung auf TestFlight und App Store

---

## Status

| Phase | Status | Datum |
|-------|--------|-------|
| MVP Stabilität (Phase 1) | ✅ Abgeschlossen | 2026-03-02 |
| Accessibility & UX (Phase 2) | ✅ Abgeschlossen | 2026-03-02 |
| TestFlight Vorbereitung | 🔄 In Arbeit | 2026-03-02 |
| TestFlight Beta | ⏸️ Ausstehend | — |
| App Store Release | ⏸️ Ausstehend | — |

---

## Pre-Flight Checkliste

### 1. Code Quality

- [x] Alle Tests grün (636+ Test-Methoden)
- [x] SwiftLint durchlaufen (keine kritischen Issues)
- [x] Thread-Safety Fixes (BirthdayCalculator, ReminderManager)
- [x] Memory Leaks geprüft
- [x] Crash-Reports geprüft (keine bekannten Crashes)
- [x] Race Conditions behoben
- [x] Code Coverage: Services & Utilities > 90%

### 2. Build & Signing

- [ ] Xcode 16.4+ installiert
- [ ] Signing Team konfiguriert
- [ ] Bundle Identifier: `com.hendrikgrueger.aiPresentsApp`
- [ ] Version: `0.2.0` (Beta)
- [ ] Build Number: `1` (Auto-Increment aktivieren)
- [ ] Provisioning Profile erstellt
- [ ] App Icons alle Größen (1x, 2x, 3x)
- [ ] Launch Screen konfiguriert

### 3. App Store Connect

- [ ] App in App Store Connect erstellt
- [ ] Bundle Identifier konfiguriert
- [ ] Pricing & Distribution (Gratis)
- [ ] Age Rating (4+)
- [ ] App Privacy (Datenschutzerklärung hinterlegt)
- [ ] Screenshots (iPhone 15 Pro, alle Sizes)
- [ ] App Description (Deutsch & Englisch)
- [ ] Keywords (iOS App Store)
- [ ] Support URL & Marketing URL

### 4. Permissions & Privacy

- [x] Contacts Permission: `NSContactsUsageDescription`
- [x] Notifications Permission: `NSUserNotificationsUsageDescription`
- [ ] Privacy Policy URL hinterlegt
- [ ] Data Collection Info (App Store Privacy)

### 5. TestFlight Konfiguration

- [ ] Beta Tester Gruppe erstellt
- [ ] TestFlight Build hochgeladen
- [ ] TestNotes verfasst (siehe unten)
Flight Release Notes verfasst

---

## TestFlight Release Notes (v0.2.0 Beta)

### Deutsch

**Willkommen bei aiPresents Beta!**

Diese Version enthält:
- **Geburtstag-Timeline**: Heutige und kommende Geburtstage auf einen Blick
- **Geschenkideen-Verwaltung**: Ideen anlegen, planen, tracken
- **Geschenk-Historie**: Was du in früheren Jahren verschenkt hast
- **Intelligente Erinnerungen**: Konfigurierbare Vorwarnungen
- **KI-Vorschläge**: Geschenkideen generieren (optional, Demo-Modus verfügbar)
- **Kontakte-Import**: Automatisch aus iOS Adressbuch
- **iCloud Sync**: Alle Geräte synchronisiert

**Neu in v0.2.0:**
- Verbesserte Accessibility (VoiceOver, Reduced Motion)
- Smart Input Fields mit Real-Time-Validierung
- Debounced Search für bessere Performance
- Quick Action Cards für bessere UX
- Erweiterte Formulare mit visuellem Feedback

**Feedback:** Wir freuen uns über deine Rückmeldung! Fehler und Wünsche bitte über Feedback-Button teilen.

### English

**Welcome to aiPresents Beta!**

This version includes:
- **Birthday Timeline**: Today's and upcoming birthdays at a glance
- **Gift Idea Management**: Create, plan, and track gift ideas
- **Gift History**: What you gifted in previous years
- **Smart Reminders**: Configurable advance notifications
- **AI Suggestions**: Generate gift ideas (optional, demo mode available)
- **Contacts Import**: Automatic from iOS contacts
- **iCloud Sync**: All devices synchronized

**New in v0.2.0:**
- Improved accessibility (VoiceOver, Reduced Motion)
- Smart input fields with real-time validation
- Debounced search for better performance
- Quick action cards for better UX
- Enhanced forms with visual feedback

**Feedback:** We appreciate your feedback! Please share bugs and feature requests via the feedback button.

---

## Build Prozess (macOS mit Xcode)

### 1. Lokal Build

```bash
# Repository klonen
git clone https://github.com/harryhirsch1878/ai-presents-app-ios.git
cd ai-presents-app-ios

# Dependencies auflösen
swift package resolve

# Debug Build
swift build

# Release Build
swift build -c release

# Tests laufen lassen
swift test --enable-code-coverage
```

### 2. Xcode Build für TestFlight

```bash
# Xcode öffnen
open aiPresentsApp.xcodeproj
# oder
open Package.swift

# Build Settings prüfen
- Product → Archive
- Signing & Capabilities → Team auswählen
- Archive erstellen
```

### 3. Upload zu App Store Connect

1. Window → Organizer
2. Select Archive
3. "Distribute App"
4. "TestFlight & App Store"
5. Upload
6. Warten auf Processing
7. In App Store Connect konfigurieren

---

## Release Checkliste (v0.2.0)

### Vor Release

- [ ] Alle offenen Issues gelöst oder auf Backlog verschoben
- [ ] CHANGELOG aktualisiert
- [ ] Versionnummer in `aiPresentsApp.swift` gesetzt
- [ ] Build Number hochgesetzt
- [ ] Release Notes erstellt (Deutsch & Englisch)
- [ ] Screenshots aufgenommen (min. 3.5", 4.7", 5.5", 6.5", 6.7")
- [ ] App Preview Video (optional)
- [ ] Beta Tester informiert (Email/Slack)

### Nach Release

- [ ] Release Announcement im Team
- [ ] Feedback Kanäle überwachen
- [ ] Crash Reports prüfen (Xcode Organizer)
- [ ] Tester Feedback sammeln
- [ ] Next Version Planung starten

---

## Bekannte Issues (v0.2.0)

Keine kritischen Issues bekannt.

### Minor Issues (keine Blocker)

- Timeline Filter View könnte als echte Komponente refactored werden
- Widget Konfiguration könnte verbessert werden (zukünftige Version)

---

## Future Releases

### v0.3.0 (Geplant)
- Home Screen Widget (iOS 17+)
- App Intents für Siri Integration
- iPad Optimierung
- Dark Mode Verbesserungen

### v0.4.0 (Geplant)
- WatchOS Companion App
- KI Prompt Optimierung
- Kontext-basierte Vorschläge
- Geschenk-Budget Tracker

---

## Kontakt & Support

- **GitHub**: https://github.com/harryhirsch1878/ai-presents-app-ios
- **Issues**: https://github.com/harryhirsch1878/ai-presents-app-ios/issues
- **Email**: harryhirsch1878@gmail.com

---

## Notes

- Version follows [Semantic Versioning](https://semver.org/)
- Beta Releases: TestFlight only
- Stable Releases: App Store + TestFlight
- Feedback Channels: In-App Feedback, GitHub Issues, Email
