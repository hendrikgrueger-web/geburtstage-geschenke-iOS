# Naming Self-Check: „MerkTag"

**Stand:** 2026-05-01 · **Risiko-Profil:** Hobby-Indie-Entwicklung (kein Anwalts-Investment, keine kommerziellen Markenanmeldungen)

## Entscheidung

App-Name wird in v1.0.7 von „Geburtstage & Geschenkideen" / „Birthdays & Gifts" auf **„MerkTag"** umgestellt. Reminder-First-Framing statt KI-Front-and-Center.

## Begründung in einem Satz

MerkTag verbindet das deutsche Wortspiel „merken + Tag (besonderer Tag)" mit Reminder-First-Versprechen, ist phonetisch in EN/FR/ES erträglich und nach Recherche frei von App-Store- und Marken-Konflikten. Das eigentliche Erinnerungs-Feature wird damit zur Marke, KI bleibt als Mehrwert dahinter.

## Self-Check-Ergebnisse (2026-05-01)

| Quelle | Suchanfrage | Resultat |
|---|---|---|
| iTunes Search API (DE) | `term=MerkTag&entity=software&country=de` | `resultCount: 0` |
| iTunes Search API (US) | `term=MerkTag&entity=software&country=us` | `resultCount: 9`, alles Merkur-Treffer (Versicherung, Service GmbH, Helper) — keiner heißt „MerkTag" |
| Web-Trademark-Suche (DPMA/EUIPO/TMview-Keyword) | `"MerkTag" Marke OR trademark` site-restricted auf register.dpma.de + euipo.europa.eu + tmdn.org | keine Treffer |
| Web-Brand-Allgemein | `"MerkTag" company brand product` | keine Treffer; ähnliche Brands wie Merck (Pharma, Klasse 5) sind phonetisch & klassen-fern |
| Domain `merktag.com` | whois | frei 🟢 |
| Domain `merktag.io` | whois | frei 🟢 |
| Domain `merktag.de` | whois | belegt (HTTP 403, geparkt — kein aktives Geschäft) |
| Domain `merktag.app` | whois | belegt (kein öffentlicher Inhalt) |
| Domain `merk-tag.de` | whois | frei 🟢 |
| Domain `merk-tag.com` | whois | frei 🟢 |

## Restrisiko-Einschätzung

- **App Store Submit-Konflikt:** keine Konkurrenz-App mit gleichem oder verwechselbarem Namen → Apple-Review wird nicht wegen Name-Confusion blocken
- **Marken-Abmahnung:** sichtbar keine eingetragene Marke „MerkTag" in DE/EU; Merck (Pharma, Klasse 5) ist phonetisch und sachlich entfernt — kein realistisches Konfliktrisiko
- **Domain-Squatting:** `.de` und `.app` belegt von vermutlichen Domain-Squattern. Für die Hobby-Phase irrelevant — Subdomain-Setup auf `gifts.gruepi.de` reicht. Optionale Backup-Registrierung von `merk-tag.de` für ~10 €/Jahr.
- **Eskalations-Plan falls doch ein Cease-and-Desist kommt:** App-Name in 30 Tagen via `asc apps info edit --name` umbenennen — App-Store-ID + User-Daten bleiben erhalten, kein finanzielles Risiko.

## Wann implementieren

Nicht jetzt: 1.0.6 ist in Apple-Review (WAITING_FOR_REVIEW). Ein App-Name-Update während laufender Submission kann den Review-Prozess invalidieren oder cancellen.

**Roll-out mit v1.0.7** (siehe `docs/plans/2026-05-01-001-feat-review-improvements-v107-plan.md`, Unit 2). Dort wird parallel die Listing-Architektur umgebaut — der Namens-Wechsel passt natürlich rein.

## Was konkret in v1.0.7 geändert wird

### App-Name pro Locale (alle ≤ 30 Zeichen)

| Locale | App-Name | Zeichen |
|---|---|---|
| de-DE | MerkTag: Geburtstage | 20 |
| en-US | MerkTag: Birthday Gifts | 23 |
| en-GB | MerkTag: Birthday Gifts | 23 |
| fr-FR | MerkTag: Anniversaires | 22 |
| fr-CA | MerkTag: Anniversaires | 22 |
| es-ES | MerkTag: Cumpleaños | 19 |
| es-MX | MerkTag: Cumpleaños | 19 |

### Subtitle (alle ≤ 30 Zeichen)

| Locale | Subtitle | Zeichen |
|---|---|---|
| de-DE | Geschenke rechtzeitig planen | 28 |
| en-US | Never forget. Gift better. | 26 |
| en-GB | Never forget. Gift better. | 26 |
| fr-FR | Cadeaux planifiés à temps | 25 |
| fr-CA | Cadeaux planifiés à temps | 25 |
| es-ES | Regalos planeados a tiempo | 26 |
| es-MX | Regalos planeados a tiempo | 26 |

### `CFBundleDisplayName` (Homescreen-Icon-Label)

Aktuell: „Geschenke AI" → neu: **„MerkTag"** (in `project.yml` setzen, `xcodegen generate`).

### Description-Reihenfolge (alle Locales)

Reminder-First-Frame nach ChatGPT-Vorschlag:
1. Hook: „Du vergisst keinen Geburtstag mehr. Und nie wieder die passende Geschenkidee."
2. NIE WIEDER VERGESSEN (Erinnerungen, Widget, Timeline) — vorher Block 2
3. GESCHENKE PERFEKT ORGANISIERT — vorher Block 3
4. DEIN KI-GESCHENKEBERATER — vorher Block 1, jetzt zuletzt
5. 100% DEINE DATEN

### Claim für Marketing-Site + ggf. Promotional Text

„Nie wieder zu spät. Nie wieder ideenlos."

## Quellen / Referenzen

- iTunes Search API: https://itunes.apple.com/search?term=MerkTag&entity=software&country=de
- DPMA Markenrecherche (kostenlos, Selbst-Check empfohlen): https://register.dpma.de/DPMAregister/marke/erweiterteRecherche
- EUIPO TMview (kostenlos, Selbst-Check empfohlen): https://www.tmdn.org/tmview/
- Apple App Name Guidelines (30 Z. Limit): https://developer.apple.com/app-store/product-page/
