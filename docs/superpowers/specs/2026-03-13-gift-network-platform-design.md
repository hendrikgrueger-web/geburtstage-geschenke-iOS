# Design Spec: Gift Network Platform

> Erstellt: 2026-03-13 | Ziel: €20.000/Monat Umsatz

---

## 1. Vision

Die App transformiert sich von einer persönlichen Geschenke-Verwaltung zu einer **sozialen Geschenke-Plattform** — dem "Splitwise für Geschenke". Jeder Nutzer profitiert davon, dass Freunde und Familie die App ebenfalls nutzen. Das erzeugt Netzwerkeffekte und virales Wachstum.

**Kern-Einsicht:** Geschenke sind inhärent sozial — Schenker und Beschenkter existieren immer als Paar. Die aktuelle App bildet nur eine Seite ab (Schenker). Indem wir die andere Seite einbinden (Beschenkter teilt Wünsche), verdoppeln wir die Zielgruppe und schaffen einen viralen Loop.

---

## 2. Umsatz-Modell & Unit Economics

### Ziel: €20.000/Monat

| Einnahmequelle | Anteil | Annahme |
|----------------|--------|---------|
| Premium Abo (€4,99/Mo) | €12.000 | ~2.400 Abonnenten |
| Premium Abo (€29,99/Jahr ≈ €2,50/Mo) | €5.000 | ~2.000 Jahres-Abonnenten |
| Lifetime (€14,99 einmalig) | €3.000 | ~200 Käufe/Monat |
| **Gesamt** | **€20.000** | **~4.600 zahlende Nutzer** |

### Benötigte Nutzerbasis (bei 3-5% Conversion)

| Conversion | Zahlende | Benötigte Downloads |
|------------|----------|---------------------|
| 3% | 4.600 | ~153.000 |
| 5% | 4.600 | ~92.000 |

**Zeitrahmen:** 12–18 Monate nach Launch, nicht Monat 1.

### Warum diese Zahlen realistisch sind

- **Marktgröße:** ~100M deutschsprachige Smartphone-Nutzer, jeder schenkt Geschenke
- **Saisonalität als Vorteil:** Weihnachten (Dez), Valentinstag (Feb), Muttertag (Mai) = 3 natürliche Akquisitions-Peaks pro Jahr
- **Vergleich:** Giftster (US) hat 500K+ Downloads, Wishlist.com 1M+. DACH-Markt hat keine dominante App.
- **Viral-Koeffizient:** Jeder geteilte Wunschzettel erreicht im Schnitt 3-8 Personen → k-Faktor > 1 erreichbar

---

## 3. Produkt-Phasen

### Phase 1: Foundation (v1.1) — Wochen 1-3

**Ziel:** Monetarisierung optimieren + Wunschlisten-MVP

#### 1a. Lifetime Purchase

- Neues StoreKit-2-Produkt: `com.hendrikgrueger.birthdays-presents-ai.lifetime` (€14,99)
- PaywallView erweitern: Dritte Option "Einmalig kaufen" unter den Abo-Plänen
- SubscriptionManager: `hasLifetimeAccess` Property, geprüft wie Abo-Entitlement
- App Store Connect: Produkt anlegen, Preis setzen

#### 1b. Persönliche Wunschliste (In-App)

- Neues SwiftData-Model: `WishlistItem`
  - `id: UUID`
  - `title: String` (Pflicht)
  - `url: String?` (optionaler Link zum Produkt)
  - `priceEstimate: Double?`
  - `note: String?`
  - `category: String?`
  - `isClaimed: Bool = false` (via Backend synchronisiert)
  - `createdAt: Date`
  - `sortOrder: Int`
- Neuer Tab/Section: "Meine Wünsche" — eigene Wunschliste verwalten (hinzufügen, sortieren, löschen)
- Teilen-Button: Generiert einen Short-Link (`geschenke.app/w/{shortId}`) via Supabase
- Premium-Gate: Wunschliste erstellen = Premium-Feature

#### 1c. Backend (Supabase)

Minimales Schema — drei Tabellen:

```sql
-- Wunschlisten (öffentlich lesbar via shortId)
CREATE TABLE wishlists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  short_id TEXT UNIQUE NOT NULL,
  owner_name TEXT NOT NULL,           -- Anzeigename (kein Account nötig)
  items JSONB NOT NULL DEFAULT '[]',  -- Array von {title, url, priceEstimate, note, category}
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Claims (wer kauft was)
CREATE TABLE claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wishlist_id UUID REFERENCES wishlists(id),
  item_index INT NOT NULL,            -- Index im items-Array
  claimer_name TEXT,                  -- Optional, für "Von: Max"
  claimed_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(wishlist_id, item_index)
);

-- Analytics (optional, für Wachstums-Tracking)
CREATE TABLE wishlist_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wishlist_id UUID REFERENCES wishlists(id),
  viewed_at TIMESTAMPTZ DEFAULT now(),
  referrer TEXT
);
```

- Supabase Edge Functions für: Create Wishlist, Update Wishlist, Claim Item, Get Wishlist
- RLS Policies: Wishlists lesbar für alle (via shortId), schreibbar nur für Owner (via App-Secret)
- Kein User-Account nötig — App sendet anonymes Owner-Token (UUID, lokal gespeichert)

#### 1d. Web-Share-Page

- Statische Seite auf `geschenke.app` (oder Subdomain)
- Lädt Wunschliste von Supabase via shortId
- Responsive Design (primär Mobile, da Links via iMessage/WhatsApp kommen)
- Pro Item: Titel, Preis-Indikation, "Ich kauf das!"-Button (setzt Claim)
- Geclaimed = durchgestrichen + "Wird schon besorgt ✓"
- Footer: "Erstelle deine eigene Wunschliste" → App Store Link
- **Kein Login nötig** — Claimen ist anonym (optional Name eingeben)
- Tech: Next.js auf Vercel oder einfaches HTML + Supabase JS Client

---

### Phase 2: Viraler Growth Loop (v1.2) — Wochen 4-6

**Ziel:** Jede geteilte Wunschliste bringt im Schnitt ≥1 neuen Nutzer

#### 2a. Smart Share Flow

- Nach Erstellen der Wunschliste: Native Share Sheet mit vorformulierter Nachricht
  - "Hey! Hier ist meine Wunschliste für [Anlass/meinen Geburtstag] 🎁 [Link]"
- Anlass-Auswahl: Geburtstag, Weihnachten, Valentinstag, Hochzeit, Sonstiges
- Deep Link: `geschenke.app/w/{shortId}` → Wenn App installiert: öffnet in App, sonst: Web-Page

#### 2b. Empfänger-Erlebnis optimieren

- Web-Page: Prominenter "App herunterladen"-Banner (Smart App Banner)
- In-App: Wenn jemand die App installiert und einen Wunschlisten-Link öffnet → sofort die Liste anzeigen (kein Onboarding vorher)
- "Erstelle jetzt deine eigene Wunschliste" CTA nach dem Claimen

#### 2c. Benachrichtigungen

- Push an Wunschlisten-Besitzer: "Jemand hat einen Wunsch von deiner Liste reserviert! 🎉"
- Push vor Geburtstag: "Dein Geburtstag ist in 2 Wochen — teile deine Wunschliste mit Freunden?"
- Push an Kontakte (opt-in): "[Name] hat eine Wunschliste geteilt — schau rein!"

#### 2d. KI-Wunschlisten-Assistent

- "Ich weiß nicht, was ich mir wünschen soll" → KI generiert personalisierte Vorschläge basierend auf Interessen
- Nutzt bestehende `AIService`-Infrastruktur
- Differenzierung zu jeder anderen Wunschlisten-App

---

### Phase 3: Gruppen-Features (v1.3) — Wochen 7-10

**Ziel:** Netzwerkeffekte — ganze Familien/Freundeskreise nutzen die App

#### 3a. Familien-/Freundeskreise

- "Kreis" erstellen (z.B. "Familie Müller", "Büro-Team")
- Mitglieder per Link einladen
- Alle Mitglieder sehen gegenseitig Wunschlisten + Geburtstage
- **Premium-Feature** (starker Conversion-Trigger: "Deine Familie wartet")

#### 3b. Wichteln / Secret Santa

- Kreis-Mitglieder melden sich an → automatische Ziehung
- Jeder sieht nur seinen zugewiesenen Empfänger + dessen Wünsche
- Budgetlimit festlegbar
- Saisonaler Hook: Push-Kampagne im November ("Wichteln mit deiner Familie einrichten?")
- **Premium-Feature**

#### 3c. Gruppen-Geschenke

- "Wir schenken zusammen" — eine Person schlägt ein Geschenk vor, andere treten bei
- Betrag pro Person wird angezeigt (wie Splitwise)
- Keine echte Zahlungsabwicklung — nur Koordination ("Überweise an [Organisator]")
- **Premium-Feature**

---

### Phase 4: Wachstums-Beschleunigung (v2.0) — Wochen 11-16

**Ziel:** Von organischem Wachstum zu skalierbarem Wachstum

#### 4a. Öffentliche Wunschlisten-Profile

- Optional: Nutzer macht Profil öffentlich → eigene URL (`geschenke.app/@name`)
- SEO-Traffic: "Geschenkideen für [Hobby/Person]" → Google findet öffentliche Listen
- Influencer/Creator können ihre Wunschlisten teilen

#### 4b. Affiliate-Integration (Web only)

- Auf der Web-Share-Page: "Bei Amazon kaufen" Links mit Affiliate-Tag
- Nur auf der Website, NICHT in der iOS-App (Apple Guidelines 3.1.1)
- Amazon PartnerNet: 1-10% je Kategorie
- Potential: €1.000-5.000/Monat zusätzlich bei genug Traffic

#### 4c. Anlass-basiertes Marketing

- Push-Kampagnen vor: Weihnachten (Nov), Valentinstag (Jan), Muttertag (Apr), Einschulung (Aug)
- "Teile jetzt deine Wunschliste für [Anlass]" → viraler Spike
- App Store Featuring beantragen für saisonale Events

#### 4d. Internationalisierung

- App bereits 4-sprachig (DE/EN/FR/ES) → Grundlage vorhanden
- Web-Share-Page mehrsprachig
- App Store Listings optimieren für US/UK/FR/ES Märkte
- US-Markt allein = 10x DACH-Potential

---

## 4. Technische Architektur

### Datenfluss

```
iOS App (SwiftData lokal)
    ↕ Sync beim Teilen/Aktualisieren
Supabase (Postgres + Edge Functions)
    ↕ REST API
Web-Share-Page (Vercel/Next.js)
    ↕ Smart App Banner
App Store (Download)
```

### Warum Supabase?

- Hendrik hat bereits Erfahrung + Credentials
- Free Tier: 500MB DB, 1GB Storage, 2M Edge Function Invocations/Monat
- Skaliert günstig: Pro Plan €25/Monat deckt bis ~100K MAU
- RLS (Row Level Security) → kein eigener Auth-Server nötig
- Realtime Subscriptions für Live-Updates (Claim erscheint sofort)

### Domain

- **Ideal:** `geschenke.app` oder `wunschliste.app` (prüfen ob verfügbar)
- **Fallback:** `wishlist.aipresents.app` (Subdomain der bestehenden Worker-Domain)
- **MVP:** `hendrikgrueger-web.github.io/wishlist` (GitHub Pages, kostenlos)

### Authentifizierung

- **Kein User-Account** in Phase 1-2 (Friction minimieren!)
- App generiert anonymes Owner-Token (UUID), gespeichert in Keychain
- Wunschliste ist an Token gebunden, nicht an Person
- **Optional in Phase 3:** Sign in with Apple für Kreise/Gruppen (dann nötig für Mitglieder-Zuordnung)

### Privacy / DSGVO

- Wunschlisten-Inhalte: vom Nutzer bewusst öffentlich geteilt (Art. 6 Abs. 1 lit. a)
- Claims: minimal (nur item_index + optionaler Name)
- Kein Tracking, keine Cookies auf der Web-Page
- Analytics: nur aggregiert (Anzahl Views pro Wunschliste)
- Bestehende Privacy Policy erweitern um Wunschlisten-Section

---

## 5. Metriken & Erfolgskriterien

| Metrik | Phase 1 Ziel | Phase 2 Ziel | Phase 4 Ziel |
|--------|-------------|-------------|-------------|
| MAU (Monthly Active Users) | 500 | 5.000 | 50.000 |
| Geteilte Wunschlisten/Monat | 50 | 1.000 | 10.000 |
| Claims/Monat | 100 | 5.000 | 50.000 |
| Viral-Koeffizient (k) | 0.3 | 0.8 | 1.2+ |
| Conversion Free→Premium | 3% | 4% | 5% |
| Zahlende Nutzer | 15 | 200 | 2.500 |
| MRR (Monthly Recurring Revenue) | €75 | €1.000 | €12.500 |
| Lifetime-Käufe/Monat | 5 | 50 | 200 |
| **Gesamt-Revenue/Monat** | **€150** | **€1.750** | **€15.500** |

**€20.000/Monat** erreichbar bei Phase 4 + Internationalisierung + Affiliate-Einnahmen.

---

## 6. Risiken & Mitigationen

| Risiko | Wahrscheinlichkeit | Mitigation |
|--------|-------------------|------------|
| Nutzer teilen Wunschlisten nicht | Mittel | Anlass-basierte Prompts, KI-Assistent, Incentives ("Teile 3 Listen → 1 Monat gratis") |
| Web-Page wird nicht gefunden | Hoch (anfangs) | SEO, Social Media, App Store Featuring, PR |
| Supabase-Kosten skalieren zu schnell | Niedrig | Free Tier reicht bis ~10K MAU, Pro Plan günstig |
| Apple lehnt Affiliate-Links ab | Mittel | Affiliate NUR auf Web-Page, nicht in iOS-App |
| Konkurrierende App kopiert Feature | Mittel | First-Mover im DACH-Markt, KI-Differenzierung |
| Privacy-Bedenken bei öffentlichen Listen | Niedrig | Default = privat, öffentlich nur opt-in |

---

## 7. Was sich NICHT ändert

- Bestehende Features (Timeline, Kontakte, Gift History, KI-Chat) bleiben unverändert
- SwiftData + iCloud Sync für lokale Daten bleibt
- Proxy-basierte KI-Architektur bleibt
- App bleibt iOS-only (kein Android geplant)
- Keine echte Zahlungsabwicklung (kein Splitwise-Payment)

---

## 8. Reihenfolge & Abhängigkeiten

```
Phase 1a (Lifetime) ──────────────────────► unabhängig, sofort machbar
Phase 1b (Wunschliste In-App) ─┐
Phase 1c (Supabase Backend) ───┤──► müssen zusammen funktionieren
Phase 1d (Web-Share-Page) ─────┘
Phase 2 (Viral Loop) ─────────────────────► baut auf Phase 1 auf
Phase 3 (Gruppen) ────────────────────────► baut auf Phase 2 auf, braucht Auth
Phase 4 (Wachstum) ───────────────────────► baut auf Phase 3 auf
```

Phase 1a (Lifetime Purchase) ist komplett unabhängig und kann parallel zu allem anderen laufen.
