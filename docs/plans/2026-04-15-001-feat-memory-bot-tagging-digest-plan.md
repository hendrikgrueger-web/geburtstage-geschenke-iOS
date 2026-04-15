---
title: "feat: Memory Bot — Strukturiertes Tagging + Nacht-Digest"
type: feat
status: completed
date: 2026-04-15
context: n8n Memory Bot (Supabase yvoislpxkmwhgmltzfin · Workflows MRBkC0coE9x28JA1 + Q4Dgh8iiJc8WAakF)
---

# feat: Memory Bot — Strukturiertes Tagging + Nacht-Digest

## Overview

Memories werden aktuell als flache Einträge ohne Struktur gespeichert. Zwei Ergänzungen:

1. **Real-Time-Tagging**: Das Answer-LLM erzeugt bei jeder Antwort 2–4 semantische Tags (inline, kein Extra-Aufruf).
2. **Nacht-Digest**: Ein täglicher n8n-Job (02:00 Uhr Berlin) lässt Claude alle Memories analysieren — erkennt Muster, verdichtet Bereiche, findet Querverbindungen — und schreibt das Ergebnis in `claude_memory_index`.

Das sind zwei unabhängige Verbesserungsebenen: Tags machen einzelne Einträge durchsuchbar, der Digest macht das Gesamtbild lesbar.

## Problem Frame

- `claude_memory` hat: `name`, `description`, `type`, `content`, `source` — kein semantisches Clustering, kein Bereichs-Bezug
- Die Fragengenerierung nutzt nur die letzten 5 Fragen als Kontext — hat kein Bild vom Gesamtstand
- Beim Wachstum auf 100+ Entries gibt es keine Möglichkeit, "was weißt du über meine Arbeit?" zu beantworten
- Ein Nacht-Job mit vollem Kontext kann tiefer analysieren als das Echtzeit-LLM beim Speichern

## Requirements

- R1: Jeder neue Memory-Eintrag bekommt 2–4 Freitext-Tags (LLM-generiert, inline beim Speichern)
- R2: `claude_memory` hat ein `tags text[]`-Feld und ein `category text`-Feld
- R3: Ein täglicher n8n-Workflow ("Memory Nacht-Digest") läuft um 02:00 Berlin
- R4: Der Digest liest alle Memories (mit Pagination), schickt sie an Claude, speichert strukturierte Analyse
- R5: `claude_memory_index` Tabelle speichert den Digest als JSONB + Metadaten
- R6: Die Fragengenerierung kann optional den letzten Digest als Zusatz-Kontext nutzen (nicht blockierend)

## Scope Boundaries

- Kein Frontend/UI zum Browsen der Memories (separate Aufgabe)
- Kein Echtzeit-Vollkontext-Analyse beim Speichern (zu teuer)
- Kein Bearbeiten alter Digests (append-only)
- Kein automatisches Löschen von Duplicate-Memories (kann später kommen)
- Tags sind nicht iCloud-synced oder extern sichtbar — nur Supabase-intern

## Kontext & Patterns

### Bestehende Infrastruktur

| Komponente | Details |
|---|---|
| Supabase URL | `https://yvoislpxkmwhgmltzfin.supabase.co/rest/v1/` |
| Supabase Credential | n8n-ID `hxTemGKuTtemTmSx` (supabaseApi) |
| Answer Workflow | `Q4Dgh8iiJc8WAakF` — 26 Nodes, aktiv |
| OpenRouter Credential | `O1DsfKu851ea2NbP` (httpHeaderAuth) |
| LLM aktuell | `qwen/qwen3.6-plus`, temperature 0.3 |
| `claude_memory` Felder | `name`, `description`, `type`, `content`, `source`, `created_at`, `id` |
| `claude_questions` Felder | `id`, `question`, `category`, `priority`, `status`, `asked_at` |

### Patterns zu folgen

- HTTP-Request-Nodes (Supabase): `predefinedCredentialType: supabaseApi`, `Prefer: return=minimal|representation`
- Code-Nodes: `jsCode`-Feld, Expression-Mode für jsonBody (`={}`)
- LLM-Calls: HTTP Request → OpenRouter, `genericCredentialType`/`httpHeaderAuth`, JSON Body mit `=`-Prefix
- Parse LLM Response: 4-Stage robust JSON extractor (bereits in Answer Workflow vorhanden)
- Schedule Trigger: Cron-Expression in n8n (`0 1 * * *` für 02:00 Berlin / 01:00 UTC)

## Technische Entscheidungen

- **Tags inline, kein Extra-LLM-Call**: Tags werden im gleichen LLM-Response-Schema zurückgegeben. Kein Extra-Kosten-Risiko, keine Latenz.
- **Category in Memory speichern** (zusätzlich zu Tags): Die Fragen-Kategorie ist semantisch verwandt mit der Antwort; nützlich für Digest-Gruppierung. Wird vom LLM als `memory.category` mitgegeben.
- **Digest als JSONB-Blob** (nicht normalisiert): Das Digest-Schema wird sich weiterentwickeln. JSONB ist flexibel ohne Schema-Migrationen bei jeder Änderung. Metadaten (Zeitraum, Anzahl) bleiben als Top-Level-Spalten.
- **Digest-Modell**: `google/gemini-3.1-flash-lite-preview` via OpenRouter — 1M Kontext, günstig, gut für strukturierte Analyse. Separate Entscheidung vom Answer-LLM.
- **Pagination**: Digest liest max. 500 Memories (reicht für ~1 Jahr). Bei Überschreitung → letzten Digest als rollierenden Kontext nutzen.
- **R6 optional**: Letzter Digest in `Prepare LLM Body` einbinden ist Low-Risk-Add; kann nach Unit 3 ergänzt werden ohne blockierende Abhängigkeit.

## Open Questions

### Resolved

- **Welche Tags-Granularität?** → Freitext (2–4 Stk.), nicht aus einem fixen Vokabular. LLM wählt selbst. Einfacher und flexibler.
- **Digest täglich oder wöchentlich?** → Täglich; bei wenigen neuen Memories (< 2) überspringt der Job einfach (IF-Node).
- **Welche Bereiche im Digest?** → LLM entscheidet selbst welche Bereiche relevant sind; kein hartes Schema.

### Deferred to Implementation

- Ob `tags`-Spalte als `text[]` oder `jsonb` angelegt wird — kommt auf Supabase-Typ-Support an; `text[]` bevorzugt
- Exakte SQL-Migration-Syntax (Supabase nutzt PostgreSQL; `ALTER TABLE ADD COLUMN tags text[] DEFAULT '{}'`)
- Ob Digest bei 0 neuen Memories überspringt oder trotzdem läuft (Implementierungs-Entscheidung)

---

## High-Level Technical Design

> *Richtungsweisende Skizze — kein Code zum Kopieren.*

```
┌─────────────────────────────────────────────────────────┐
│  ANSWER WORKFLOW (Q4Dgh8iiJc8WAakF) — Änderungen        │
│                                                          │
│  Prepare LLM Body                                        │
│  → Schema erweitert um:                                  │
│    "tags": ["tag1", "tag2", ...],  // 2-4 Stk           │
│    "memory.category": "Arbeit|Familie|..."               │
│                                                          │
│  Insert claude_memory (qa + adhoc)                       │
│  → jsonBody erweitert um: tags, category                 │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  NACHT-DIGEST WORKFLOW (neu)                             │
│                                                          │
│  Schedule (01:00 UTC)                                    │
│  → GET claude_memory (alle, limit 500, desc)             │
│  → Code: Prompt bauen + Memories serialisieren           │
│  → HTTP: OpenRouter (gemini-2.0-flash)                   │
│  → Code: LLM-Response parsen (JSON extractor)            │
│  → IF: Ergebnis valide?                                  │
│  → POST claude_memory_index (upsert)                     │
│  → Telegram: Digest-Summary an Hendrik (optional)        │
└─────────────────────────────────────────────────────────┘

claude_memory_index Schema:
{
  id, created_at, period_start, period_end,
  memory_count: integer,
  model_used: text,
  analysis: jsonb {
    areas: { Arbeit: {summary, key_points[]}, ... }
    patterns: [{ label, description, evidence_count }]
    cross_connections: [{ topic_a, topic_b, relation }]
    unexplored_gaps: string[]
    overall_impression: string
  }
}
```

---

## Implementation Units

- [ ] **Unit 1: Supabase Schema erweitern**

**Goal:** `claude_memory` bekommt `tags text[]` und `category text`; neue Tabelle `claude_memory_index` anlegen.

**Requirements:** R2, R5

**Dependencies:** Keine

**Files:**
- Supabase SQL Editor (kein lokales File — SQL direkt in Supabase ausführen)

**Approach:**
- `ALTER TABLE claude_memory ADD COLUMN tags text[] DEFAULT '{}'`
- `ALTER TABLE claude_memory ADD COLUMN category text`
- `claude_memory_index` anlegen als neue Tabelle mit Spalten: `id uuid DEFAULT gen_random_uuid() PRIMARY KEY`, `created_at timestamptz DEFAULT now()`, `period_start timestamptz`, `period_end timestamptz`, `memory_count integer`, `model_used text`, `analysis jsonb`
- Row Level Security analog zu bestehenden Tabellen konfigurieren (falls aktiv)

**Test scenarios:**
- INSERT in claude_memory mit tags-Array funktioniert
- SELECT `tags @> ARRAY['Bitcoin']` gibt korrekte Treffer zurück
- claude_memory_index nimmt JSONB-Objekte beliebiger Tiefe an

**Verification:**
- Supabase Table Editor zeigt beide neuen Spalten
- Ein Test-Insert mit `tags: ['test', 'plan']` wird ohne Fehler gespeichert

---

- [ ] **Unit 2: Answer Workflow — Tags + Category im LLM-Schema**

**Goal:** Das LLM gibt bei jeder Antwort `tags[]` und `memory.category` zurück; beides wird in Supabase gespeichert.

**Requirements:** R1, R2

**Dependencies:** Unit 1 (Spalten müssen existieren)

**Files:**
- n8n Workflow `Q4Dgh8iiJc8WAakF` → Node `Prepare LLM Body` (jsCode)
- n8n Workflow `Q4Dgh8iiJc8WAakF` → Node `Parse LLM Response` (jsCode)
- n8n Workflow `Q4Dgh8iiJc8WAakF` → Nodes `Insert claude_memory (qa)` + `(adhoc)` (jsonBody)

**Approach:**
- In `Prepare LLM Body`: JSON-Schema um `"tags": ["string (2–4 prägnante Schlagworte)"]` und `"memory.category"` erweitern; Few-Shot-Beispiele ergänzen, die Tags zeigen
- In `Parse LLM Response`: `tags` und `category` aus LLM-Output extrahieren + auf `llm.memory` setzen; Fallback: leeres Array / null
- In `Insert claude_memory`: `"tags": {{ JSON.stringify($json.llm.memory.tags || []) }}, "category": {{ JSON.stringify($json.llm.memory.category || null) }}`

**Patterns to follow:**
- Bestehende `Parse LLM Response` 4-Stage JSON extractor
- `Insert new question` jsonBody Pattern (Expression-Mode)

**Test scenarios:**
- Antwort senden → LLM gibt `tags: ["Kraftsport", "Longevity"]` zurück
- Supabase-Eintrag hat gefülltes `tags`-Array
- LLM gibt kein `tags`-Feld zurück → Fallback `[]` verhindert Insert-Fehler

**Verification:**
- 2–3 Testantworten in Telegram schicken
- Supabase `SELECT tags, category FROM claude_memory ORDER BY created_at DESC LIMIT 5` zeigt befüllte Felder

---

- [ ] **Unit 3: Nacht-Digest Workflow bauen**

**Goal:** Neuer n8n-Workflow "Memory Nacht-Digest" läuft täglich 01:00 UTC, liest alle Memories, lässt Claude analysieren, speichert Ergebnis in `claude_memory_index`.

**Requirements:** R3, R4, R5

**Dependencies:** Unit 1 (claude_memory_index-Tabelle)

**Files:**
- Neuer n8n-Workflow (via PUT /api/v1/workflows) — "Memory Nacht-Digest"

**Approach (Node-Reihenfolge):**
1. `Schedule Trigger` — Cron `0 1 * * *` (01:00 UTC = 02:00/03:00 Berlin)
2. `GET claude_memory` — Supabase HTTP, alle Einträge, `order=created_at.desc`, `limit=500`
3. `IF: Memories vorhanden?` — `$json.length > 0`; sonst End
4. `Build Digest Prompt` (Code Node) — serialisiert Memories als kompaktes JSON, baut System-Prompt mit Analyseanweisung (Bereiche, Muster, Querverbindungen, Lücken)
5. `LLM: Analyze Memories` (HTTP Request) — OpenRouter, `google/gemini-3.1-flash-lite-preview`, temperature 0.2, 1M context
6. `Parse Digest Response` (Code Node) — 4-Stage JSON extractor (analog Parse LLM Response)
7. `Insert claude_memory_index` — Supabase POST mit `period_start/end`, `memory_count`, `model_used`, `analysis`
8. `Telegram: Digest Summary` (optional) — kurze Zusammenfassung an Hendrik (Chat-ID 6740845735)

**Digest-Prompt-Inhalt:**
- Kontext: "Du analysierst Hendriks persönliches Memory-System"
- Task: Bereiche zusammenfassen, Muster erkennen, Querverbindungen finden, Lücken aufzeigen
- Format: Valides JSON ohne Markdown, Schema wie in High-Level Design
- Instruction: "Erkunde auch was NICHT vorkommt — welche Lebensbereiche fehlen noch?"

**Patterns to follow:**
- `Prepare LLM Body` + `LLM: Process Answer` aus Answer Workflow
- Supabase Insert aus bestehenden Nodes

**Test scenarios:**
- Workflow manuell triggern → LLM gibt valides JSON zurück
- `claude_memory_index` hat einen neuen Eintrag
- Bei 0 Memories (leere DB) → Workflow endet gracefully ohne Fehler
- LLM gibt kein valides JSON → Parse-Fallback schreibt raw_output, kein Crash

**Verification:**
- Manueller Trigger → Supabase-Eintrag in `claude_memory_index` mit befülltem `analysis`-JSONB
- Telegram-Nachricht kommt an (falls aktiviert)
- Nächsten Morgen: automatischer Run in Workflow-History sichtbar

---

- [ ] **Unit 4 (optional): Fragengenerierung nutzt letzten Digest als Kontext**

**Goal:** `Prepare LLM Body` im Answer Workflow holt den letzten `claude_memory_index`-Eintrag und gibt ihn als Zusatz-Kontext ans Fragen-LLM weiter — bessere Diversität und Tiefe der nächsten Frage.

**Requirements:** R6

**Dependencies:** Unit 1, 2, 3 (Digest muss mindestens einmal gelaufen sein)

**Files:**
- n8n Workflow `Q4Dgh8iiJc8WAakF` → neuer Node `Get Latest Digest` (HTTP Request, Supabase)
- n8n Workflow `Q4Dgh8iiJc8WAakF` → Node `Prepare LLM Body` (System-Prompt-Erweiterung)
- Connections: `Assemble context` → `Get Latest Digest` → `Get recent questions` → `Prepare LLM Body`

**Approach:**
- GET `claude_memory_index?order=created_at.desc&limit=1` → liefert letzten Digest
- In `Prepare LLM Body`: wenn Digest vorhanden, ergänze System-Prompt um `"Wissensstand-Zusammenfassung:\n[areas.summary pro Bereich]"`
- LLM kann gezielt Lücken aus `unexplored_gaps` aufgreifen
- Fallback: kein Digest → Prompt wie bisher

**Test scenarios:**
- Nach erstem Digest: neue Antwort → Frage geht in einen bisher ungefragten Bereich
- Digest nicht vorhanden → Workflow läuft ohne Fehler

**Verification:**
- Fragen adressieren erkannte Lücken aus dem Digest
- Kein Fehler wenn `claude_memory_index` leer ist

---

## System-Wide Impact

- **Supabase Schema**: Zwei Änderungen an bestehender Tabelle (backward-compatible: DEFAULT-Werte für `tags`/`category`)
- **Answer Workflow Latenz**: Tags werden inline generiert — da sie Teil desselben LLM-Calls sind, keine Mehrlatenz
- **Digest-Kosten**: ~500 Memories × ~200 Tokens = ~100K Input + ~2K Output ≈ $0.01/Tag bei gemini-2.0-flash
- **Fehlerfall Digest**: Kein Einfluss auf den Answer Workflow; Digest ist ein eigenständiger Job

## Risiken

- **LLM gibt kein `tags`-Feld zurück** → Parse-Fallback auf `[]` nötig; verhindert Insert-Fehler
- **gemini-3.1-flash-lite-preview** ist ein Preview-Modell — könnte sich ändern. Alternative: `qwen/qwen3.6-plus` als Fallback
- **500-Memory-Limit**: Reicht für ~6–18 Monate je nach Nutzungsfrequenz. Danach: rollierende Fenster oder Digest-auf-Digest
- **Supabase `text[]` Syntax** in n8n jsonBody: `JSON.stringify(array)` erzeugt `["a","b"]` — PostgreSQL versteht das mit `Content-Type: application/json` korrekt

## Sequenz

Unit 1 → Unit 2 → Unit 3 → (Unit 4 optional, jederzeit nachziehbar)

Unit 1 und 2 können theoretisch parallel starten, aber Unit 2 schreibt in die neuen Spalten — sicherer: erst Unit 1 fertigstellen und testen.

## Sources & References

- Answer Workflow: `Q4Dgh8iiJc8WAakF` (n8n.gruepi.de)
- Ask Workflow: `MRBkC0coE9x28JA1`
- Supabase Projekt: `yvoislpxkmwhgmltzfin`
- Credential Supabase: `hxTemGKuTtemTmSx` (supabaseApi)
- Credential OpenRouter: `O1DsfKu851ea2NbP` (httpHeaderAuth)
- Aktuelles LLM: `qwen/qwen3.6-plus`
- Digest LLM: `google/gemini-3.1-flash-lite-preview` (OpenRouter)
