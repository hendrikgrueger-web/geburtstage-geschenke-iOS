# Release Notes v1.0.7 (Build 139)

**Status:** in Vorbereitung — wird mit Wave 2 zusammen submitted.
**Vorgänger:** v1.0.6 (Build 137) — im Apple-Review (WAITING_FOR_REVIEW).

## Was ist neu — kurz

v1.0.7 bündelt zwei Verbesserungs-Wellen:

### Wave 1 (Build 137 → 138, schon committed)

- **Stats-Row neu gedacht** — drei Zähler beantworten jetzt „was-mache-ich-heute"-Fragen statt nur Kontaktanzahl.
- **Daten-Export** als JSON über Share-Sheet (DSGVO Art. 20: Recht auf Datenübertragbarkeit).
- **Permission-Sweeps** und kleinere Empty-State-Reassurance-Texte.
- **MerkTag-Naming-Vorbereitung** — Self-Check für Rebrand, technisch noch nicht aktiv geschaltet.

### Wave 2 (Build 138 → 139, in Umsetzung)

- **Geschenk-Historie:** Jahres-Plakette zeigt wieder „2025" / „2024" statt „2.025" / „2.024" — Locale-Bug bei der SwiftUI-Int-Interpolation behoben.
- **KI-Chat:** Kennt jetzt das aktuelle Datum und nennt korrekte Termine. Vorher konnte die KI in seltenen Fällen ein falsches absolutes Datum nennen, wenn nach „in X Tagen" gefragt wurde.
- **Such-/KI-Leiste:** Klarerer Hinweis-Text, damit erkennbar ist, dass die Eingabe direkt in den KI-Chat führt.

---

## Lokalisierte Release Notes (für ASC)

### DE-DE / DE-AT / DE-CH

```
Wir haben kleine, aber sichtbare Schliffe vorgenommen:

• Geschenk-Historie zeigt Jahre wieder ohne Tausenderpunkt
• KI-Chat kennt das aktuelle Datum und nennt korrekte Termine
• Such-/KI-Leiste signalisiert klarer, dass sie zur KI führt
• Stats-Row beantwortet jetzt was-heute-ansteht
• Neuer JSON-Daten-Export für manuelle Backups
```

### EN-US / EN-GB

```
Small but visible improvements:

• Gift history now displays years without thousand separators
• AI chat knows today's date and gives correct timing
• Search/AI bar more clearly signals it leads to the assistant
• Stats row now answers what's-on-today
• New JSON data export for manual backups
```

### FR-FR / FR-CA

```
Petites améliorations bien visibles :

• L'historique des cadeaux affiche les années sans séparateur de milliers
• Le chat IA connaît la date du jour et donne des dates correctes
• La barre de recherche / IA signale plus clairement qu'elle ouvre l'assistant
• Les statistiques répondent à « qu'est-ce qui se passe aujourd'hui »
• Nouvel export JSON pour des sauvegardes manuelles
```

### ES-ES / ES-MX

```
Pequeñas pero visibles mejoras:

• El historial de regalos muestra los años sin separador de miles
• El chat de IA conoce la fecha de hoy y da fechas correctas
• La barra de búsqueda / IA señala más claramente que abre el asistente
• La fila de estadísticas responde a qué hay hoy
• Nueva exportación de datos JSON para copias de seguridad manuales
```

---

## Technischer Hintergrund

- **Plan Wave 1:** `docs/plans/2026-05-01-001-feat-review-improvements-v107-plan.md`
- **Plan Wave 2:** `docs/plans/2026-05-01-002-fix-e2e-findings-v107-plan.md`
- **E2E-Test 2026-05-01:** `docs/E2E-TESTBERICHT-2026-05-01.md`

## Submit-Checkliste (auto)

1. `project.yml`: `CFBundleVersion` 138 → 139 (App + Widget)
2. `xcodegen generate` + `Info.plist`-Diff committen
3. `xcodebuild build` als Sanity-Check
4. Push → TestFlight-Workflow läuft automatisch
5. Nach TestFlight-SUCCEEDED: App-Store-Build-Workflow `27f2efdf-ce6e-4c74-846f-3eb002c39ef5` triggern
6. ASC-Version 1.0.7 anlegen → Localizations setzen → Build attachen → validate → submit
