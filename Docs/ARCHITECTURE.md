# Architektur — ai-presents-app-ios

## 1) Technologie-Stack
- **UI:** SwiftUI
- **Persistenz:** SwiftData
- **Sync:** CloudKit
- **Systemdaten:** Contacts.framework
- **Benachrichtigungen:** UserNotifications
- **KI:** OpenRouter (optional, feature-flag)

## 2) Modulschnitt
- `ContactsImportService` – liest Kontakte/Geburtstage datensparsam
- `Timeline` – sortiert und filtert nächste Geburtstage
- `GiftIdeas` – Geschenkideen inkl. Status/Budget/Link
- `ReminderManager` – plant lokale Reminder nach Regelwerk
- `AIService` – KI-Vorschläge, nur bei Opt-in
- `Settings` – Berechtigungen, Regeln, KI-Schalter, Datenschutzseiten

## 3) Datenmodell
### PersonRef
- `contactIdentifier`
- `displayName`
- `birthday`
- `relation`
- `updatedAt`

### GiftIdea
- `personId`
- `title`, `note`
- `budgetMin`, `budgetMax`
- `link`
- `status` (`idea`, `planned`, `purchased`, `given`)
- `tags`

### GiftHistory
- archivierte/verschenkte Einträge pro Person

### ReminderRule
- `leadDays` (Default: 30/14/7/2)
- `quietHours`
- `enabled`

## 4) Datenfluss (vereinfacht)
1. Kontakte importieren → `PersonRef` speichern
2. Timeline berechnen (heute + Differenzlogik)
3. Gift-Ideen bearbeiten
4. ReminderRule anwenden → Notifications planen
5. Optional KI-Suggestion auf Basis minimierter Nutzdaten

## 5) Fehlertoleranz & Stabilität
- Optionals defensiv behandeln (kein force unwrap in Kernflows)
- Save/Delete mit Fehlerbehandlung + UI-Rückmeldung
- Input-Validation (Budget, URL, Duplikate)
- defensive Navigation (leere Zustände sauber behandeln)

## 6) Datenschutz by Design
- Nur erforderliche Kontaktdaten verarbeiten
- Keine Exportfunktion des gesamten Adressbuchs
- KI-Aufrufe nur bei Opt-in
- KI-Payload auf minimal nötige Felder reduzieren
- klare In-App-Transparenz, was lokal vs. extern verarbeitet wird

## 7) Erweiterbarkeit
- iPad/Mac später durch SwiftUI-Komponentenstruktur möglich
- Widgets/App Intents modular ergänzbar
- KI-Layer austauschbar, wenn Provider wechselt
