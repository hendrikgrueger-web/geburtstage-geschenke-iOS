# Security & Legal TODO — vor App Store Release

> Erstellt: März 2026 | Geprüfte Version: 0.8.1 (Build 13)
> Agenten: DSGVO-Check ✅ | Pentester ⏳ (Ergebnisse folgen)

---

## 🔴 KRITISCH — Sofort beheben (Abmahn- / Review-Risiko)

- [ ] **K1 — Adresse ins Impressum**
  - `Sources/aiPresentsApp/Views/Settings/LegalView.swift` Zeile 11
  - `Docs/TERMS.md` Abschnitt 15
  - `Sources/aiPresentsApp/Localizable.xcstrings` (gleicher String DE+EN)
  - Anschrift: Straße, PLZ, Ort, Deutschland — ladungsfähige Adresse nach TMG §5

- [ ] **K2 — Falsche Drittanbieter in Datenschutzerklärung**
  - "OpenAI API" → raus. Korrekt: Cloudflare (Proxy) + OpenRouter + Google Gemini
  - `Docs/PRIVACY.md` Abschnitt 4.1 und 6
  - `Docs/PRIVACY_EN.md` identisch
  - `Sources/aiPresentsApp/Views/Settings/PrivacyView.swift`

- [ ] **K3 — Chat-Datenübertragung vollständig dokumentieren**
  - Chat sendet: Geburtstag (Tag+Monat), alle Geschenkideen inkl. Status, Geschenkhistorie
  - `Docs/PRIVACY.md` Abschnitt 4 → neuen Abschnitt 4.2 "KI-Chat" ergänzen
  - `Docs/DSGVO-AI.md` aktualisieren

- [ ] **K4 — Consent-Text vs. Code angleichen**
  - Geplante Geschenke (`[planned]`, `[purchased]`) werden im Chat übertragen, stehen nicht im Consent
  - Entweder: herausfiltern aus Chat-Prompt (technisch sauberer)
  - Oder: Consent-Text in `AIConsentManager` + Docs explizit erweitern

- [ ] **K5 — Widerspruchsrecht (Art. 21 DSGVO) ergänzen**
  - `Docs/PRIVACY.md` Abschnitt 9 → Abschnitt 9.6 + 9.7 ergänzen
  - `Docs/PRIVACY_EN.md` identisch
  - Auch: Beschwerderecht bei Aufsichtsbehörde (Art. 77 DSGVO) nennen

- [ ] **K6 — PrivacyInfo.xcprivacy erstellen**
  - Datei: `Sources/aiPresentsApp/PrivacyInfo.xcprivacy`
  - Deklarieren: NSPrivacyAccessedAPICategoryUserDefaults (CA92.1)
  - Deklarieren: Kontaktdaten (NSPrivacyCollectedDataTypeContacts)
  - Deklarieren: Audiodaten (Mikrofon/Sprache)
  - Ohne diese Datei: Apple lehnt App seit Herbst 2024 ab

---

## 🟡 SOLLTE ANGEPASST WERDEN — vor App Store

- [ ] **S1 — "Beta" + Versionsnummern in Docs aktualisieren**
  - Alle 4 Dateien: `PRIVACY.md`, `PRIVACY_EN.md`, `TERMS.md`, `TERMS_EN.md`
  - "Version: 0.2.0 (Beta)" → aktuelle Version, "Beta" entfernen

- [ ] **S2 — AVV mit Drittanbietern abschließen (Art. 28 DSGVO)**
  - Cloudflare DPA: https://www.cloudflare.com/cloudflare-customer-dpa/
  - Google DPA: via Google Cloud Console
  - OpenRouter: legal@openrouter.ai kontaktieren
  - Ohne AVV sind Standardvertragsklauseln rechtlich unwirksam

- [ ] **S4 — "nicht-kommerziell" aus LegalView entfernen**
  - `Sources/aiPresentsApp/Views/Settings/LegalView.swift` Zeile 11
  - Besser: "Diese App wird kostenlos zur Verfügung gestellt."

- [ ] **S5 — Demo-Modus-Texte aus Docs entfernen**
  - Existiert nicht mehr im Code, steht aber noch in `TERMS.md` und `PRIVACY.md`

- [ ] **S7 — App Store Privacy Labels vervollständigen**
  - In App Store Connect setzen: Kontaktdaten, Nutzungsdaten, Audiodaten
  - Audiodaten (Mikrofon/Sprache) fehlen aktuell

- [ ] **S8 — Altershinweis im KI-Consent ergänzen**
  - Art. 8 DSGVO: unter 16 braucht elterliche Zustimmung
  - Mindestens Texthinweis: "Ich bestätige, dass ich 16 Jahre oder älter bin."

---

## 🔵 EMPFEHLUNG — Nice to Have

- [ ] **E1 — Datenschutzerklärung als Online-URL** (kein roher GitHub-Link)
- [ ] **E2 — Cloudflare Worker auf EU-Region beschränken** (wrangler.toml)
- [ ] **E3 — Consent-Zeitstempel in AIConsentManager speichern**
- [ ] **E4 — iCloud-Datenlöschung besser dokumentieren**

---

## ⏳ Pentester-Ergebnisse

Werden ergänzt sobald Security-Agent fertig ist.

---

## Quellen

- DSGVO-Agent (Claude Sonnet 4.6), März 2026
- Pentester-Agent (Claude Sonnet 4.6), März 2026 — ausstehend
