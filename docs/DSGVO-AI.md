# DSGVO-Dokumentation: KI-Features

Stand: März 2026 (v1.0.1)

## Überblick

Die KI-Features (Geschenkvorschläge, Geburtstagsgrüße) übertragen überwiegend pseudonymisierte Daten (mit Vorname für bessere Ergebnisse) über Cloudflare Workers (Proxy) → OpenRouter Inc. (USA) → Google Gemini (USA). Die Nutzung ist optional und erfordert eine explizite Einwilligung des Nutzers.

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

Folgende Daten werden pro KI-Anfrage an OpenRouter / Google übertragen:

- **Vorname** — wird für bessere, personalisierte KI-Ergebnisse übertragen (Nachname verbleibt auf dem Gerät)
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

- **Nachname** (verbleibt ausschließlich auf dem Gerät)
- **Geburtsdatum** (weder Tag, Monat noch Jahr)
- **Exaktes Alter**
- Links (z.B. Produkt-URLs)
- Notizen
- Telefonnummern, E-Mail-Adressen, Kontaktdaten
- iCloud-Identitäten

### 2.3 Anonymisierung (technische Umsetzung)

| Originaldaten | Anonymisierte Form | Utility |
|---|---|---|
| Vorname "Anna" | "Anna" (wird übertragen) + "weiblich" | `GenderInference.swift` |
| Alter 34 | "Mitte 30" | `AgeObfuscator.swift` |
| Geburtstag 15.03. | (nicht übertragen) | — |
| Nachname "Müller" | (nicht übertragen) | — |

---

## 3. Auftragsverarbeiter (Art. 28 DSGVO)

### AVV/DPA-Status Übersicht

| Auftragsverarbeiter | Rolle | DPA-Status | Datum |
|---------------------|-------|------------|-------|
| Cloudflare Inc. | Proxy | ✅ Auto-akzeptiert (Main Service Agreement, DPA v6.3) | Juni 2025 |
| OpenRouter Inc. | API-Gateway | ⏳ DPA angefragt (Enterprise-Tier) | 25. März 2026 |
| Google LLC | Sub-Processor via OpenRouter | ✅ Abgedeckt über OpenRouter-Vertragskette | — |

### Ergänzende Schutzmaßnahmen (Supplementary Measures)

Zusätzlich zu den Standardvertragsklauseln (Art. 46 DSGVO) werden folgende technische Maßnahmen umgesetzt:
- **Zero Data Retention (ZDR):** Weder OpenRouter noch Google speichern Prompts oder Antworten dauerhaft
- **Verschlüsselung in Transit:** TLS 1.3 auf allen Verbindungen (App → Cloudflare → OpenRouter → Google)
- **Kein Modelltraining:** Daten werden nicht zum Training von KI-Modellen verwendet
- **Datensparsamkeit:** Nur pseudonymisierte Daten (Vorname, Altersgruppe, Beziehungstyp) werden übertragen
- **Keine dauerhafte Speicherung:** API-Calls sind stateless — nach Verarbeitung werden keine Daten vorgehalten

### 3.0 Cloudflare Inc.

- **Rolle:** Auftragsverarbeiter (Proxy)
- **Sitz:** USA (San Francisco, CA)
- **Zweck:** Proxying der API-Anfragen, Schutz des API-Keys
- **DPA-Status:** ✅ Automatisch akzeptiert als Teil des Cloudflare Main Service Agreement (DPA v6.3, Juni 2025)
- **DPA-Link:** https://www.cloudflare.com/cloudflare-customer-dpa/
- **Datenschutz:** https://www.cloudflare.com/privacypolicy/
- **Trust Hub:** https://trust.cloudflare.com/
- **Drittlandübermittlung:** USA — Standardvertragsklauseln (SCCs Module 2 & 3) gemäß Art. 46 DSGVO

### 3.1 OpenRouter Inc.

- **Rolle:** Auftragsverarbeiter (API-Gateway)
- **Sitz:** USA (San Francisco, CA)
- **Zweck:** Weiterleitung der KI-Anfragen an das Sprachmodell
- **DPA-Status:** ⏳ DPA angefragt am 25.03.2026 — Enterprise-Tier erforderlich für formales DPA
- **DPA-Kontakt:** enterprise@openrouter.ai / https://openrouter.ai/enterprise
- **Trust Center:** https://trust.openrouter.ai/
- **Datenschutz:** https://openrouter.ai/privacy
- **Zero Data Retention (ZDR):** Aktiviert (`provider.zdr: true`) — OpenRouter speichert keine Prompts oder Antworten dauerhaft
- **Training:** Daten werden NICHT zum Modelltraining verwendet
- **Drittlandübermittlung:** USA — Standardvertragsklauseln gemäß Art. 46 DSGVO

**Hinweis:** Bis zum Abschluss des formalen DPA stützt sich die Datenübertragung auf: (1) Einwilligung des Nutzers (Art. 6.1.a), (2) Standardvertragsklauseln (Art. 46), (3) Zero Data Retention als ergänzende Schutzmaßnahme, (4) OpenRouter ToS mit DPA-Verweis für Organizations.

### 3.2 Google LLC (Vertex AI / Google AI Studio)

- **Rolle:** Sub-Auftragsverarbeiter (Sprachmodell-Betreiber)
- **Sitz:** USA (Mountain View, CA)
- **Zweck:** Verarbeitung der eigentlichen KI-Anfragen
- **DPA-Status:** ✅ Abgedeckt über OpenRouter als Auftragsverarbeiter — kein separater Vertrag erforderlich
- **Datenschutz:** https://policies.google.com/privacy
- **Google Cloud DPA:** https://cloud.google.com/terms/data-processing-addendum
- **Retains Prompts:** Nein — Google speichert keine Prompts bei Nutzung über OpenRouter mit ZDR
- **Training:** Daten werden NICHT zum Modelltraining verwendet
- **Modell:** Google Gemini 3.1 Flash Lite (via OpenRouter)
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
Rennekamp 19, 59494 Soest
Geschäftsführer: Hendrik Grüger, Sebastian Mause
hendriks-apps@gruepi.de

---

## 9. DPA-Anfrage an OpenRouter (Vorlage)

**Status:** ⏳ Angefragt am 25.03.2026
**Kontakt:** enterprise@openrouter.ai / https://openrouter.ai/enterprise

**E-Mail-Vorlage:**

> Subject: Data Processing Agreement (DPA) Request — Grüpi GmbH
>
> Dear OpenRouter Team,
>
> We are Grüpi GmbH (Germany) and operate the iOS app "Geburtstage & Geschenkideen" (Birthday Calendar & Gifts) on the Apple App Store.
>
> Our app uses OpenRouter's API with Zero Data Retention (ZDR) enabled to provide optional AI-powered gift suggestions to EU-based users. As this constitutes data processing under GDPR (Art. 28), we require a formal Data Processing Agreement (DPA/AVV).
>
> Details:
> - Company: Grüpi GmbH, Rennekamp 19, 59494 Soest, Germany
> - App: Geburtstage & Geschenkideen (App Store ID: 6760319397)
> - Model used: Google Gemini 3.1 Flash Lite via OpenRouter
> - Data transmitted: First names, age groups, relationship types, hobbies (pseudonymized, with user consent)
> - ZDR: Enabled (provider.zdr: true)
> - Legal basis: User consent (GDPR Art. 6.1.a) + Standard Contractual Clauses (Art. 46)
>
> Could you provide us with your standard DPA or direct us to the Enterprise tier where DPAs are available?
>
> Best regards,
> Hendrik Grüger
> hendriks-apps@gruepi.de

**Nach Antwort:** DPA-Status in Abschnitt 3 aktualisieren (⏳ → ✅).
