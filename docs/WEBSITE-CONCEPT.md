# Website-Konzept — Marketing-Site für „Geburtstage & Geschenkideen"

> **Briefing-Dokument für Design-Iteration.** Selbsterklärend; ein Designer (oder Claude-Design-Skill) sollte daraus ohne Rückfragen einen ersten visuellen Entwurf bauen können.

| | |
|---|---|
| **Produkt** | Geburtstage & Geschenkideen (iOS App, App Store ID 6760319397) |
| **Ziel-Domain** | `gifts.gruepi.de` (Subdomain-Vorschlag, alternativ `presents.gruepi.de` oder `birthday.gruepi.de`) |
| **Zielgruppe** | 30+ deutschsprachige Privatnutzer, die viele Geburtstage tracken (Familie, Freunde, Kollegen). Kein Tech-Bro-Publikum. |
| **Kern-Job-to-be-done** | „Ich will keinen Geburtstag mehr vergessen — und beim nächsten passenden Geschenk nicht jedes Mal von vorn nachdenken." |
| **Sprachen** | Primär Deutsch. Englisch als zweite Locale (App ist mehrsprachig: en, de, es, fr). |
| **Konversionsziel** | App Store Download. Sekundär: TestFlight-Beta-Anmeldung. |

---

## 1. Tonalität & Positionierung

### Was die Site NICHT sein soll

- Kein „Lifestyle-App"-Bunt. Keine Konfetti-Stockfotos.
- Keine KI-Hype-Sprache („revolutionary", „AI-powered" als Buzzword im Hero).
- Keine künstliche Knappheit, keine Urgency-Banner, kein Email-Capture-Modal.
- Keine Vergleichstabelle gegen No-Name-Konkurrenz (wirkt billig).

### Was die Site sein soll

- **Ruhig, präzise, geschmackvoll** — wie ein gutes Schweizer Notizbuch oder ein deutsches Premium-Werkzeug.
- **Selbstbewusst ohne Lautstärke**: Die App löst ein nervendes Mini-Problem ohne Drama — die Site darf das gleiche Versprechen ausstrahlen.
- **Datenschutz als Verkaufsargument**, nicht als Footer-Pflicht. Spielt direkt auf die Sorge „KI mag meine Daten" an, die viele Käufer haben.
- **Indie-Maker-Feel** statt Konzern-Marketing. Hendrik Grüger / Grüpi GmbH ist eine echte Person, das soll spürbar sein.

### Markenversprechen in einem Satz

> „Du vergisst keinen Geburtstag mehr. Und keine Geschenkidee."

(Optionaler Substitle: „Privat, sortiert, mit unaufdringlicher KI-Hilfe.")

---

## 2. Visueller Stil — Empfehlung „Quiet Editorial"

Mood-Referenzen (zur Orientierung für Designer):
- **Linear.app** (Strukturierung, Typografie-Hierarchie)
- **Vercel.com** (Whitespace, schwarz-weiß + ein Akzent)
- **Things 3** (Cultured Code, ruhige Persönlichkeit)
- **Notion's Frontpage** (klare Sections, ehrliche Screenshots)

### Farb-System

Aus der App übernehmen, leicht reduziert für Web:

| Token | Hex (ungefähr, aus AppColor.swift bestätigen) | Verwendung |
|---|---|---|
| Background | `#FAFAF7` (warmer Off-White) | Body |
| Surface | `#FFFFFF` | Cards |
| Foreground | `#0E0E10` | Primärtext |
| Muted | `#6B6B6B` | Sekundärtext |
| Border | `#E8E6E0` | Trennlinien |
| Accent | `AppColor.accent` aus der App (lila/violett, exakter Wert in `Color+DocAI.swift` bzw. `AppColor`) | CTAs, Highlights |
| Danger | `AppColor.danger` | nur für Privacy-Schaltsymbole |

**Regel:** Akzentfarbe maximal 1× pro Sektion. Kein zweites Farbsystem.

### Typografie

| Stil | Empfehlung | Begründung |
|---|---|---|
| Display / Hero | **Söhne** oder **Inter Display** in 96–120 px, semibold | Modern, vertrauensbildend, deutsch tauglich |
| Body | **Inter** 17–18 px / line-height 1.6 | Lesbarkeit, neutral |
| Mono (für Tech-Transparenz-Block) | **JetBrains Mono** | konsistent zur Dev-Welt |
| Akzidenz-Serif (sparsam) | **Tiempos Headline** o. ä. — nur für 1 Pull-Quote pro Page | Editorial-Feel |

### Layout-Grid

12-col, max-width 1200 px, aber: Hero und Demo-Sektionen dürfen **fullbleed** sein. Mobile-First — die Site muss vor allem auf dem iPhone gut aussehen, weil viele Visitors direkt vom App Store Link aus dort landen.

### Animation

- **Pinned-Scroll**: Im Hero scrollt ein iPhone-Mockup synchron zum Page-Scroll (Stats → Liste → KI-Chat → Widget). Tool: GSAP ScrollTrigger oder Framer Motion `useScroll`.
- **Sanfte Fade-Up-Reveals** für Sections (max. 12 px Translate-Y, 300 ms ease-out). Keine Bouncing- oder Springs.
- **Keine Auto-Play-Videos** im Hero. Nur ein animiertes iPhone, das beim Scroll reagiert.

---

## 3. Sektions-Architektur (One-Pager, Long-Scroll)

### S1 — Hero (above-fold)

- **H1**: „Du vergisst keinen Geburtstag mehr. Und keine Geschenkidee."
- **Sub**: Ein Satz, was die App tut. Beispiel: „Eine ruhige iOS-App für Familie, Freunde und Kollegen — mit Widget, KI-Vorschlägen und ehrlichem Datenschutz."
- **CTAs**:
  - Primär: Apple-Standard „Download on the App Store"-Badge (offizielles Asset)
  - Sekundär: kleiner QR-Code daneben (mobile Visitors sind eh am Phone, Desktop-Visitors scannen)
  - Kein „Try Free"-Button, weil die App komplett gratis ist
- **Visuell**: iPhone 17 Pro Mockup rechts, das die Timeline mit Stats-Section zeigt. Beim Scroll wechselt das Mockup-Inhalt synchron.
- **Trust-Mini-Bar darunter**: 3 kleine Icons + Text: „🇩🇪 Made in Münster · 🔒 DSGVO-konform · ⭐ Kein Tracking"

### S2 — „Wofür eigentlich?" (3 Cards)

Drei gleichwertige Cards, je mit einem **Mini-Demo-Visual** (kein generisches Icon):

1. **Erinnern** — Widget-Mockup zeigt nächste 7 Tage, Untertitel: „Heute, in 3 Tagen, in 9 Tagen — direkt auf dem Lockscreen."
2. **Vorschlagen** — Chat-Bubble-Mockup mit echtem Vorschlag: „Stefan, 35, liest gern Sci-Fi → Kindle Paperwhite, ca. 169 €." Untertitel: „Anonymisierte KI-Hilfe — nur wenn Du sie aktivierst."
3. **Tracken** — Listen-Mockup mit 3 historischen Geschenken. Untertitel: „Wer hat letztes Jahr was bekommen? Damit Du Dich nicht wiederholst."

### S3 — Datenschutz als Verkaufsargument (prominent, nicht versteckt)

- **H2**: „Deine Kontaktdaten bleiben Deine."
- Drei klare Bullets:
  1. **Was übertragen wird**: Vornamen + anonymisierte Eckdaten (Altersgruppe, Geschlecht) — nur wenn Du KI aktivierst.
  2. **Was nie übertragen wird**: Nachnamen, Geburtsdaten, Notizen, Telefonnummern.
  3. **Was passiert nach der Anfrage**: Nichts. Zero Data Retention bei OpenRouter und Google.
- **Mini-Box**: „Datenweg: Deine App → Cloudflare Worker (Münster) → OpenRouter (USA) → Google Gemini. Auf Basis von Standardvertragsklauseln (Art. 46 DSGVO)."
- **Klein**: „Voller Privacy-Text" → Link zur PRIVACY.md

> **Designhinweis:** Diese Sektion explizit als visuelles Schwergewicht — sie ist Wettbewerbsvorteil. Etwa 25 % der Page-Höhe.

### S4 — Die kleine Wahrheit über KI

- **H2**: „Wir nutzen Gemini 3.1 Flash Lite via OpenRouter."
- Tech-Transparenz-Block, monospaced. Beispiel:
  ```
  Modell:        Google Gemini 3.1 Flash Lite
  Anbieter:      OpenRouter (USA), Zero Data Retention
  Proxy:         Cloudflare Workers (EU)
  Kosten:        Wir tragen sie. Du nicht.
  Aktivierung:   Opt-in, jederzeit widerrufbar.
  ```
- Ein Satz dazu: „Wir machen das transparent, weil uns Apples Privacy Review und Dein Vertrauen wichtig sind."

> **Differentiator:** Niemand sonst in der Geschenke-App-Kategorie ist auf seiner Marketingseite so konkret. Das verkauft.

### S5 — Widget-Showcase

- iPhone-Lockscreen-Mockup mit **echten** Medium- und Large-Widget-Renders.
- 3 schmale Sub-Cards: „Mini" (nur nächster Geburtstag), „Medium" (3 Tage), „Large" (7 Tage).
- Untertitel: „Tipp aufs Widget = Direkt zum richtigen Kontakt."

### S6 — iPad + Mehrsprachig

- Split-View-Mockup auf iPad-Pro-13-inch.
- Daneben kurzer Absatz: „Auch fürs iPad — Master-Detail-Layout in allen 4 Orientierungen. Verfügbar auf Deutsch, Englisch, Spanisch und Französisch."

### S7 — Pricing

- **H2**: „Kostet Dich nichts. Aktuell."
- Ein Absatz, ehrlich: „Die App ist gratis. Wir entwickeln sie weiter — Premium-Optionen für Power-User kommen, frühe Nutzer behalten ihren Zugang. Werbung gibt es nie."

### S8 — Wer macht das? (Indie-Trust)

- Foto Hendrik (oder stilisiertes Portrait, falls kein Foto-Wunsch)
- Block: „Hendrik Grüger, Grüpi GmbH, Münster. Ich nutze die App selbst täglich für ~80 Kontakte — sie löst ein Problem, das ich hatte. Wenn etwas nervt, schreib mir: [hello@gruepi.de](mailto:hello@gruepi.de)."
- Drei Mini-Links: LinkedIn, Mail, optional GitHub

### S9 — FAQ (8–10, ehrlich)

Vorschlag-Items:
- „Brauche ich iCloud?"
- „Was wenn ich keinen iCloud-Account habe?"
- „Wird mein Gemini-Quota verbraucht?"
- „Kann ich die App auch ohne KI nutzen?"
- „Sehe ich vergangene Geschenke ab wann?"
- „Funktioniert das Widget auf älteren iPhones?"
- „Kann ich Kontakte aus dem iOS-Adressbuch importieren?"
- „Wann kommt eine Android-Version?"  → Antwort: aktuell nicht geplant, Apple-only
- „Kostet es wirklich nichts?"
- „Was passiert, wenn ich die App lösche?"  → SwiftData lokal weg, iCloud-Sync bleibt 30 Tage erhalten

Accordion-Style, alle by default zu.

### S10 — Footer

Drei Spalten:
1. **Produkt**: App Store, Privacy, Terms, Changelog
2. **Unternehmen**: Impressum (Grüpi GmbH), Kontakt, Support
3. **Sprache-Switcher**: DE / EN

Ganz unten: Copyright, „Made in Münster, Germany" mit kleinem ❤️.

---

## 4. Pflicht-Inhalte (rechtlich, nicht weglassen)

- **Impressum** als eigene Seite (TMG-Pflicht). Aktuelle Daten in `docs/PRIVACY.md` und ASC-Eintrag prüfen.
- **Datenschutzerklärung** als eigene Seite. Vorhandener Volltext: `docs/PRIVACY.md` (DE) und `docs/PRIVACY_EN.md` (EN). Übernehmen, evtl. visuell aufbereiten.
- **Cookie-Banner**: Nur wenn analytisch ein Tool eingesetzt wird, das das erfordert. Wenn Plausible/Cabin (cookie-frei) → Banner kann entfallen.
- **App Store Badge**: Apple-Brand-Guidelines beachten — nur das offizielle Asset, korrekte Mindestgröße.

---

## 5. Tech-Stack-Empfehlung

| Layer | Tool | Begründung |
|---|---|---|
| **Framework** | **Astro 5+** | Statisches HTML-Output, beste SEO, Islands-Architektur für selektive Interaktivität |
| **Styling** | **Tailwind CSS 4** + Custom Tokens aus App-Color-System | Konsistent zur App-Dev-Erfahrung |
| **Animation** | **GSAP ScrollTrigger** für Pinned-Scroll-Mockup, **Framer Motion** für Reveals (falls React-Islands) | Beide Industry-Standard |
| **iPhone-Mockups** | Statische `.png` aus echten Simulator-Screenshots, `react-iphone-mockup` für Frame, Lottie für Animationen | Realismus + Performance |
| **Hosting** | **Cloudflare Pages** | Hendrik nutzt schon Cloudflare Workers für den App-AI-Proxy → konsistente Infrastruktur, kostenlos |
| **Domain** | `gifts.gruepi.de` (Subdomain via Cloudflare DNS) | Klare Trennung von Hauptseite, eigener Build |
| **Analytics** | **Plausible** (self-hosted oder Cloud) | DSGVO-konform, cookie-frei — passt zur Datenschutz-Botschaft |
| **Form** | Cloudflare Worker + Resend für Support-Mails | Kein zusätzlicher Service, eine Infrastruktur |
| **CI** | GitHub Actions → Cloudflare Pages Deploy bei Push auf `main` | Standard |

### Performance-Ziel

- **Lighthouse 100 / 100 / 100 / 100** auf der Hero-Page (Mobile)
- **LCP < 1.8 s**, kein Layout Shift im Hero
- **Total Bundle**: < 100 KB JS gzipped
- **Image-Format**: AVIF + WebP-Fallback, alle Mockups mit `<picture>` und korrektem `srcset`

---

## 6. Inhalts-Quellen (vorhandenes Material wiederverwenden)

| Was | Wo |
|---|---|
| App-Store-Listing-Texte | `docs/APP-STORE-LISTING.md` |
| Privacy-Volltext | `docs/PRIVACY.md`, `docs/PRIVACY_EN.md` |
| Terms | `docs/TERMS.md`, `docs/TERMS_EN.md` |
| What's-New | `docs/WHATS-NEW-1.0.md` |
| Architektur (für FAQ-Antworten) | `docs/ARCHITECTURE.md` |
| Roadmap-Hinweise | `docs/ROADMAP.md` |
| Bisherige Startseiten-Idee | `docs/plan-startseite-redesign.md` (falls relevant) |

**Designer-Auftrag:** Diese Texte sichten, wo sie passen 1:1 nutzen, sonst kürzen — nicht neu erfinden.

---

## 7. Screenshots & Visuals — was zu liefern ist

Aus dem iOS-Simulator (iPhone 17 Pro, light + dark mode):

1. **Timeline-Hauptansicht** mit Stats-Section + 6–8 Geburtstagen (echte Demo-Daten, keine Lorem-Ipsum-Namen — Hendrik's `SampleDataService.swift` gibt sich Mühe mit echten deutschen Namen)
2. **KI-Chat-Empty-State** mit den 4 Welcome-Chips (siehe Screenshot vom 2026-05-01)
3. **KI-Chat mit Beispiel-Konversation** (1 User-Frage + 1 KI-Antwort mit echtem Vorschlag)
4. **Person-Detail-View** mit 2–3 historischen Geschenken
5. **Widget-Renders**: Medium und Large auf iOS 26 Lockscreen (Privacy-Mode + normaler Mode)
6. **Settings-Screen** mit aktivem KI-Toggle (zeigt den korrigierten Datenschutz-Text)
7. **iPad Split-View** Quer- und Hochformat

**Lieferform:** PNG, 3x retina, transparenter Hintergrund optional. Quellpfad: `docs/screenshots/website/`.

---

## 8. Domain-Frage (zu klären)

Optionen für die Subdomain:
- `gifts.gruepi.de` — kurz, direkt, englisch (passt zum App-Namen „Birthday Calendar Gifts")
- `presents.gruepi.de` — englisch, präsenter aber länger
- `birthday.gruepi.de` — beschreibt nur halben Use-Case
- `geburtstage.gruepi.de` — deutsch, lang, weniger international
- `gruepi.de/birthday` — kein eigenes Subdomain, im Hauptauftritt eingebettet

**Empfehlung: `gifts.gruepi.de`** — kurz, semantisch nah am App-Namen, eigener Build-Scope getrennt von der Haupt-Gruepi-Site.

---

## 9. Open Questions für Hendrik (Designer-Briefing)

1. **Mood**: „Quiet Editorial" (a) wie hier vorgeschlagen, oder lieber „Warm Anti-Tech" (Things-3-haft, sandfarben, weicher) oder „Bold Statement" (Apple-Marketing-Stil, große Hero-Type)?
2. **Eigenes Foto in S8 oder stilisiertes Portrait/Avatar**?
3. **iPhone-Mockup-Stil**: realistisches Hardware-Frame, oder abstrahiert (nur Screen, kein Frame)?
4. **Soll die Site selbst auch Light/Dark-Mode unterstützen** (Toggle), oder nur Light?
5. **Zweisprachigkeit jetzt oder später**: erst nur DE und später EN, oder direkt beide Locales bauen?
6. **Domain-Endgültig**: `gifts.gruepi.de` ok?
7. **Ob ein Newsletter-Opt-In** in den Footer (z. B. „Sag mir Bescheid wenn neue Features kommen") eingebaut werden soll. Eher nein — passt zur Anti-Marketing-Tonalität.

---

## 10. Erfolgs-Definition

| Metrik | Ziel (3 Monate nach Launch) |
|---|---|
| Lighthouse Performance | 100 / 100 / 100 / 100 (Mobile + Desktop) |
| Indexierung | Site rankt für „Geburtstage App iOS" und „Geschenkideen App" auf S. 1 deutscher Google-Resultate |
| App Store CTR (Site → Store) | > 8 % der Page-Visitors klicken den App-Store-Badge |
| TestFlight-Anmeldungen | nur ein eher unverbindliches Ziel — primär ist der App Store |
| Datenschutz-Sektion-Engagement | > 60 % der Visitors scrollen mindestens bis Sektion S3 |

---

## 11. Nächste Schritte (ab grünem Licht)

1. **Designer / `frontend-design`-Skill aktivieren** mit diesem Brief als Input + Mood-Wahl beantwortet
2. Erste **3 Hi-Fi-Mockups** (Hero, Datenschutz-Sektion, FAQ) als statische PNG/Figma — 1 Iteration mit Hendrik
3. **Astro-Skelett** im Repo `~/Coding/1_privat/Websites/gruepi-de-presents-app/` (oder im Monorepo unter `web/`)
4. **Hero + S2 + S3** als erste live deploybare Version auf `gifts.gruepi.de`
5. **Iterativ S4–S10** ergänzen, jeweils mit kurzem Hendrik-Review

Erste live-deploybare Version realistisch in **2–3 Sessions à 90 Min**, vollständig polierter Stand in **5–6 Sessions**.

---

*Dieses Dokument ist die Single Source of Truth für die Marketing-Site. Bei Designentscheidungen, die hier nicht abgedeckt sind, gilt: im Zweifel ruhiger, kürzer, ehrlicher als der Default.*
