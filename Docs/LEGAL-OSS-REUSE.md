# OSS-Reuse Richtlinie

## Ziel
Externe Open-Source-Bausteine rechtssicher und sauber nutzen, ohne Lizenzprobleme.

## Kandidaten (vor Nutzung einzeln prüfen)
- `lukeleleh/reminders-app` (MIT)
- `tiagomartinho/Reminders` (MIT)
- `richardtop/CalendarKit` (MIT)

## Regeln
1. **Pattern first, Copy second**: Architekturidee bevorzugen statt blindes Copy/Paste.
2. Wenn Code übernommen wird:
   - Original-Lizenztext beibehalten
   - Attribution dokumentieren
   - Herkunft in Commit-Message benennen
3. Drittanbieter-Lizenzen in `ThirdPartyLicenses/` ablegen.
4. Keine proprietären Assets/Branding aus Fremdprojekten übernehmen.
5. Bei unklarer Lizenz: **nicht übernehmen**, erst klären.

## Pflicht bei jeder Übernahme
- Datei/Abschnitt markieren (`// Source: ...`)
- Lizenz in Doku aktualisieren
- kurze Begründung, warum übernommen wurde
