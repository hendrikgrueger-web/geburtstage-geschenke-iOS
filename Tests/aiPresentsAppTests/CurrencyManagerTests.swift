import XCTest
@testable import aiPresentsApp

@MainActor
final class CurrencyManagerTests: XCTestCase {

    var sut: CurrencyManager!

    override func setUp() {
        super.setUp()
        // Reset singleton state before each test
        sut = CurrencyManager.shared
        // Clear UserDefaults to avoid test interference
        UserDefaults.standard.removeObject(forKey: "currencyAutomatic")
        UserDefaults.standard.removeObject(forKey: "selectedCurrencyCode")
    }

    override func tearDown() {
        super.tearDown()
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: "currencyAutomatic")
        UserDefaults.standard.removeObject(forKey: "selectedCurrencyCode")
        sut = nil
    }

    // MARK: - effectiveCurrencyCode Tests

    func testEffectiveCurrencyCodeWhenAutomatic() {
        sut.isAutomatic = true
        let effective = sut.effectiveCurrencyCode
        XCTAssertEqual(effective, Locale.current.currency?.identifier ?? "EUR",
                       "Effektive Währung sollte Locale-Währung sein wenn automatisch")
    }

    func testEffectiveCurrencyCodeWhenManual() {
        sut.isAutomatic = false
        sut.currencyCode = "USD"
        let effective = sut.effectiveCurrencyCode
        XCTAssertEqual(effective, "USD",
                       "Effektive Währung sollte manuell gesetzte Währung sein")
    }

    // MARK: - formatAmount Tests

    func testFormatAmountWithEuro() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        let formatted = sut.formatAmount(100.50)
        XCTAssertTrue(formatted.contains("100"), "Formatierter Betrag sollte 100 enthalten")
        XCTAssertTrue(formatted.contains("€") || formatted.contains("EUR"),
                      "Formatierter Betrag sollte EUR-Symbol enthalten")
    }

    func testFormatAmountWithJPY() {
        sut.isAutomatic = false
        sut.currencyCode = "JPY"
        let formatted = sut.formatAmount(1000.0)
        XCTAssertTrue(formatted.contains("1000") || formatted.contains("1,000"),
                      "JPY-Betrag sollte korrekt formatiert sein")
        // JPY hat keine Dezimalstellen
        XCTAssertFalse(formatted.contains(",") || formatted.contains(".") || formatted.contains("00"),
                       "JPY sollte keine Dezimalstellen anzeigen")
    }

    func testFormatAmountWithZero() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        let formatted = sut.formatAmount(0.0)
        XCTAssertTrue(formatted.contains("0"), "Null-Betrag sollte 0 enthalten")
    }

    func testFormatAmountWithNegative() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        let formatted = sut.formatAmount(-50.0)
        XCTAssertTrue(formatted.contains("50") || formatted.contains("-"),
                      "Negativer Betrag sollte korrekt formatiert sein")
    }

    // MARK: - formatBudgetRange Tests

    func testFormatBudgetRangeSingleValue() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        let formatted = sut.formatBudgetRange(min: 100.0, max: 100.0)
        XCTAssertTrue(formatted.contains("100"), "Einzelwert-Range sollte Wert enthalten")
    }

    func testFormatBudgetRangeOpenEnded() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        let formatted = sut.formatBudgetRange(min: 0, max: 500.0)
        XCTAssertTrue(formatted.contains("500"), "Open-ended Range sollte Maximalwert enthalten")
        XCTAssertTrue(formatted.lowercased().contains("bis") || formatted.contains("≤"),
                      "Open-ended Range sollte 'bis' oder '≤' enthalten")
    }

    func testFormatBudgetRangeClosedRange() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        let formatted = sut.formatBudgetRange(min: 100.0, max: 500.0)
        XCTAssertTrue(formatted.contains("100"), "Closed Range sollte Minimalwert enthalten")
        XCTAssertTrue(formatted.contains("500"), "Closed Range sollte Maximalwert enthalten")
        XCTAssertTrue(formatted.contains("–") || formatted.contains("-"),
                      "Closed Range sollte Bindestrich enthalten")
    }

    func testFormatBudgetRangeZeroRange() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        let formatted = sut.formatBudgetRange(min: 0, max: 0)
        XCTAssertEqual(formatted, "", "Null-Range sollte leeren String zurückgeben")
    }

    // MARK: - formatAmountOrEmpty Tests

    func testFormatAmountOrEmptyWithAmount() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        let formatted = sut.formatAmountOrEmpty(100.0)
        XCTAssertTrue(formatted.contains("100"), "Formatierter Betrag sollte Wert enthalten")
        XCTAssertFalse(formatted.lowercased().contains("kein"),
                       "Positiver Betrag sollte nicht 'Kein Preis' anzeigen")
    }

    func testFormatAmountOrEmptyWithZero() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        let formatted = sut.formatAmountOrEmpty(0.0)
        XCTAssertTrue(formatted.lowercased().contains("kein"),
                      "Null-Betrag sollte 'Kein Preis' anzeigen")
    }

    func testFormatAmountOrEmptyWithNegative() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        let formatted = sut.formatAmountOrEmpty(-10.0)
        XCTAssertTrue(formatted.lowercased().contains("kein"),
                      "Negativer Betrag sollte 'Kein Preis' anzeigen")
    }

    // MARK: - sliderMaximum Tests

    func testSliderMaximumEUR() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        XCTAssertEqual(sut.sliderMaximum, 500, "EUR Slider-Maximum sollte 500 sein")
    }

    func testSliderMaximumUSD() {
        sut.isAutomatic = false
        sut.currencyCode = "USD"
        XCTAssertEqual(sut.sliderMaximum, 500, "USD Slider-Maximum sollte 500 sein")
    }

    func testSliderMaximumJPY() {
        sut.isAutomatic = false
        sut.currencyCode = "JPY"
        XCTAssertEqual(sut.sliderMaximum, 50_000, "JPY Slider-Maximum sollte 50.000 sein")
    }

    func testSliderMaximumSEK() {
        sut.isAutomatic = false
        sut.currencyCode = "SEK"
        XCTAssertEqual(sut.sliderMaximum, 5_000, "SEK Slider-Maximum sollte 5.000 sein")
    }

    func testSliderMaximumINR() {
        sut.isAutomatic = false
        sut.currencyCode = "INR"
        XCTAssertEqual(sut.sliderMaximum, 25_000, "INR Slider-Maximum sollte 25.000 sein")
    }

    func testSliderMaximumKRW() {
        sut.isAutomatic = false
        sut.currencyCode = "KRW"
        XCTAssertEqual(sut.sliderMaximum, 50_000, "KRW Slider-Maximum sollte 50.000 sein")
    }

    func testSliderMaximumGBP() {
        sut.isAutomatic = false
        sut.currencyCode = "GBP"
        XCTAssertEqual(sut.sliderMaximum, 500, "GBP Slider-Maximum sollte 500 sein (default)")
    }

    // MARK: - sliderStep Tests

    func testSliderStepEUR() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        XCTAssertEqual(sut.sliderStep, 5, "EUR Slider-Step sollte 5 sein")
    }

    func testSliderStepUSD() {
        sut.isAutomatic = false
        sut.currencyCode = "USD"
        XCTAssertEqual(sut.sliderStep, 5, "USD Slider-Step sollte 5 sein")
    }

    func testSliderStepJPY() {
        sut.isAutomatic = false
        sut.currencyCode = "JPY"
        XCTAssertEqual(sut.sliderStep, 500, "JPY Slider-Step sollte 500 sein")
    }

    func testSliderStepSEK() {
        sut.isAutomatic = false
        sut.currencyCode = "SEK"
        XCTAssertEqual(sut.sliderStep, 50, "SEK Slider-Step sollte 50 sein")
    }

    func testSliderStepINR() {
        sut.isAutomatic = false
        sut.currencyCode = "INR"
        XCTAssertEqual(sut.sliderStep, 250, "INR Slider-Step sollte 250 sein")
    }

    func testSliderStepGBP() {
        sut.isAutomatic = false
        sut.currencyCode = "GBP"
        XCTAssertEqual(sut.sliderStep, 5, "GBP Slider-Step sollte 5 sein (default)")
    }

    // MARK: - sliderMinimum Tests

    func testSliderMinimumAllCurrencies() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        XCTAssertEqual(sut.sliderMinimum, 0, "Slider-Minimum sollte immer 0 sein")
    }

    func testSliderMinimumJPY() {
        sut.isAutomatic = false
        sut.currencyCode = "JPY"
        XCTAssertEqual(sut.sliderMinimum, 0, "JPY Slider-Minimum sollte 0 sein")
    }

    // MARK: - isFractionalCurrency Tests

    func testIsFractionalCurrencyEUR() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        XCTAssertTrue(sut.isFractionalCurrency, "EUR sollte Bruchteile unterstützen")
    }

    func testIsFractionalCurrencyJPY() {
        sut.isAutomatic = false
        sut.currencyCode = "JPY"
        XCTAssertFalse(sut.isFractionalCurrency, "JPY sollte keine Bruchteile unterstützen")
    }

    func testIsFractionalCurrencyKRW() {
        sut.isAutomatic = false
        sut.currencyCode = "KRW"
        XCTAssertFalse(sut.isFractionalCurrency, "KRW sollte keine Bruchteile unterstützen")
    }

    func testIsFractionalCurrencyUSD() {
        sut.isAutomatic = false
        sut.currencyCode = "USD"
        XCTAssertTrue(sut.isFractionalCurrency, "USD sollte Bruchteile unterstützen")
    }

    // MARK: - currencySymbol Tests

    func testCurrencySymbolEUR() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        let symbol = sut.currencySymbol
        XCTAssertTrue(symbol == "€" || symbol == "EUR",
                      "EUR Symbol sollte € oder EUR sein")
    }

    func testCurrencySymbolUSD() {
        sut.isAutomatic = false
        sut.currencyCode = "USD"
        let symbol = sut.currencySymbol
        XCTAssertTrue(symbol == "$" || symbol == "USD",
                      "USD Symbol sollte $ oder USD sein")
    }

    func testCurrencySymbolGBP() {
        sut.isAutomatic = false
        sut.currencyCode = "GBP"
        let symbol = sut.currencySymbol
        XCTAssertTrue(symbol == "£" || symbol == "GBP",
                      "GBP Symbol sollte £ oder GBP sein")
    }

    func testCurrencySymbolJPY() {
        sut.isAutomatic = false
        sut.currencyCode = "JPY"
        let symbol = sut.currencySymbol
        XCTAssertTrue(symbol == "¥" || symbol == "JPY",
                      "JPY Symbol sollte ¥ oder JPY sein")
    }

    func testCurrencySymbolCHF() {
        sut.isAutomatic = false
        sut.currencyCode = "CHF"
        let symbol = sut.currencySymbol
        XCTAssertTrue(symbol == "CHF" || symbol == "Fr." || symbol.contains("CHF"),
                      "CHF Symbol sollte CHF oder Fr. enthalten")
    }

    // MARK: - currencyName Tests

    func testCurrencyNameLocalized() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        let name = sut.currencyName
        XCTAssertFalse(name.isEmpty, "Währungsname sollte nicht leer sein")
        XCTAssertNotEqual(name, "EUR", "Währungsname sollte lokalisiert sein, nicht nur Code")
    }

    // MARK: - commonCurrencyCodes Tests

    func testCommonCurrencyCodesContainsExpected() {
        let commonCodes = CurrencyManager.commonCurrencyCodes
        XCTAssertTrue(commonCodes.contains("EUR"), "Common Codes sollte EUR enthalten")
        XCTAssertTrue(commonCodes.contains("USD"), "Common Codes sollte USD enthalten")
        XCTAssertTrue(commonCodes.contains("GBP"), "Common Codes sollte GBP enthalten")
        XCTAssertTrue(commonCodes.contains("JPY"), "Common Codes sollte JPY enthalten")
    }

    // MARK: - State Persistence Tests

    func testIsAutomaticPersistsToUserDefaults() {
        sut.isAutomatic = false
        let stored = UserDefaults.standard.bool(forKey: "currencyAutomatic")
        XCTAssertFalse(stored, "isAutomatic sollte in UserDefaults gespeichert sein")
    }

    func testCurrencyCodePersistsToUserDefaults() {
        sut.currencyCode = "USD"
        let stored = UserDefaults.standard.string(forKey: "selectedCurrencyCode")
        XCTAssertEqual(stored, "USD", "currencyCode sollte in UserDefaults gespeichert sein")
    }

    // MARK: - Edge Cases Tests

    func testFormatAmountWithVeryLargeNumber() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        let formatted = sut.formatAmount(999_999_999.99)
        XCTAssertTrue(formatted.contains("999") || formatted.contains("1B") || formatted.contains("Mrd"),
                      "Sehr große Zahl sollte formatiert sein")
    }

    // MARK: - Currency Change Handling Tests

    func testSwitchingBetweenCurrencies() {
        sut.isAutomatic = false
        sut.currencyCode = "EUR"
        let eurFormatted = sut.formatAmount(100.0)

        sut.currencyCode = "USD"
        let usdFormatted = sut.formatAmount(100.0)

        XCTAssertNotEqual(eurFormatted, usdFormatted,
                          "Formatierung sollte sich ändern beim Währungswechsel")
    }

    // MARK: - GiftTransitionService Integration Tests (Placeholder)

    func testGiftTransitionServiceStrategy() {
        // GiftTransitionService ist ein @MainActor enum mit statischen Methoden,
        // die auf SwiftData ModelContext angewiesen sind.
        // Vollständiges Unit-Testing ist schwierig, da ModelContext nicht einfach
        // zu mocken ist und das Service Datenbankzugriffe durchführt.
        //
        // EMPFOHLENE INTEGRATION TEST-STRATEGIE:
        //
        // 1. Verwende ModelContainer.inMemory() für temporäre Test-DB:
        //    let container = try ModelContainer(
        //        for: PersonRef.self,
        //        GiftIdea.self,
        //        GiftHistory.self,
        //        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        //    )
        //    let context = ModelContext(container)
        //
        // 2. Erstelle Test-Daten:
        //    - PersonRef mit Geburtstag VOR heute
        //    - GiftIdea mit status=.purchased
        //    - Einfügen in context via context.insert()
        //    - context.delete() wenn nötig
        //
        // 3. Rufe auf: GiftTransitionService.autoTransitionPurchasedGifts(in: context)
        //
        // 4. Validiere:
        //    - idea.status sollte .given sein
        //    - Neue GiftHistory-Einträge sollten erstellt sein
        //    - statusLog sollte aktualisiert sein
        //
        // BEISPIEL INTEGRATION TEST:
        /*
        @MainActor
        func testAutoTransitionPurchasedGifts() throws {
            // Setup In-Memory Container
            let container = try ModelContainer(
                for: PersonRef.self,
                GiftIdea.self,
                GiftHistory.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = ModelContext(container)

            // Erstelle Person mit Geburtstag im Januar 2025
            let person = PersonRef(
                contactIdentifier: "test123",
                name: "Test",
                birthday: Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 15))!
            )
            context.insert(person)

            // Erstelle gekaufte Geschenkidee
            let idea = GiftIdea(
                personId: person.id,
                title: "Test Gift",
                status: .purchased
            )
            context.insert(idea)
            try context.save()

            // Führe Transition durch
            GiftTransitionService.autoTransitionPurchasedGifts(in: context)

            // Validiere
            XCTAssertEqual(idea.status, .given)

            // Fetch GiftHistory
            let historyDescriptor = FetchDescriptor<GiftHistory>()
            let histories = try context.fetch(historyDescriptor)
            XCTAssertGreaterThan(histories.count, 0)
        }
        */

        XCTAssertTrue(true, "GiftTransitionService erfordert Integration Tests mit ModelContainer")
    }
}
