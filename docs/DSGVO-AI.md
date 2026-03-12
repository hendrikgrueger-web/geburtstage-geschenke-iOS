# DSGVO-Dokumentation: KI-Features

Stand: März 2026 (v1.0.0)

## Überblick

Die KI-Features (Geschenkvorschläge, Geburtstagsgrüße) übertragen ausschließlich anonymisierte Daten über Cloudflare Workers (Proxy) → OpenRouter Inc. (USA) → Google Gemini (USA). Die Nutzung ist optional und erfordert eine explizite Einwilligung des Nutzers.

---

## 1. Rechtsgrundlagen

| Verarbeitungszweck | Rechtsgrundlage |
|---|---|
| KI-Geschenkvorschläge | Art. 6 Abs. 1 lit. a DSGVO (Einwilligung) |
| KI-Geburtstagsgrüße | Art. 6 Abs. 1 lit. a DSGVO (Einwilligung) |
| Drittlandübermittlung USA | Art. 46 DSGVO (Standardvertragsklauseln) |

---

## 2. Datenkategorien

### 2.1 Was wird übertragen

Folgende anonymisierte Daten werden pro KI-Anfrage an OpenRouter / Google übertragen:

- **Geschlecht** — lokal abgeleitet aus Beziehungstyp und Vorname (z.B. "weiblich", "männlich", "Person")
- **Altersgruppe** — ungefähre Angabe (z.B. "Mitte 30", "Anfang 20"), NICHT das exakte Alter
- **Beziehungstyp** — z.B. "Freund", "Mutter", "Kollege"
- **Sternzeichen** — berechnet aus dem Geburtsdatum (keine Personaldaten)
- **Hobbies/Interessen** — dauerhafte Hobbies pro Person, sofern eingetragen
- **Tags** — einmalige Interessen/Tags pro Geschenkidee, sofern eingetragen
- **Budget-Rahmen** — Min/Max-Werte für passende Geschenkvorschläge
- **Geschenktitel** — nur Titel (ohne Jahr, Notizen oder Links)
- **Tage bis Geburtstag** — relative Angabe (z.B. "10 Tage"), kein Datum

### 2.2 Was NICHT übertragen wird

Folgende Daten verlassen das Gerät niemals im Rahmen der KI-Features:

- **Name** (weder Vor- noch Nachname)
- **Geburtsdatum** (weder Tag, Monat noch Jahr)
- **Exaktes Alter**
- Links (z.B. Produkt-URLs)
- Notizen
- Telefonnummern, E-Mail-Adressen, Kontaktdaten
- iCloud-Identitäten

### 2.3 Anonymisierung (technische Umsetzung)

| Originaldaten | Anonymisierte Form | Utility |
|---|---|---|
| Vorname "Anna" | "weiblich" | `GenderInference.swift` |
| Alter 34 | "Mitte 30" | `AgeObfuscator.swift` |
| Geburtstag 15.03. | (nicht übertragen) | — |
| Name "Anna Müller" | (nicht übertragen) | — |

---

## 3. Auftragsverarbeiter (Art. 28 DSGVO)

### 3.0 Cloudflare Inc.

- **Rolle:** Auftragsverarbeiter (Proxy)
- **Sitz:** USA (San Francisco, CA)
- **Zweck:** Proxying der API-Anfragen, Schutz des API-Keys
- **Datenschutz:** https://www.cloudflare.com/privacypolicy/
- **DPA:** Verfügbar unter https://www.cloudflare.com/cloudflare-customer-dpa/
- **Drittlandübermittlung:** USA — Standardvertragsklauseln gemäß Art. 46 DSGVO

### 3.1 OpenRouter Inc.

- **Rolle:** Auftragsverarbeiter (API-Gateway)
- **Sitz:** USA (San Francisco, CA)
- **Zweck:** Weiterleitung der KI-Anfragen an das Sprachmodell
- **Datenschutz:** https://openrouter.ai/privacy
- **Drittlandübermittlung:** USA — Standardvertragsklauseln gemäß Art. 46 DSGVO

**Empfehlung:** Mit OpenRouter einen Auftragsverarbeitungsvertrag (AVV) abschließen. Kontakt: legal@openrouter.ai

### 3.2 Google LLC (Vertex AI / Google AI Studio)

- **Rolle:** Sub-Auftragsverarbeiter (Sprachmodell-Betreiber)
- **Sitz:** USA (Mountain View, CA)
- **Zweck:** Verarbeitung der eigentlichen KI-Anfragen
- **Datenschutz:** https://policies.google.com/privacy
- **Modell:** Google Gemini (via OpenRouter)
- **Drittlandübermittlung:** USA — Standardvertragsklauseln gemäß Art. 46 DSGVO

---

## 4. Einwilligungsmanagement (Technische Umsetzung)

### 4.1 AIConsentManager

```swift
// Speicherort: Sources/aiPresentsApp/Services/AIConsentManager.swift
// Speicherung: UserDefaults (lokal, kein Server-Roundtrip)

// Keys:
// - "ai_dsgvo_consent_v1": Bool — Einwilligung erteilt
// - "ai_feature_enabled_v1": Bool — KI aktiviert/deaktiviert
```

### 4.2 Einwilligungsflow

1. User tippt auf KI-Button in PersonDetailView
2. Wenn keine Einwilligung: AIConsentSheet öffnet sich
3. Sheet zeigt alle übertragenen Daten, Verarbeiter, Rechtsgrundlagen
4. User wählt "Zustimmen" → `AIConsentManager.shared.giveConsent()`
5. User wählt "Ablehnen" → Sheet schließt, keine KI-Nutzung

### 4.3 Widerruf

- Jederzeit in Einstellungen → KI-Assistent → "Widerrufen"
- Widerruf setzt beide UserDefaults-Keys auf `false`
- Rückwirkende Löschung der bereits übertragenen Daten: Nicht möglich (stateless API-Calls)

### 4.4 Verfügbarkeitsprüfung

```swift
// AIService.isAPIKeyConfigured: true wenn API-Key in Info.plist vorhanden
// AIConsentManager.shared.consentGiven: true nach Einwilligung
// AIConsentManager.shared.canUseAI: true wenn beides + Key konfiguriert
```

---

## 5. Fallback-Verhalten

Wenn KI nicht verfügbar ist (kein Key, keine Einwilligung, Netzwerkfehler):
- Es wird eine Fehlermeldung angezeigt
- Keine Daten werden übertragen

---

## 6. App Store Privacy Labels

Für die App Store Connect Privacy-Deklaration sind folgende Labels empfohlen:

### Daten, die mit der Person verknüpft werden
- (Keine — alle KI-Daten werden anonymisiert übertragen)

### Daten, die nicht mit der Person verknüpft werden
- **Nutzungsdaten:** KI-Anfragen (Geschlecht, Altersgruppe, Relation, Sternzeichen, Hobbies, Tags, Budget-Rahmen, Geschenktitel)

### Keine Datenverfolgung
- Kein Tracking im Sinne von ATT

**Hinweis:** Da die KI-Features optional und einwilligungspflichtig sind, können sie als "optionale Features" deklariert werden.

---

## 7. Betroffenenrechte (Art. 15–22 DSGVO)

Da die App selbst keine Nutzerdatenbank betreibt:

| Recht | Umsetzung |
|---|---|
| Auskunft (Art. 15) | Alle Daten lokal auf Gerät einsehbar |
| Berichtigung (Art. 16) | In der App direkt bearbeitbar |
| Löschung (Art. 17) | Einstellungen → Alle Daten löschen |
| Widerruf (Art. 7 Abs. 3) | Einstellungen → KI-Assistent → Widerrufen |
| Übertragbarkeit (Art. 20) | CSV-Export in PersonDetailView |

Für Daten, die bereits an OpenRouter/Google übertragen wurden:
- Diese werden nach der Verarbeitung nicht dauerhaft gespeichert (stateless)
- Weitere Auskunft: Direkter Kontakt zu OpenRouter und Google

---

## 8. Kontakt Datenschutz

Gruepi GmbH
Goethestraße 3, 36304 Alsfeld
Geschäftsführer: Hendrik Grüger
hendrik@gruepi.de
