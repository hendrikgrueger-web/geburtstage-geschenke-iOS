# Datenschutzrichtlinie (Privacy Policy)

**App:** AI Präsente
**Version:** 1.0.0
**Stand:** 11. März 2026
**Sprache:** Deutsch

---

## 1. Überblick

AI Präsente respektiert Ihre Privatsphäre und schützt Ihre persönlichen Daten. Diese App wurde entwickelt, um Geburtstage und Geschenkideen zu verwalten, ohne unnötige Daten zu sammeln oder zu teilen.

### Kernprinzipien
- **Datensparsamkeit:** Wir sammeln nur Daten, die für die App-Funktionalität notwendig sind.
- **Transparenz:** Sie wissen jederzeit, welche Daten wir verwenden und wofür.
- **Kontrolle:** Sie haben volle Kontrolle über Ihre Daten und können diese jederzeit löschen.
- **Sicherheit:** Ihre Daten werden verschlüsselt und sicher gespeichert.
- **Keine Tracking:** Wir verwenden keine Tracking-Tools, Analytics oder Werbedienste.

---

## 2. Verantwortlicher

**Anbieter:**
- Gruepi GmbH, Goethestraße 3, 36304 Alsfeld
- Geschäftsführer: Hendrik Grüger
- E-Mail: hendrik@gruepi.de

**Kontakt für Datenschutzfragen:** hendrik@gruepi.de

---

## 3. Welche Daten wir verarbeiten

### 3.1 Kontakte (iOS-Adressbuch)

**Zweck:** Import von Geburtstagsdaten aus Ihren Kontakten.

**Daten:**
- Name und Vorname
- Geburtsdatum (falls vorhanden)
- Profilbild (falls vorhanden)

**Verarbeitung:**
- Daten werden nur lokal auf Ihrem Gerät und in Ihrem persönlichen iCloud-Konto gespeichert.
- Keine Übermittlung an Dritte oder Server des Entwicklers.

**Ihre Kontrolle:**
- Sie können jederzeit in den iOS-Einstellungen den Zugriff auf Kontakte widerrufen.
- Sie können einzelne Kontakte aus der App entfernen.

### 3.2 Benutzerdaten (SwiftData)

**Zweck:** Speicherung von Geschenkideen, Geschenkhistorie und Erinnerungen.

**Daten:**
- Geschenkideen (Titel, Beschreibung, Budget, Links)
- Geschenkhistorie (was Sie wann wem geschenkt haben)
- Erinnerungsregeln (wann Sie erinnert werden möchten)
- AI-Suggestion-Feedback (Ihre Bewertung von Geschenkvorschlägen)

**Verarbeitung:**
- Alle Daten werden lokal auf Ihrem Gerät gespeichert.
- Optionaler iCloud-Sync (CloudKit) zur Synchronisation zwischen Ihren Geräten.
- Keine Übermittlung an Dritte oder Server des Entwicklers.

**Ihre Kontrolle:**
- Sie können alle Daten direkt in der App löschen.
- Sie können den iCloud-Sync in den iOS-Einstellungen deaktivieren.

### 3.3 Benachrichtigungen (Push-Notifications)

**Zweck:** Erinnerungen an Geburtstage und Geschenkplanung.

**Daten:**
- Keine persönlichen Daten werden für Benachrichtigungen gesammelt.
- Benachrichtigungen werden lokal auf Ihrem Gerät generiert.

**Ihre Kontrolle:**
- Sie können jederzeit in den iOS-Einstellungen Benachrichtigungen deaktivieren.
- Sie können Erinnerungsregeln in der App anpassen oder löschen.

### 3.4 iCloud-Sync (CloudKit)

**Zweck:** Synchronisation Ihrer Daten zwischen mehreren iOS-Geräten.

**Daten:**
- Alle oben genannten Benutzerdaten werden übertragen.
- Daten werden in Ihrem persönlichen iCloud-Konto verschlüsselt gespeichert.

**Verarbeitung:**
- Übertragung erfolgt direkt zwischen Ihren Geräten und iCloud.
- Der Entwickler hat keinen Zugriff auf Ihre iCloud-Daten.

**Ihre Kontrolle:**
- Sie können den iCloud-Sync in den iOS-Einstellungen deaktivieren.
- Sie können Daten jederzeit aus der App löschen (dies löscht sie auch aus iCloud).

---

## 4. KI-Funktionen (Optional)

### 4.1 Geschenkideen und Geburtstagsnachrichten

**Zweck:** Generierung von personalisierten Geschenkideen und Geburtstagsnachrichten.

**Verarbeitung:**
- KI-Anfragen enthalten überwiegend anonymisierte Daten: Geschlecht (lokal abgeleitet), Altersgruppe (z.B. „Mitte 30"), Beziehungstyp, Sternzeichen, Interessen, Budget-Rahmen, Geschenktitel.
- Der **Vorname** wird übertragen, um bessere und persönlichere KI-Ergebnisse zu ermöglichen. Der **Nachname** wird NICHT übertragen und verbleibt ausschließlich auf dem Gerät.
- Es werden KEINE Geburtsdaten oder exakten Altersangaben übertragen.
- Anfragen werden über Cloudflare Workers an OpenRouter Inc. (USA) und von dort an Google Gemini (USA) weitergeleitet.
- KI-Antworten werden nur lokal gespeichert.

**Datenschutz:**
- Der Vorname wird für die Qualität der KI-Vorschläge übertragen. Nachname, Geburtsdatum und exaktes Alter werden NICHT übertragen.
- **Zero Data Retention (ZDR):** Die KI-Anfragen werden mit aktiviertem ZDR gesendet. Weder OpenRouter noch Google speichern Prompts oder Antworten dauerhaft. Daten werden nicht zum Modelltraining verwendet.
- Durch aktiviertes Zero Data Retention (ZDR) speichern weder OpenRouter noch Google Anfragen oder Antworten dauerhaft. Daten werden nicht zum Modelltraining verwendet.

**Ihre Kontrolle:**
- KI-Funktionen sind optional und können in den Einstellungen deaktiviert werden.

---

## 5. Daten, die wir NICHT sammeln

Wir sammeln **keine** der folgenden Daten:

- Standortdaten
- Gerätekennungen (Device IDs, Advertising Identifiers)
- Nutzungsstatistiken oder Analytics
- Crash-Reports (wird an Apple übermittelt, nicht an den Entwickler)
- Daten für Werbezwecke
- Drittanbieter-Cookies oder Tracking-Pixel
- Gesundheitsdaten
- Finanzdaten

---

## 6. Datenübermittlung an Dritte

Wir übertragen Ihre persönlichen Daten **nicht** an Dritte, außer:

1. **iCloud (Apple):** Zur Synchronisation zwischen Ihren Geräten (CloudKit).
2. **KI-Dienste (Optional):** Cloudflare Workers (Proxy), OpenRouter Inc. (USA), Google Gemini (USA) — zur Generierung von Geschenkideen (nur anonymisierte Daten).

Beide Übertragungen erfolgen nur mit Ihrer ausdrücklichen Zustimmung und können jederzeit deaktiviert werden.

**Keine Datenübermittlung an:**
- Werbepartner
- Datenbroker
- Social-Media-Plattformen
- Regierungsbehörden (außer gesetzlich vorgeschrieben)

---

## 7. Datensicherheit

Wir treffen angemessene Maßnahmen zum Schutz Ihrer Daten:

- **Lokale Speicherung:** Alle Daten werden verschlüsselt auf Ihrem Gerät gespeichert (iOS Data Protection).
- **iCloud-Verschlüsselung:** iCloud-Daten werden Ende-zu-Ende verschlüsselt (falls aktiviert).
- **Keine offenen Datenbanken:** Alle Datenzugriffe erfolgen über kontrollierte APIs.
- **Regelmäßige Updates:** Wir veröffentlichen Sicherheitsupdates, um bekannte Schwachstellen zu beheben.

---

## 8. Kinder und Jugendliche

Diese App ist für Personen ab 16 Jahren geeignet. Wir sammeln bewusst keine Daten von Kindern unter 13 Jahren:

- Keine Altersverifikation erforderlich.
- Keine besonderen Schutzmechanismen für Minderjährige notwendig.
- Eltern können die App unter Aufsicht nutzen.

---

## 9. Ihre Rechte

Nach der DSGVO (EU) und geltenden Datenschutzgesetzen haben Sie folgende Rechte:

### 9.1 Recht auf Auskunft
Sie können eine Übersicht aller über Sie gespeicherten Daten anfordern.

**Wie:** Senden Sie eine E-Mail an hendrik@gruepi.de mit dem Betreff "Datenauskunft".

### 9.2 Recht auf Löschung
Sie können verlangen, dass alle Ihre Daten gelöscht werden.

**Wie:**
- In der App: Alle Daten über "Einstellungen → Daten löschen" entfernen.
- Per E-Mail: hendrik@gruepi.de mit dem Betreff "Datenlöschung".

### 9.3 Recht auf Berichtigung
Sie können falsche Daten korrigieren lassen.

**Wie:** In der App direkt ändern oder per E-Mail an hendrik@gruepi.de.

### 9.4 Recht auf Datenübertragbarkeit
Sie können alle Ihre Daten in einem maschinenlesbaren Format anfordern.

**Wie:** Senden Sie eine E-Mail an hendrik@gruepi.de mit dem Betreff "Datenexport".

### 9.5 Recht auf Widerruf der Einwilligung
Sie können Ihre Einwilligung zur Datenverarbeitung jederzeit widerrufen.

**Wie:**
- In den iOS-Einstellungen: Kontakte, Benachrichtigungen, iCloud deaktivieren.
- In der App: KI-Funktionen deaktivieren.

---

## 10. Datenretention

**Wie lange werden Ihre Daten gespeichert?**

- **Kontakte:** Solange Sie die App nutzen oder Kontakte in der App speichern.
- **Geschenkdaten:** Solange Sie die App nutzen oder die Daten nicht manuell löschen.
- **Erinnerungen:** Solange Sie die App nutzen oder die Regeln nicht löschen.
- **KI-Feedback:** Solange Sie die App nutzen (für kontinuierliche Verbesserung der KI-Empfehlungen).

**Automatische Löschung:**
- Es gibt keine automatische Löschung Ihrer Daten.
- Bei Deinstallation der App bleiben Daten in iCloud erhalten (falls Sync aktiv).
- Bei Deinstallation ohne iCloud-Sync werden alle lokalen Daten gelöscht.

---

## 11. Änderungen an dieser Datenschutzrichtlinie

Wir behalten uns vor, diese Datenschutzrichtlinie anzupassen:

- Wesentliche Änderungen werden in der App angezeigt.
- Die aktualisierte Version wird hier dokumentiert.
- Sie werden per E-Mail informiert (falls Sie einen Account bei App Store Connect haben).

**Letzte Aktualisierung:** 11. März 2026

---

## 12. Kontakt

Bei Fragen zu dieser Datenschutzrichtlinie oder Ihren Datenrechten kontaktieren Sie uns:

- **E-Mail:** hendrik@gruepi.de
- **GitHub Issues:** https://github.com/hendrikgrueger-web/geburtstage-geschenke-iOS/issues
- **Sprache:** Deutsch oder Englisch

---

## 13. Anhänge

### 13.1 iOS-Settings für Datenschutz

Um Ihre Privatsphäre zu schützen, überprüfen Sie folgende Einstellungen:

**Einstellungen → Datenschutz & Sicherheit:**
- Kontakte: Prüfen, ob AI Präsente Zugriff hat (einmalige Abfrage beim ersten Start).
- Benachrichtigungen: AI Präsente-Benachrichtigungen anpassen oder deaktivieren.

**Einstellungen → [Ihr Name] → iCloud:**
- iCloud Drive: AI Präsente-Daten können deaktiviert werden.

### 13.2 App-Settings für Datenschutz

In der App unter "Einstellungen" können Sie:

- KI-Funktionen aktivieren/deaktivieren
- Alle lokalen Daten löschen

---

**Vielen Dank für Ihr Vertrauen!**
