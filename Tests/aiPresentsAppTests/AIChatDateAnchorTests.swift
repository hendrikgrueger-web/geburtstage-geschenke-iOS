import XCTest
@testable import aiPresentsApp

// MARK: - AIChatViewModel — DateAnchor Tests
//
// Fix: `buildDateAnchor(lang:region:)` ist `internal` (nicht private) und damit
// direkt per @testable import testbar.
//
// Injizierbarer Date-Provider: `viewModel.currentDate = { fixedDate }`
//
// Strategie für Locale/TimeZone-Determinismus:
//   - `buildDateAnchor` direkt aufrufen (keine Locale-Abhängigkeit durch Simulator-Default)
//   - ISO-Format ist POSIX/en_US_POSIX — sprachunabhängig determiniert
//   - Wochentag-Formatierung via prettyFormatter nutzt die übergebene lang/region — testbar

@MainActor
final class AIChatDateAnchorTests: XCTestCase {

    // MARK: - Hilfsmethoden

    /// Erzeugt ein festes Datum in UTC aus einem ISO-8601-String (z.B. "2026-05-01T12:00:00Z").
    private func fixedDate(_ iso: String) -> Date {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.date(from: iso)!
    }

    /// Baut ein ViewModel mit injizierbarem Datum.
    private func makeVM(date: Date) -> AIChatViewModel {
        let vm = AIChatViewModel()
        vm.currentDate = { date }
        return vm
    }

    // MARK: - A) Datums-Anker-Inhalt: Kopfzeilen

    func testDateAnchor_DE_containsHeader() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "de", region: "DE")
        XCTAssertTrue(anchor.contains("HEUTIGES DATUM:"),
                      "DE-Anker muss 'HEUTIGES DATUM:' enthalten. Anker: \(anchor)")
    }

    func testDateAnchor_EN_containsHeader() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "en", region: "US")
        XCTAssertTrue(anchor.contains("TODAY'S DATE:"),
                      "EN-Anker muss 'TODAY'S DATE:' enthalten. Anker: \(anchor)")
    }

    func testDateAnchor_FR_containsHeader() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "fr", region: "FR")
        XCTAssertTrue(anchor.contains("DATE D'AUJOURD'HUI :"),
                      "FR-Anker muss 'DATE D\\'AUJOURD\\'HUI :' enthalten. Anker: \(anchor)")
    }

    func testDateAnchor_ES_containsHeader() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "es", region: "ES")
        XCTAssertTrue(anchor.contains("FECHA DE HOY:"),
                      "ES-Anker muss 'FECHA DE HOY:' enthalten. Anker: \(anchor)")
    }

    // MARK: - A) Datums-Anker-Inhalt: ISO-Datum

    func testDateAnchor_DE_containsISODate() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "de", region: "DE")
        XCTAssertTrue(anchor.contains("2026-05-01"),
                      "DE-Anker muss ISO-Datum '2026-05-01' enthalten. Anker: \(anchor)")
    }

    func testDateAnchor_EN_containsISODate() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "en", region: "US")
        XCTAssertTrue(anchor.contains("2026-05-01"),
                      "EN-Anker muss ISO-Datum enthalten. Anker: \(anchor)")
    }

    func testDateAnchor_FR_containsISODate() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "fr", region: "FR")
        XCTAssertTrue(anchor.contains("2026-05-01"), "FR-Anker muss ISO-Datum enthalten")
    }

    func testDateAnchor_ES_containsISODate() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "es", region: "ES")
        XCTAssertTrue(anchor.contains("2026-05-01"), "ES-Anker muss ISO-Datum enthalten")
    }

    // MARK: - A) Datums-Anker: Wochentag in korrekter Sprache (2026-05-01 = Freitag)

    func testDateAnchor_DE_containsWeekdayGerman() {
        // 2026-05-01 ist ein Freitag
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "de", region: "DE")
        XCTAssertTrue(anchor.lowercased().contains("freitag"),
                      "DE-Anker muss 'Freitag' enthalten. Anker: \(anchor)")
    }

    func testDateAnchor_EN_containsWeekdayEnglish() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "en", region: "US")
        XCTAssertTrue(anchor.lowercased().contains("friday"),
                      "EN-Anker muss 'Friday' enthalten. Anker: \(anchor)")
    }

    func testDateAnchor_FR_containsWeekdayFrench() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "fr", region: "FR")
        XCTAssertTrue(anchor.lowercased().contains("vendredi"),
                      "FR-Anker muss 'vendredi' enthalten. Anker: \(anchor)")
    }

    func testDateAnchor_ES_containsWeekdaySpanish() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "es", region: "ES")
        XCTAssertTrue(anchor.lowercased().contains("viernes"),
                      "ES-Anker muss 'viernes' enthalten. Anker: \(anchor)")
    }

    // Wochentage aller 7 Tage — nutzt 2025-12-29..2026-01-04 (Mo–So)
    // 2025-12-29 = Montag
    func testDateAnchor_DE_allWeekdays() {
        let weekdays_de = ["montag", "dienstag", "mittwoch", "donnerstag", "freitag", "samstag", "sonntag"]
        let dates = [
            "2025-12-29", "2025-12-30", "2025-12-31",
            "2026-01-01", "2026-01-02", "2026-01-03", "2026-01-04"
        ]
        let vm = AIChatViewModel()
        for (index, dateStr) in dates.enumerated() {
            vm.currentDate = { self.fixedDate("\(dateStr)T12:00:00Z") }
            let anchor = vm.buildDateAnchor(lang: "de", region: "DE").lowercased()
            XCTAssertTrue(anchor.contains(weekdays_de[index]),
                          "Datum \(dateStr): Anker muss '\(weekdays_de[index])' enthalten. Anker: \(anchor)")
        }
    }

    func testDateAnchor_EN_allWeekdays() {
        let weekdays_en = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        let dates = [
            "2025-12-29", "2025-12-30", "2025-12-31",
            "2026-01-01", "2026-01-02", "2026-01-03", "2026-01-04"
        ]
        let vm = AIChatViewModel()
        for (index, dateStr) in dates.enumerated() {
            vm.currentDate = { self.fixedDate("\(dateStr)T12:00:00Z") }
            let anchor = vm.buildDateAnchor(lang: "en", region: "US").lowercased()
            XCTAssertTrue(anchor.contains(weekdays_en[index]),
                          "Datum \(dateStr): EN-Anker muss '\(weekdays_en[index])' enthalten")
        }
    }

    // MARK: - B) Schutzklausel in allen 4 Sprachen

    func testDateAnchor_DE_containsRelativeKeyword() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "de", region: "DE")
        XCTAssertTrue(anchor.contains("relativ"),
                      "DE-Anker muss Schutzklausel mit 'relativ' enthalten. Anker: \(anchor)")
    }

    func testDateAnchor_EN_containsRelativeKeyword() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "en", region: "US")
        XCTAssertTrue(anchor.contains("relative"),
                      "EN-Anker muss 'relative' enthalten. Anker: \(anchor)")
    }

    func testDateAnchor_FR_containsRelativeKeyword() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "fr", region: "FR")
        XCTAssertTrue(anchor.contains("relatives"),
                      "FR-Anker muss 'relatives' enthalten. Anker: \(anchor)")
    }

    func testDateAnchor_ES_containsRelativeKeyword() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "es", region: "ES")
        XCTAssertTrue(anchor.contains("relativas"),
                      "ES-Anker muss 'relativas' enthalten. Anker: \(anchor)")
    }

    func testDateAnchor_allLanguages_nonEmpty() {
        let langs = [("de", "DE"), ("en", "US"), ("fr", "FR"), ("es", "ES")]
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        for (lang, region) in langs {
            let anchor = vm.buildDateAnchor(lang: lang, region: region)
            XCTAssertFalse(anchor.isEmpty, "\(lang)_\(region): Anker darf nicht leer sein")
        }
    }

    // MARK: - C) Cache-Invalidierung bei Tageswechsel

    func testCache_noRebuildOnSecondCallSameDay() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let prompt1 = vm.systemPromptForTesting()
        XCTAssertFalse(vm.promptNeedsRebuildForTesting, "Kein Rebuild nötig nach initialem Build")
        let prompt2 = vm.systemPromptForTesting()
        XCTAssertEqual(prompt1, prompt2, "Gleicher Tag: Prompt muss identisch sein")
    }

    func testCache_rebuildAfterDayChange() {
        let vm = AIChatViewModel()
        vm.currentDate = { self.fixedDate("2026-05-01T12:00:00Z") }
        vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let prompt1 = vm.systemPromptForTesting()
        XCTAssertTrue(prompt1.contains("2026-05-01"), "Erster Prompt muss '2026-05-01' enthalten")

        // Tag wechseln
        vm.currentDate = { self.fixedDate("2026-05-02T12:00:00Z") }
        let prompt2 = vm.systemPromptForTesting()

        XCTAssertTrue(prompt2.contains("2026-05-02"),
                      "Nach Tageswechsel muss Prompt '2026-05-02' enthalten. Prompt: \(prompt2.prefix(300))")
        XCTAssertFalse(prompt2.contains("2026-05-01"),
                       "Nach Tageswechsel darf '2026-05-01' nicht mehr im Prompt stehen")
    }

    func testCache_rebuildAfterDataAndDayChangeSimultaneous() {
        let person = makeTestPerson(name: "Anna Beispiel")
        let vm = AIChatViewModel()
        vm.currentDate = { self.fixedDate("2026-05-01T12:00:00Z") }
        vm.configure(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)

        let _ = vm.systemPromptForTesting()
        XCTAssertFalse(vm.promptNeedsRebuildForTesting)

        // Gleichzeitig: Daten ändern UND Tag wechseln
        vm.currentDate = { self.fixedDate("2026-05-02T12:00:00Z") }
        let idea = GiftIdea(personId: person.id, title: "Neues Geschenk", status: .idea)
        vm.refreshContext(people: [person], giftIdeas: [idea], giftHistory: [], modelContext: nil)

        XCTAssertTrue(vm.promptNeedsRebuildForTesting, "Rebuild muss nach refreshContext gesetzt sein")
        let newPrompt = vm.systemPromptForTesting()
        XCTAssertTrue(newPrompt.contains("2026-05-02"), "Neues Datum muss im Prompt sein")
        XCTAssertTrue(newPrompt.contains("Neues Geschenk"), "Neue Daten müssen im Prompt sein")
    }

    func testCache_multipleCallsSameDayNoRebuild() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let prompt1 = vm.systemPromptForTesting()
        let prompt2 = vm.systemPromptForTesting()
        let prompt3 = vm.systemPromptForTesting()

        XCTAssertEqual(prompt1, prompt2)
        XCTAssertEqual(prompt2, prompt3)
        XCTAssertFalse(vm.promptNeedsRebuildForTesting)
    }

    func testCache_invalidatePromptCache_setsNilDay() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let _ = vm.systemPromptForTesting()
        XCTAssertFalse(vm.promptNeedsRebuildForTesting)

        vm.invalidatePromptCache()
        XCTAssertTrue(vm.promptNeedsRebuildForTesting,
                      "Nach invalidatePromptCache muss promptNeedsRebuild true sein")

        // Nächster Aufruf rebuildet zwingend
        let rebuiltPrompt = vm.systemPromptForTesting()
        XCTAssertFalse(vm.promptNeedsRebuildForTesting)
        XCTAssertFalse(rebuiltPrompt.isEmpty, "Rebuilt Prompt darf nicht leer sein")
    }

    func testCache_invalidatePromptCache_rebuildUsesCurrentDate() {
        let vm = AIChatViewModel()
        vm.currentDate = { self.fixedDate("2026-05-01T12:00:00Z") }
        vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let prompt1 = vm.systemPromptForTesting()
        XCTAssertTrue(prompt1.contains("2026-05-01"))

        vm.invalidatePromptCache()
        vm.currentDate = { self.fixedDate("2026-06-15T12:00:00Z") }
        let prompt2 = vm.systemPromptForTesting()
        XCTAssertTrue(prompt2.contains("2026-06-15"),
                      "Nach invalidate+Datumswechsel muss neues Datum genutzt werden")
    }

    func testCache_refreshContextWithSameDataAndDayCausesRebuild() {
        // refreshContext invalidiert immer — auch bei identischen Daten
        // (notwendig weil der Caller nicht weiß ob Daten wirklich gleich sind)
        let person = makeTestPerson(name: "Max Muster")
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        vm.configure(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)

        let _ = vm.systemPromptForTesting()
        XCTAssertFalse(vm.promptNeedsRebuildForTesting)

        // Gleiche Daten, gleicher Tag — refreshContext setzt trotzdem rebuild
        vm.refreshContext(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)
        XCTAssertTrue(vm.promptNeedsRebuildForTesting,
                      "refreshContext muss immer rebuild triggern")
    }

    // MARK: - D) Edge Cases

    func testDateAnchor_leapYear_2024_02_29() {
        let vm = makeVM(date: fixedDate("2024-02-29T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "de", region: "DE")
        XCTAssertTrue(anchor.contains("2024-02-29"),
                      "Schalttag muss korrekt im Anker erscheinen. Anker: \(anchor)")
        XCTAssertTrue(anchor.lowercased().contains("donnerstag"),
                      "2024-02-29 ist ein Donnerstag. Anker: \(anchor)")
    }

    func testDateAnchor_leapYear_2024_02_29_EN() {
        let vm = makeVM(date: fixedDate("2024-02-29T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "en", region: "US")
        XCTAssertTrue(anchor.contains("2024-02-29"))
        XCTAssertTrue(anchor.lowercased().contains("thursday"),
                      "2024-02-29 is a Thursday. Anker: \(anchor)")
    }

    func testDateAnchor_yearChange_2025_12_31_to_2026_01_01() {
        // Silvesternacht: Prompt mit 31.12. gebaut, nächster Aufruf mit 1.1. muss neues Datum bringen
        let vm = AIChatViewModel()
        vm.currentDate = { self.fixedDate("2025-12-31T12:00:00Z") }
        vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let prompt31 = vm.systemPromptForTesting()
        XCTAssertTrue(prompt31.contains("2025-12-31"))

        vm.currentDate = { self.fixedDate("2026-01-01T12:00:00Z") }
        let prompt01 = vm.systemPromptForTesting()
        XCTAssertTrue(prompt01.contains("2026-01-01"),
                      "Neujahr: Prompt muss '2026-01-01' enthalten. Prompt: \(prompt01.prefix(300))")
        XCTAssertFalse(prompt01.contains("2025-12-31"),
                       "Neujahr: '2025-12-31' darf nicht mehr im Prompt sein")
    }

    func testDateAnchor_timezone_UTC_vs_Auckland() {
        // Kurz vor Mitternacht UTC — in Auckland ist es schon der nächste Tag
        // Das Datum im Anker soll das LOKALE Datum (TimeZone.current) sein, nicht UTC.
        // Da der Test in der Simulator-TimeZone läuft, prüfen wir hier nur,
        // dass der Anker ein ISO-Datum enthält und kein Crash entsteht.
        // Ein TimeZone-Override per setenv ist fragil und wird bewusst vermieden.
        let date = fixedDate("2026-05-01T23:30:00Z")
        let vm = makeVM(date: date)
        let anchor = vm.buildDateAnchor(lang: "de", region: "DE")
        XCTAssertFalse(anchor.isEmpty)
        // ISO-Datum im erwarteten Format yyyy-MM-dd
        let isoPattern = /\d{4}-\d{2}-\d{2}/
        XCTAssertNotNil(try? isoPattern.firstMatch(in: anchor),
                        "Anker muss ISO-Datum im Format yyyy-MM-dd enthalten. Anker: \(anchor)")
    }

    func testDateAnchor_frCA_doesNotCrash() {
        // fr-CA (Québec): Wochentag in franz.-kanad. Schreibweise — kein Crash, non-empty
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "fr", region: "CA")
        XCTAssertFalse(anchor.isEmpty, "fr_CA: Anker darf nicht leer sein")
        XCTAssertTrue(anchor.contains("2026-05-01"), "fr_CA: ISO-Datum muss enthalten sein")
        // Wochentag auf Französisch (vendredi = Freitag)
        XCTAssertTrue(anchor.lowercased().contains("vendredi"),
                      "fr_CA: Wochentag 'vendredi' erwartet. Anker: \(anchor)")
    }

    func testDateAnchor_esAR_doesNotCrash() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "es", region: "AR")
        XCTAssertFalse(anchor.isEmpty, "es_AR: Anker darf nicht leer sein")
        XCTAssertTrue(anchor.contains("2026-05-01"))
    }

    func testDateAnchor_unknownRegion_emptyString_fallback() {
        // lang=de, region="" → Fallback auf de_DE-Locale, kein Crash
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "de", region: "")
        XCTAssertFalse(anchor.isEmpty, "Leere region muss Fallback-Locale nutzen, kein Crash")
        XCTAssertTrue(anchor.contains("HEUTIGES DATUM:"))
        XCTAssertTrue(anchor.contains("2026-05-01"))
        XCTAssertTrue(anchor.lowercased().contains("freitag"),
                      "de+leere Region: Wochentag auf Deutsch erwartet. Anker: \(anchor)")
    }

    func testDateAnchor_unknownLanguage_fallsBackToEnglish() {
        // Unbekannte Sprache → default (Englisch)
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "ja", region: "JP")
        XCTAssertFalse(anchor.isEmpty, "Unbekannte Sprache: kein Crash")
        XCTAssertTrue(anchor.contains("TODAY'S DATE:"),
                      "Unbekannte Sprache muss auf Englisch fallen. Anker: \(anchor)")
        XCTAssertTrue(anchor.contains("2026-05-01"))
    }

    func testDateAnchor_emptyLang_fallsBackToEnglish() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        let anchor = vm.buildDateAnchor(lang: "", region: "")
        XCTAssertFalse(anchor.isEmpty)
        XCTAssertTrue(anchor.contains("TODAY'S DATE:"))
    }

    func testDateAnchor_isoDate_noLocaleFormatting() {
        // ISO-Formatter nutzt en_US_POSIX — kein Tausenderpunkt, kein Locale-Overhead
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        for (lang, region) in [("de", "DE"), ("fr", "FR"), ("es", "ES"), ("en", "US")] {
            let anchor = vm.buildDateAnchor(lang: lang, region: region)
            // ISO-Datum "2026-05-01" — kein Slash, kein Punkt als Trennzeichen im ISO-Teil
            XCTAssertTrue(anchor.contains("2026-05-01"),
                          "\(lang)_\(region): ISO-Datum '2026-05-01' erwartet. Anker: \(anchor)")
        }
    }

    // MARK: - E) Integration: Datums-Anker im vollständigen System-Prompt

    func testSystemPrompt_DE_containsDateAnchor() {
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)
        let prompt = vm.systemPromptForTesting()
        XCTAssertTrue(prompt.contains("2026-05-01"),
                      "System-Prompt muss Datums-Anker enthalten. Anfang: \(prompt.prefix(500))")
    }

    func testSystemPrompt_afterDayChange_updatesDateInPrompt() {
        let vm = AIChatViewModel()
        vm.currentDate = { self.fixedDate("2026-05-01T12:00:00Z") }
        vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let p1 = vm.systemPromptForTesting()
        XCTAssertTrue(p1.contains("2026-05-01"))

        vm.currentDate = { self.fixedDate("2026-05-15T12:00:00Z") }
        let p2 = vm.systemPromptForTesting()
        XCTAssertTrue(p2.contains("2026-05-15"),
                      "Tageswechsel: System-Prompt muss '2026-05-15' enthalten")
        XCTAssertFalse(p2.contains("2026-05-01"),
                       "Altes Datum '2026-05-01' darf nicht mehr im Prompt sein")
    }

    func testSystemPrompt_withPeople_containsBothDateAndPersons() {
        let person = makeTestPerson(name: "Luisa Schmidt", relation: "Schwester")
        let vm = makeVM(date: fixedDate("2026-05-01T12:00:00Z"))
        vm.configure(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)

        let prompt = vm.systemPromptForTesting()
        XCTAssertTrue(prompt.contains("2026-05-01"), "Datums-Anker muss im Prompt sein")
        XCTAssertTrue(prompt.contains("Luisa"), "Personenname muss im Prompt sein")
        XCTAssertTrue(prompt.contains("Schwester"), "Relation muss im Prompt sein")
    }

    func testSystemPrompt_cacheRespectsBuildDay() {
        let vm = AIChatViewModel()
        vm.currentDate = { self.fixedDate("2026-01-15T10:00:00Z") }
        vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let prompt1 = vm.systemPromptForTesting()
        XCTAssertFalse(vm.promptNeedsRebuildForTesting)

        // Datum leicht verändern aber gleicher Tag → kein Rebuild
        vm.currentDate = { self.fixedDate("2026-01-15T22:00:00Z") }
        let prompt2 = vm.systemPromptForTesting()
        XCTAssertEqual(prompt1, prompt2,
                       "Gleiches Datum (anderer Zeitpunkt): Prompt muss identisch (gecacht) sein")
    }

    // MARK: - Hilfsfunktionen

    private func makeTestPerson(name: String, relation: String = "Freund") -> PersonRef {
        PersonRef(
            contactIdentifier: UUID().uuidString,
            displayName: name,
            birthday: Calendar.current.date(from: DateComponents(year: 1990, month: 6, day: 20))!,
            relation: relation
        )
    }
}

// MARK: - AIChatPromptCachingTests Erweiterungen (in separater Extension-Klasse)
//
// Ergänzt bestehende AIChatPromptCachingTests.swift um Datums-abhängige Cache-Tests.

@MainActor
final class AIChatPromptCachingDateTests: XCTestCase {

    private func fixedDate(_ iso: String) -> Date {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.date(from: iso)!
    }

    private func makePerson(name: String, relation: String = "Freund") -> PersonRef {
        PersonRef(
            contactIdentifier: UUID().uuidString,
            displayName: name,
            birthday: Calendar.current.date(from: DateComponents(year: 1985, month: 3, day: 10))!,
            relation: relation
        )
    }

    func testCaching_initialBuild_promptNeedsRebuildFalse() {
        let vm = AIChatViewModel()
        vm.currentDate = { self.fixedDate("2026-05-01T12:00:00Z") }
        vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        XCTAssertTrue(vm.promptNeedsRebuildForTesting, "Vor erstem Build: muss rebuild nötig sein")
        let _ = vm.systemPromptForTesting()
        XCTAssertFalse(vm.promptNeedsRebuildForTesting, "Nach Build: kein Rebuild nötig")
    }

    func testCaching_refreshContextAlwaysInvalidates() {
        let vm = AIChatViewModel()
        vm.currentDate = { self.fixedDate("2026-05-01T12:00:00Z") }
        let person = makePerson(name: "Test Person")
        vm.configure(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)

        let _ = vm.systemPromptForTesting()
        XCTAssertFalse(vm.promptNeedsRebuildForTesting)

        vm.refreshContext(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)
        XCTAssertTrue(vm.promptNeedsRebuildForTesting,
                      "refreshContext muss immer invalidieren (auch ohne Datumswechsel)")
    }

    func testCaching_giftStatusUpdate_invalidatesCache() async {
        let person = makePerson(name: "Marie Müller")
        let idea = GiftIdea(personId: person.id, title: "Blumen", status: .idea)
        let vm = AIChatViewModel()
        vm.currentDate = { self.fixedDate("2026-05-01T12:00:00Z") }
        vm.configure(people: [person], giftIdeas: [idea], giftHistory: [], modelContext: nil)

        let initial = vm.systemPromptForTesting()
        XCTAssertTrue(initial.contains("Blumen[idea]"))

        let action = ChatAction(
            type: .updateGiftStatus,
            data: ActionData(
                personId: nil, personName: nil, giftTitle: nil, giftNote: nil,
                newStatus: GiftStatus.purchased.rawValue,
                giftIdeaId: "g1"
            )
        )
        await vm.processAction(action)

        XCTAssertTrue(vm.promptNeedsRebuildForTesting,
                      "processAction(updateGiftStatus) muss Cache invalidieren")
        let updated = vm.systemPromptForTesting()
        XCTAssertTrue(updated.contains("Blumen[purchased]"),
                      "Nach Status-Update muss Prompt 'purchased' enthalten")
    }

    func testCaching_dateAnchorChangesOnDayBoundary() {
        let vm = AIChatViewModel()
        vm.currentDate = { self.fixedDate("2026-03-31T12:00:00Z") }
        vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let p1 = vm.systemPromptForTesting()
        XCTAssertTrue(p1.contains("2026-03-31"))

        // Tageswechsel: 1. April
        vm.currentDate = { self.fixedDate("2026-04-01T12:00:00Z") }
        let p2 = vm.systemPromptForTesting()
        XCTAssertTrue(p2.contains("2026-04-01"), "Monatsgrenze: April muss im Prompt erscheinen")
        XCTAssertFalse(p2.contains("2026-03-31"))
    }

    func testCaching_leapYearBoundary_2024_02_28_to_02_29() {
        let vm = AIChatViewModel()
        vm.currentDate = { self.fixedDate("2024-02-28T12:00:00Z") }
        vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let p1 = vm.systemPromptForTesting()
        XCTAssertTrue(p1.contains("2024-02-28"))

        vm.currentDate = { self.fixedDate("2024-02-29T12:00:00Z") }
        let p2 = vm.systemPromptForTesting()
        XCTAssertTrue(p2.contains("2024-02-29"), "Schaltjahr: 29. Februar muss im Prompt sein")
    }

    func testCaching_leapYearBoundary_2024_02_29_to_03_01() {
        let vm = AIChatViewModel()
        vm.currentDate = { self.fixedDate("2024-02-29T12:00:00Z") }
        vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let _ = vm.systemPromptForTesting()

        vm.currentDate = { self.fixedDate("2024-03-01T12:00:00Z") }
        let p2 = vm.systemPromptForTesting()
        XCTAssertTrue(p2.contains("2024-03-01"), "Nach Schalttag: 1. März muss im Prompt sein")
        XCTAssertFalse(p2.contains("2024-02-29"))
    }

    func testCaching_yearChange_2025_to_2026() {
        let vm = AIChatViewModel()
        vm.currentDate = { self.fixedDate("2025-12-31T12:00:00Z") }
        vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let p1 = vm.systemPromptForTesting()
        XCTAssertTrue(p1.contains("2025-12-31"))

        vm.currentDate = { self.fixedDate("2026-01-01T12:00:00Z") }
        let p2 = vm.systemPromptForTesting()
        XCTAssertTrue(p2.contains("2026-01-01"),
                      "Jahreswechsel: Neues Jahr muss im Prompt sein. Anfang: \(p2.prefix(300))")
        XCTAssertFalse(p2.contains("2025-12-31"))
    }

    func testCaching_multipleDayChanges_eachCausesRebuild() {
        let vm = AIChatViewModel()
        let dates = [
            "2026-01-01", "2026-01-02", "2026-01-03",
            "2026-06-30", "2026-07-01", "2026-12-31"
        ]

        for dateStr in dates {
            vm.currentDate = { self.fixedDate("\(dateStr)T12:00:00Z") }
            if vm.promptNeedsRebuildForTesting {
                vm.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)
            }
            let prompt = vm.systemPromptForTesting()
            XCTAssertTrue(prompt.contains(dateStr),
                          "Datum \(dateStr): Prompt muss aktuelles Datum enthalten")
            // Nächsten Zyklus vorbereiten: manuell Tag-Wechsel simulieren (currentDate ändert sich)
            // — nächste Iteration setzt neues Datum, Cache-Check erkennt Wechsel
        }
    }
}
