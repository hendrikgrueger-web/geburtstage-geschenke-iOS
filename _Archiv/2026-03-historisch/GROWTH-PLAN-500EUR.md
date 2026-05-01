# Growth Plan: €500/Monat — AI Präsente

> Erstellt: 2026-03-14 | 4 Experten-Analysen konsolidiert

---

## Die 3 Hebel mit dem größten Impact

### 1. Trial von 90 → 14 Tage (SOFORT, 5 Minuten)

**Der größte Revenue-Killer:** 3-Monats-Trial = €0 Einnahmen für 90 Tage pro User.

| Trial-Dauer | Conversion Rate | Revenue-Start |
|-------------|----------------|---------------|
| 90 Tage | ~2-4% | Monat 4 |
| **14 Tage** | **8-18%** | **Woche 3** |

Eine Zeile Code: `SubscriptionManager.trialDurationMonths = 3` → `trialDurationDays = 14`

### 2. Preise erhöhen (App Store Connect)

| Produkt | Aktuell | Empfohlen | Begründung |
|---------|---------|-----------|------------|
| Monthly | €2,90 | **€3,99** | +37% Revenue, keine messbare Conversion-Senkung |
| Yearly | €19,90 | **€24,99** | = €2,08/Mo, 48% Rabatt vs Monthly |
| Lifetime | €29,90 | **€59,99** | Kanibalisiert sonst Subscriptions |

### 3. Keywords fixen (App Store Connect, nach Review)

**Fehlende Core-Keywords:** `Geschenk` / `gift` und `KI` / `AI` fehlen komplett!

**DE Keywords (neu):**
```
Geschenk,Siri,Widget,KI,Assistent,Kontakte,Geburtstagsliste,Erinnerung,Planer,Countdown,Jahrestag,Familie
```

**EN Keywords (neu):**
```
gift,AI,assistant,Siri,widget,voice,organizer,contacts,reminder,planner,countdown,tracker,anniversary
```

---

## Revenue-Projektion

**Mit aktuellem Modell (90-Tage-Trial, €2,90):** €30-60/Mo nach 6 Monaten
**Mit optimiertem Modell (14-Tage-Trial, €3,99):** €350-500/Mo nach 6 Monaten

---

## Quick Wins (Features, 1-2 Tage Aufwand)

| # | Feature | Impact | Aufwand |
|---|---------|--------|---------|
| 1 | **Share Extension** (Safari → "Als Geschenkidee speichern") | Tägliche Nutzung | 3-5 Tage |
| 2 | **Lock Screen Widget** (Heute Geburtstag) | 50-100x/Tag Impressions | 1 Tag |
| 3 | **URL-Import** für Gift Ideas (Amazon-Link → Titel+Preis) | Daten-Attachment | 1-2 Tage |
| 4 | **Kontaktlos hinzufügen** (ohne Apple-Kontakt) | Conversion-Barrier weg | 4-8h |
| 5 | **Jahrestage** als eigener Typ | Mehr Nutzungsfrequenz | 4-8h |

---

## ASO-Optimierungen (nach Review)

### App-Name/Subtitle

| Feld | Aktuell | Empfohlen |
|------|---------|-----------|
| EN Name | "Birthdays & Gifts" (18) | **"Birthdays & Gifts: AI Planner"** (30) |
| EN Subtitle | "Your AI Gift-Finding Assistant" (31!) | **"AI Gift Planner & Reminders"** (29) |
| DE Subtitle | "Dein KI-Geschenkeberater" (25) | **"Geschenk Planer mit KI & Siri"** (30) |

### Screenshot-Reihenfolge (6 Stück)

1. "Nie wieder einen Geburtstag vergessen" — Timeline mit Daten
2. "KI findet das perfekte Geschenk" — AI Chat
3. "Direkt auf dem Homescreen" — Widget
4. "Personalisiert nach Hobbies & Alter" — PersonDetail
5. "Hey Siri, wer hat bald Geburtstag?" — Siri-Dialog
6. "Geschenkideen sammeln & verfolgen" — Gift Ideas

### Fehlende Lokalisierungen

| Markt | Prio | Begründung |
|-------|------|------------|
| Italiano (it-IT) | HOCH | Platz 5 weltweit App Store Revenue |
| de-AT / de-CH | MITTEL | DACH-Raum erweitern |
| Português (pt-BR) | MITTEL | Großes Volumen |

---

## Paywall-Optimierungen

### PaywallView verbessern
- [ ] Yearly als visuellen Default (oben, "Meistgewählt")
- [ ] Feature-Liste statt generischem Text
- [ ] Personalisierter Hook: "Du hast X Geburtstage gespeichert"
- [ ] Trial-Countdown in letzten 7 Tagen (Push + Banner)

### Paywall-Trigger (proaktiv, nicht nur reaktiv)
- [ ] Nach erstem Kontakt-Import zeigen (dismissible)
- [ ] 7 Tage vor Trial-Ende: Push-Notification
- [ ] 1 Tag vor Trial-Ende: Push-Notification

---

## Marketing-Zeitplan (Woche für Woche)

### Vor Approval (jetzt)
- [ ] Twitter/X Thread: "App ist im Review" + Screenshots
- [ ] ProductHunt-Profil anlegen
- [ ] 3 TikTok-Videos aufnehmen (Buffer)
- [ ] Reddit-Accounts aufwärmen (hilfreiche Comments)

### Woche 1 (App Store Approval)
- [ ] Tag 1: Twitter "Sie ist live! 🎉"
- [ ] Tag 1: Reddit r/iOSDev "Erste iOS-App veröffentlicht — AMA"
- [ ] Tag 2: TikTok Video 1
- [ ] Tag 5: Show HN (Dienstag 10 Uhr ET)

### Woche 2
- [ ] ProductHunt Launch
- [ ] Reddit r/ADHD Post (authentisch)
- [ ] 3x TikTok/Woche
- [ ] Keyword-Anpassung basierend auf Search Impressions

### Woche 3-4 (Saisonale Vorbereitung)
- [ ] In-App Event für Weihnachten
- [ ] Push-Kampagne planen
- [ ] Lifetime-Deal für Black Friday (temporär €19,90)

### Monat 2 (Dezember — goldener Monat)
- [ ] 2. Dez: Push "22 Tage bis Weihnachten 🎄"
- [ ] 10. Dez: TikTok "So plane ich Geschenke für 8 Personen"
- [ ] 20. Dez: Featuring-Nomination für Valentinstag einreichen
- [ ] In-App Review-Prompt aktivieren

### Monat 3 (Januar-Februar)
- [ ] "Neues Jahr"-Kampagne
- [ ] Valentinstag: Größter Push, In-App Event
- [ ] Preis-Analyse: Bei stabiler Conversion → Preis erhöhen

---

## Apple Featuring Checkliste

- [x] iOS 26 Design (Liquid Glass)
- [x] 4 Sprachen
- [x] Widget
- [x] Siri Integration
- [x] Privacy-First (kein Tracking)
- [ ] Accessibility: Dynamic Type + VoiceOver prüfen
- [ ] Min. 4.5★ Rating mit 50+ Reviews
- [ ] App Preview Video (15-30 Sek)
- [ ] Featuring-Nomination: https://developer.apple.com/contact/app-store/promote/

---

## Viral-Mechanismen (mittelfristig)

1. **"Ich kauf das"-Teilen:** Nach "gekauft"-Markierung → Share Sheet mit App-Link
2. **Gruppen-Koordination:** Familie koordiniert gemeinsam Geschenke (CloudKit Sharing)
3. **Jahresrückblick:** "2026: 12 Freunden gratuliert, €340 ausgegeben" als Share-Image
4. **Lock Screen Widget:** Schön designt → wird als Screenshot geteilt

---

## TikTok Content-Formate

**Format 1 — POV:**
"POV: Du hast vergessen, dass deine beste Freundin nächste Woche Geburtstag hat"
→ Screenrecording: KI generiert 5 Ideen in 3 Sekunden

**Format 2 — Tutorial:**
"3 Sekunden bis zur perfekten Geschenkidee"
→ Person → KI-Chat → Vorschläge

**Format 3 — Dev Story:**
"Ich habe 3 Monate in eine App investiert, die Apple gerade reviewed"
→ Code, Simulator, App Icon

**Rhythmus:** 3x/Woche, DE zuerst, dann EN
