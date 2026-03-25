---
title: "fix: DSGVO-Härtung — AVV-Status dokumentieren, Consent-Text fixen, Docs konsistent machen"
type: fix
status: active
date: 2026-03-25
---

# DSGVO-Härtung — AVV-Status, Consent-Text, Docs-Konsistenz

## Overview

Drei Datenschutz-Schwachstellen beheben, die im Review vom 25.03.2026 identifiziert wurden:
1. Rechtlich angreifbarer Satz im Consent-Sheet streichen
2. App-Name-Inkonsistenz in allen Docs vereinheitlichen
3. AVV/DPA-Status mit Auftragsverarbeitern formalisieren und dokumentieren

## Problem Frame

Die App "Geburtstage & Geschenkideen" ist seit 24.03.2026 im App Store. Die Datenschutz-Dokumentation ist grundsätzlich gut, hat aber drei Schwachstellen:

- **Consent-Sheet** enthält den Satz "Ein Vorname allein ist nicht personenbezogen" — das ist nach DSGVO Art. 4 Nr. 1 rechtlich angreifbar, weil der Vorname zusammen mit Altersgruppe, Beziehungstyp und Hobbies übertragen wird.
- **Docs** verwenden inkonsistent "AI Präsente" (Home-Screen-Name) statt "Geburtstage & Geschenkideen" (App Store-Name).
- **AVV/DPA** mit OpenRouter fehlt formal (Art. 28 DSGVO Pflicht). Cloudflare DPA ist auto-akzeptiert.

## Requirements Trace

- R1. Consent-Sheet darf keine rechtlich angreifbaren Aussagen enthalten
- R2. App-Name muss in allen Docs konsistent zum App Store-Namen sein
- R3. AVV-Status mit allen Auftragsverarbeitern muss dokumentiert sein
- R4. Nutzer muss über die Auftragsverarbeiter-Kette korrekt informiert werden
- R5. Alle Änderungen müssen in DE + EN konsistent sein

## Scope Boundaries

- Kein Code-Refactoring — nur Text-/Dokumentenänderungen
- Kein neuer Consent-Flow — bestehender v2-Flow bleibt
- OpenRouter-DPA-Anfrage ist ein externer Schritt (dokumentiert, nicht automatisierbar)
- Keine Änderungen an der KI-Architektur oder dem Datenfluss

## Context & Research

### Relevanter Code und Patterns

- `Sources/aiPresentsApp/Views/AI/AIConsentSheet.swift` — Consent-Dialog, Zeile 77: problematischer Satz
- `Sources/aiPresentsApp/Views/Settings/PrivacyView.swift` — In-App Datenschutzerklärung
- `Sources/aiPresentsApp/Views/Settings/LegalView.swift` — Impressum
- `docs/PRIVACY.md` / `docs/PRIVACY_EN.md` — Datenschutzrichtlinie DE/EN
- `docs/TERMS.md` / `docs/TERMS_EN.md` — Nutzungsbedingungen DE/EN
- `docs/DSGVO-AI.md` — KI-DSGVO-Dokumentation

### Recherche-Ergebnisse: OpenRouter DPA

- **OpenRouter DPA:** Existiert, aber nur für Enterprise-Tier. Anfrage via enterprise@openrouter.ai oder openrouter.ai/enterprise
- **OpenRouter Trust Center:** https://trust.openrouter.ai — SOC2-Dokumentation, Security Controls
- **OpenRouter ZDR:** Zero Data Retention ist Default + per-Request aktivierbar (`provider.zdr: true`)
- **Cloudflare DPA:** Auto-akzeptiert als Teil des Main Service Agreement (v6.3, Juni 2025)
- **Google (Sub-Processor):** Kein direktes Vertragsverhältnis nötig — läuft über OpenRouter als Auftragsverarbeiter

## Key Technical Decisions

- **Consent-Text:** Problematischen Satz ersetzen durch neutrale Formulierung über Anonymisierungsstrategie
- **App-Name:** Überall "Geburtstage & Geschenkideen" als primären Namen verwenden, "(AI Präsente)" nur als Home-Screen-Name-Klammer
- **AVV-Dokumentation:** Drei-Stufen-Status: ✅ vorhanden, ⏳ angefragt, ❌ fehlend
- **OpenRouter DPA:** Enterprise-Anfrage als manuellen Schritt dokumentieren, nicht als Blocker für den Release

## Open Questions

### Resolved During Planning

- **Ist E-Mail allein im Impressum ausreichend?** → Ja, nach EuGH-Rechtsprechung reicht E-Mail wenn zeitnah geantwortet wird. Kein Handlungsbedarf.
- **Brauchen wir einen Datenschutzbeauftragten?** → Nein, GmbH mit < 20 Mitarbeitern bei Datenverarbeitung und keine besonders sensiblen Daten.

### Deferred to Implementation

- **OpenRouter DPA-Response:** Zeitpunkt und Konditionen unbekannt — wird nach Anfrage dokumentiert

## Implementation Units

- [ ] **Unit 1: Consent-Sheet Text fixen**

  **Goal:** Rechtlich angreifbaren Satz streichen und durch korrekte Formulierung ersetzen

  **Requirements:** R1

  **Dependencies:** Keine

  **Files:**
  - Modify: `Sources/aiPresentsApp/Views/AI/AIConsentSheet.swift`
  - Modify: `Sources/aiPresentsApp/Localizable.xcstrings` (falls String dort lokalisiert)

  **Approach:**
  - Zeile 77-79: Den gesamten Text-Block im `ConsentSection` "Datenschutz-Prinzip" ersetzen
  - Alt: *"Die KI kennt nur Vornamen, Altersgruppe und Beziehung — keine Nachnamen, keine Geburtsdaten, keine Kontaktdaten. Ein Vorname allein ist nicht personenbezogen."*
  - Neu: *"Die übertragenen Daten sind so gewählt, dass eine Identifikation der beschriebenen Person stark erschwert wird. Nachnamen, Geburtsdaten und Kontaktdaten werden nie übertragen."*
  - EN-Pendant prüfen und konsistent ändern

  **Patterns to follow:**
  - Bestehender Consent-Sheet-Aufbau mit `ConsentSection` + `ConsentDataRow`

  **Verification:**
  - Satz "nicht personenbezogen" kommt nirgends mehr vor
  - Build erfolgreich

- [ ] **Unit 2: App-Name in Docs vereinheitlichen**

  **Goal:** "AI Präsente" durch "Geburtstage & Geschenkideen" als primären App-Namen ersetzen

  **Requirements:** R2

  **Dependencies:** Keine

  **Files:**
  - Modify: `docs/PRIVACY.md`
  - Modify: `docs/PRIVACY_EN.md`
  - Modify: `docs/TERMS.md`
  - Modify: `docs/TERMS_EN.md`
  - Modify: `docs/DSGVO-AI.md`

  **Approach:**
  - Header/Metadaten: `**App:** Geburtstage & Geschenkideen` (statt "AI Präsente")
  - Im Fließtext: "Geburtstage & Geschenkideen" als App-Name, "(AI Präsente)" nur wenn der Home-Screen-Name explizit erklärt wird
  - Version auf 1.0.1 aktualisieren, Stand auf März 2026 belassen
  - In-App-Views (PrivacyView, LegalView, TermsView) prüfen — diese verwenden keinen expliziten App-Namen, nur "die App" → kein Handlungsbedarf dort

  **Verification:**
  - `grep -r "AI Präsente" docs/` zeigt keine alleinstehenden Vorkommen mehr

- [ ] **Unit 3: AVV/DPA-Status dokumentieren**

  **Goal:** Formalen AVV-Status mit allen Auftragsverarbeitern in DSGVO-AI.md dokumentieren

  **Requirements:** R3, R4

  **Dependencies:** Unit 2 (App-Name bereits konsistent)

  **Files:**
  - Modify: `docs/DSGVO-AI.md`

  **Approach:**
  - Abschnitt 3 "Auftragsverarbeiter" überarbeiten: Status-Tabelle mit ✅/⏳/❌
  - Cloudflare: ✅ DPA auto-akzeptiert (Main Service Agreement, v6.3 Juni 2025), Link zum DPA
  - OpenRouter: ⏳ DPA angefragt (Enterprise-Tier erforderlich), Link zum Trust Center
  - Google: ✅ Sub-Processor über OpenRouter, Google Cloud DPA gilt via OpenRouter-Kette
  - "Empfehlung: AVV abschließen" → "Status: DPA angefragt am [Datum]" mit konkretem Kontakt
  - Supplementary Measures dokumentieren: ZDR, Verschlüsselung in Transit, keine Speicherung
  - Kontaktdaten für DPA-Anfrage: enterprise@openrouter.ai

  **Verification:**
  - Jeder Auftragsverarbeiter hat expliziten DPA-Status
  - Keine offenen "Empfehlungen" mehr ohne Zeitplan

- [ ] **Unit 4: In-App PrivacyView aktualisieren**

  **Goal:** PrivacyView konsistent mit aktualisierter DSGVO-AI.md machen

  **Requirements:** R4

  **Dependencies:** Unit 3

  **Files:**
  - Modify: `Sources/aiPresentsApp/Views/Settings/PrivacyView.swift`

  **Approach:**
  - KI-Section: "Cloudflare Workers (Proxy) → OpenRouter Inc. (USA) → Google Gemini (USA)" ist bereits korrekt
  - Ergänzen: "Datenverarbeitung auf Basis von Auftragsverarbeitungsverträgen (DPA) und Standardvertragsklauseln." (statt nur SCC erwähnen)
  - Profilbild-Erwähnung: In PRIVACY.md steht "Profilbild (falls vorhanden)" bei Kontaktdaten, in PrivacyView nicht → in PrivacyView ergänzen oder in PRIVACY.md streichen (Profilbild wird nur lokal angezeigt, nie übertragen → aus PRIVACY.md streichen da irreführend im Kontext "Was wird gespeichert")

  **Verification:**
  - PrivacyView und PRIVACY.md sind inhaltlich konsistent
  - Build erfolgreich

- [ ] **Unit 5: OpenRouter DPA anfragen (manueller Schritt)**

  **Goal:** Enterprise-DPA bei OpenRouter anfordern

  **Requirements:** R3

  **Dependencies:** Unit 3 (Status dokumentiert)

  **Files:**
  - Modify: `docs/DSGVO-AI.md` (Status-Update nach Antwort)

  **Approach:**
  - E-Mail an enterprise@openrouter.ai mit:
    - Firmenname: Grüpi GmbH
    - Zweck: iOS-App mit EU-Nutzern, DSGVO-relevant
    - Anfrage: DPA/Auftragsverarbeitungsvertrag
    - Hinweis auf bestehende ZDR-Nutzung
  - Alternativ: OpenRouter Enterprise-Formular ausfüllen (openrouter.ai/enterprise)
  - E-Mail-Template als Kommentar in DSGVO-AI.md hinterlegen
  - Nach Antwort: DSGVO-AI.md Status aktualisieren

  **Verification:**
  - E-Mail gesendet oder Formular ausgefüllt
  - DSGVO-AI.md enthält Datum der Anfrage

## Risks & Dependencies

- **OpenRouter antwortet nicht:** ZDR + Einwilligung + SCC sind eine starke Basis auch ohne formales DPA. Risiko einer Behörden-Beanstandung ist gering bei einer Consumer-App mit opt-in KI.
- **App Store Review:** Text-Änderungen im Consent-Sheet erfordern keinen neuen Review — nur wenn die App-Binary sich ändert. Da Unit 1 Code ändert, wird ein neuer Build nötig.

## Sources & References

- OpenRouter Privacy Policy: https://openrouter.ai/privacy
- OpenRouter Terms of Service: https://openrouter.ai/terms
- OpenRouter Trust Center: https://trust.openrouter.ai
- OpenRouter Enterprise: https://openrouter.ai/enterprise
- Cloudflare DPA: https://www.cloudflare.com/cloudflare-customer-dpa/
- DSGVO Art. 28 (Auftragsverarbeiter): https://dsgvo-gesetz.de/art-28-dsgvo/
- DSGVO Art. 46 (Standardvertragsklauseln): https://dsgvo-gesetz.de/art-46-dsgvo/
