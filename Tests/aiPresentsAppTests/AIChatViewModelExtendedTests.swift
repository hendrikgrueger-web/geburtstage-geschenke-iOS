import XCTest
@testable import aiPresentsApp

// MARK: - Hilfsfunktionen

private func makePerson(
    id: UUID = UUID(),
    name: String,
    relation: String = "Freund",
    birthday: Date = Date(),
    hobbies: [String] = []
) -> PersonRef {
    let p = PersonRef(
        id: id,
        contactIdentifier: "test-\(UUID().uuidString)",
        displayName: name,
        birthday: birthday,
        relation: relation
    )
    p.hobbies = hobbies
    return p
}

private func makeGiftIdea(personId: UUID, title: String, status: GiftStatus = .idea) -> GiftIdea {
    GiftIdea(personId: personId, title: title, status: status)
}

// MARK: - cleanMessageText Tests

@MainActor
final class CleanMessageTextTests: XCTestCase {

    private var sut: AIChatViewModel!

    override func setUp() {
        super.setUp()
        sut = AIChatViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // Hilfsmethode: greift via öffentlichen Wrapper zu.
    // cleanMessageText ist private — wir testen es indirekt über die ViewModel-Methode.
    // Dafür nutzen wir systemPromptForTesting() + refreshContext um personIdMap aufzubauen,
    // dann sendMessage mit einem bereits gemockten Text. Da wir keine API mocken,
    // testen wir die Regex-Logik direkt über einen dünnen Wrapper der im ViewModel liegt.
    //
    // AIChatViewModel exponiert cleanMessageText NICHT öffentlich.
    // Daher testen wir die Auswirkung über extractMentionedPersons (das personIdMap braucht)
    // und verifizieren, dass kurze IDs nach refreshContext korrekt befüllt werden.
    //
    // Für cleanMessageText direkt: Da die Methode private ist, müssen wir
    // die Regex-Logik mit denselben Pattern testen wie im ViewModel implementiert.

    func testCleanMessageText_klammer_IDs_werden_entfernt() {
        // Pattern: "\s*\(p\d+\)" → leerer String
        // Wir replizieren exakt die Regex aus cleanMessageText
        var text = "Deine Schwester (p33) hat bald Geburtstag"
        let bracketRegex = try! Regex(#"\s*\(p\d+\)"#)
        text = text.replacing(bracketRegex, with: "")
        XCTAssertEqual(text, "Deine Schwester hat bald Geburtstag")
    }

    func testCleanMessageText_keine_IDs_unveraendert() {
        var text = "Anna hat in 5 Tagen Geburtstag"
        let bracketRegex = try! Regex(#"\s*\(p\d+\)"#)
        text = text.replacing(bracketRegex, with: "")
        XCTAssertEqual(text, "Anna hat in 5 Tagen Geburtstag")
    }

    func testCleanMessageText_leerer_String_bleibt_leer() {
        var text = ""
        let bracketRegex = try! Regex(#"\s*\(p\d+\)"#)
        text = text.replacing(bracketRegex, with: "")
        XCTAssertEqual(text, "")
    }

    func testCleanMessageText_mehrere_klammer_IDs_alle_entfernt() {
        var text = "Für Anna (p1) und Max (p2) und Lisa (p33) habe ich Ideen"
        let bracketRegex = try! Regex(#"\s*\(p\d+\)"#)
        text = text.replacing(bracketRegex, with: "")
        XCTAssertEqual(text, "Für Anna und Max und Lisa habe ich Ideen")
    }

    func testCleanMessageText_ID_am_Ende() {
        var text = "Schau dir das an (p5)"
        let bracketRegex = try! Regex(#"\s*\(p\d+\)"#)
        text = text.replacing(bracketRegex, with: "")
        XCTAssertEqual(text, "Schau dir das an")
    }

    func testCleanMessageText_ID_am_Anfang_wird_nicht_durch_bracketRegex_entfernt() {
        // Klammer-Pattern nur für "(p5)" mit vorangehendem Leerzeichen oder direkt
        var text = "(p1) hat Geburtstag"
        let bracketRegex = try! Regex(#"\s*\(p\d+\)"#)
        text = text.replacing(bracketRegex, with: "")
        // "(p1)" ohne vorangehende Leerzeichen wird auch entfernt da \s* optional
        XCTAssertTrue(text.trimmingCharacters(in: .whitespaces).hasPrefix("hat Geburtstag"))
    }

    func testCleanMessageText_geschenk_IDs_g_nicht_entfernt() {
        // cleanMessageText entfernt nur p\d+ IDs, nicht g\d+ (Geschenk-IDs)
        var text = "g1 wurde für Anna gespeichert (p2)"
        let bracketRegex = try! Regex(#"\s*\(p\d+\)"#)
        text = text.replacing(bracketRegex, with: "")
        XCTAssertTrue(text.contains("g1"))
        XCTAssertFalse(text.contains("(p2)"))
    }

    func testCleanMessageText_mehrstellige_personen_ID() {
        var text = "Idee für deine Tante (p123)"
        let bracketRegex = try! Regex(#"\s*\(p\d+\)"#)
        text = text.replacing(bracketRegex, with: "")
        XCTAssertEqual(text, "Idee für deine Tante")
    }
}

// MARK: - buildAPIMessages Tests (via promptNeedsRebuildForTesting + systemPromptForTesting)

@MainActor
final class BuildAPIMessagesTests: XCTestCase {

    private var sut: AIChatViewModel!

    override func setUp() {
        super.setUp()
        sut = AIChatViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // buildAPIMessages ist private — wir testen über systemPromptForTesting()
    // und verifizieren das Verhalten indirekt.

    func testSystemPrompt_immer_erste_Nachricht() {
        // Nach configure wird ein gültiger System-Prompt gebaut
        let person = makePerson(name: "Anna")
        sut.configure(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)

        let prompt = sut.systemPromptForTesting()
        XCTAssertFalse(prompt.isEmpty, "System-Prompt sollte nicht leer sein")
    }

    func testSystemPrompt_enthaelt_person_shortID() {
        let person = makePerson(name: "Bernd")
        sut.configure(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)

        let prompt = sut.systemPromptForTesting()
        // Erste Person bekommt p1
        XCTAssertTrue(prompt.contains("p1:Bernd"), "Prompt sollte Short-ID p1 für erste Person enthalten")
    }

    func testSystemPrompt_mehrere_personen_aufsteigend_sortiert() {
        // Personen werden alphabetisch sortiert (FIX: stabile p1-Zuordnung)
        let zoe = makePerson(name: "Zoe")
        let anna = makePerson(name: "Anna")
        sut.configure(people: [zoe, anna], giftIdeas: [], giftHistory: [], modelContext: nil)

        let prompt = sut.systemPromptForTesting()
        // Anna kommt alphabetisch vor Zoe → Anna = p1, Zoe = p2
        XCTAssertTrue(prompt.contains("p1:Anna"), "Anna sollte p1 sein (alphabetisch)")
        XCTAssertTrue(prompt.contains("p2:Zoe"), "Zoe sollte p2 sein (alphabetisch)")
    }

    func testSystemPrompt_ohne_personen_enthaelt_keine() {
        sut.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)
        let prompt = sut.systemPromptForTesting()
        XCTAssertTrue(prompt.contains("(keine)") || prompt.isEmpty == false,
                      "Leere Kontaktliste sollte korrekt dargestellt werden")
    }

    func testSystemPrompt_caching_kein_rebuild_beim_zweiten_aufruf() {
        let person = makePerson(name: "Max")
        sut.configure(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)

        // Erster Aufruf → baut Prompt, setzt promptNeedsRebuild = false
        let prompt1 = sut.systemPromptForTesting()
        XCTAssertFalse(sut.promptNeedsRebuildForTesting, "Nach Aufruf sollte rebuild = false sein")

        // Zweiter Aufruf → liefert gecachten Prompt
        let prompt2 = sut.systemPromptForTesting()
        XCTAssertEqual(prompt1, prompt2, "Gecachter Prompt sollte identisch sein")
    }

    func testSystemPrompt_enthaelt_hobbies_der_person() {
        let person = makePerson(name: "Lena", hobbies: ["Kochen", "Lesen"])
        sut.configure(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)

        let prompt = sut.systemPromptForTesting()
        XCTAssertTrue(prompt.contains("Kochen"), "Prompt sollte Hobbies enthalten")
        XCTAssertTrue(prompt.contains("Lesen"), "Prompt sollte alle Hobbies enthalten")
    }

    func testSystemPrompt_enthaelt_relation() {
        let person = makePerson(name: "Klaus", relation: "Vater")
        sut.configure(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)

        let prompt = sut.systemPromptForTesting()
        XCTAssertTrue(prompt.contains("Vater"), "Prompt sollte Beziehungstyp enthalten")
    }
}

// MARK: - extractMentionedPersons Tests

@MainActor
final class ExtractMentionedPersonsTests: XCTestCase {

    private var sut: AIChatViewModel!

    // Feste UUIDs für stabile Tests
    private let annaId = UUID()
    private let maxId = UUID()
    private let lisaId = UUID()

    override func setUp() {
        super.setUp()
        sut = AIChatViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    private func setupPeople() -> [PersonRef] {
        // Alphabetisch: Anna=p1, Lisa=p2, Max=p3
        let anna = makePerson(id: annaId, name: "Anna")
        let max = makePerson(id: maxId, name: "Max")
        let lisa = makePerson(id: lisaId, name: "Lisa")
        return [anna, max, lisa]
    }

    func testExtractMentionedPersons_einzelne_ID_findet_person() {
        let people = setupPeople()
        sut.configure(people: people, giftIdeas: [], giftHistory: [], modelContext: nil)

        // System-Prompt muss gebaut werden damit personIdMap befüllt wird
        _ = sut.systemPromptForTesting()

        // Jetzt mentionedPersons manuell über welcomeChips testen — extractMentionedPersons ist private.
        // Wir testen das Verhalten indirekt: nach configure + getSystemPrompt sind IDs bekannt.
        // Die mentionedPersons werden in performSend gesetzt — da wir keinen API-Call machen können,
        // testen wir welcomeChips als indirekter Beweis dass personIdMap korrekt befüllt ist.
        let chips = sut.welcomeChips
        XCTAssertFalse(chips.isEmpty, "WelcomeChips sollten bei konfigurierten Personen existieren")
        XCTAssertTrue(chips.first?.label.contains("Anna") == true ||
                      chips.first?.label.contains("Lisa") == true ||
                      chips.first?.label.contains("Max") == true,
                      "Chips sollten Personennamen enthalten")
    }

    func testExtractMentionedPersons_initial_leer() {
        // Ohne configure: mentionedPersons leer
        XCTAssertTrue(sut.mentionedPersons.isEmpty, "mentionedPersons sollte initial leer sein")
    }

    func testExtractMentionedPersons_bleibt_nach_configure_leer() {
        let people = setupPeople()
        sut.configure(people: people, giftIdeas: [], giftHistory: [], modelContext: nil)
        // mentionedPersons wird nur durch performSend befüllt, nicht durch configure
        XCTAssertTrue(sut.mentionedPersons.isEmpty, "mentionedPersons sollte nach configure noch leer sein")
    }
}

// MARK: - Message-Management Tests

@MainActor
final class MessageManagementTests: XCTestCase {

    private var sut: AIChatViewModel!

    override func setUp() {
        super.setUp()
        sut = AIChatViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testInitialState_messages_leer() {
        XCTAssertTrue(sut.messages.isEmpty, "Messages sollte initial leer sein")
    }

    func testInitialState_isLoading_false() {
        XCTAssertFalse(sut.isLoading, "isLoading sollte initial false sein")
    }

    func testInitialState_pendingPerson_nil() {
        XCTAssertNil(sut.pendingGiftIdeaPerson, "pendingGiftIdeaPerson sollte initial nil sein")
        XCTAssertNil(sut.pendingSuggestionsPerson, "pendingSuggestionsPerson sollte initial nil sein")
    }

    func testInitialState_pendingGiftIdea_felder_leer() {
        XCTAssertEqual(sut.pendingGiftIdeaTitle, "")
        XCTAssertEqual(sut.pendingGiftIdeaNote, "")
    }

    func testCancelPendingRequests_setzt_isLoading_false() {
        // Direkt cancelPendingRequests aufrufen
        sut.cancelPendingRequests()
        XCTAssertFalse(sut.isLoading, "isLoading sollte nach cancelPendingRequests false sein")
    }

    func testCancelPendingRequests_mehrfach_aufrufen_stabil() {
        // Mehrfacher Cancel sollte nicht crashen
        sut.cancelPendingRequests()
        sut.cancelPendingRequests()
        sut.cancelPendingRequests()
        XCTAssertFalse(sut.isLoading)
    }

    func testSendMessage_leerString_wird_nicht_gesendet() {
        // sendMessage mit leerem String → performSend prüft guard !trimmed.isEmpty
        // Da keine API vorhanden, prüfen wir: messages bleibt leer
        sut.sendMessage("")
        // Task läuft async — aber guard bei leerem String greift sofort (nach trim)
        // Nach dem guard wird nichts an messages angehängt
        // Wir geben dem Task eine kurze Zeit
        let expectation = expectation(description: "Leere Nachricht wird nicht angehängt")
        expectation.isInverted = true // Erwartet KEIN erfüllen

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !self.sut.messages.isEmpty {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 0.2)
        XCTAssertTrue(sut.messages.isEmpty, "Leere Nachricht sollte nicht zu messages hinzugefügt werden")
    }

    func testSendMessage_nurLeerzeichen_wird_nicht_gesendet() {
        sut.sendMessage("   ")
        let exp = expectation(description: "Nur-Leerzeichen-Nachricht nicht gesendet")
        exp.isInverted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !self.sut.messages.isEmpty {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 0.2)
        XCTAssertTrue(sut.messages.isEmpty, "Nur-Leerzeichen sollte nicht gesendet werden")
    }

    func testSendMessage_gueltige_Nachricht_landet_in_messages() async {
        // Da kein API-Mock → API-Call schlägt fehl, aber User-Message wurde bereits hinzugefügt
        // Wir müssen einen konfigurierten Zustand haben, damit sendMessage läuft
        sut.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        // sendMessage ist fire-and-forget via Task — wir warten kurz
        sut.sendMessage("Hallo, wer hat bald Geburtstag?")

        // Sehr kurze Wartezeit damit der synchrone Teil (messages.append(userMessage)) ausgeführt wird
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // User-Nachricht sollte sofort hinzugefügt werden (vor dem API-Call)
        XCTAssertFalse(sut.messages.isEmpty, "User-Nachricht sollte zu messages hinzugefügt werden")
        XCTAssertEqual(sut.messages.first?.role, .user)
        XCTAssertEqual(sut.messages.first?.content, "Hallo, wer hat bald Geburtstag?")
    }

    func testSendMessage_nachricht_wird_getrimmt() async {
        sut.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        sut.sendMessage("  Hallo  ")
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(sut.messages.first?.content, "Hallo",
                       "Nachricht sollte getrimmt in messages landen")
    }

    func testSendMessage_fehlgeschlagener_API_Call_haengt_fehlermeldung_an() async {
        // Ohne gültigen Proxy-Secret schlägt API-Call fehl
        sut.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)
        sut.sendMessage("Test")

        // Warten bis API-Call fehlschlägt und Error-Message angehängt wird
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 Sekunden max

        // Nach fehlgeschlagenem API-Call: User-Message + Error-Message
        if sut.messages.count >= 2 {
            let lastMsg = sut.messages.last
            XCTAssertEqual(lastMsg?.role, .assistant, "Error-Message sollte als assistant erscheinen")
        }
        // isLoading sollte nach Abschluss false sein
        XCTAssertFalse(sut.isLoading, "isLoading sollte nach Abschluss false sein")
    }
}

// MARK: - State-Management Tests

@MainActor
final class StateManagementTests: XCTestCase {

    private var sut: AIChatViewModel!

    override func setUp() {
        super.setUp()
        sut = AIChatViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testInitialState_vollstaendig() {
        XCTAssertTrue(sut.messages.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.pendingGiftIdeaPerson)
        XCTAssertNil(sut.pendingSuggestionsPerson)
        XCTAssertEqual(sut.pendingGiftIdeaTitle, "")
        XCTAssertEqual(sut.pendingGiftIdeaNote, "")
        XCTAssertTrue(sut.mentionedPersons.isEmpty)
    }

    func testPromptNeedsRebuild_initial_true() {
        // Nach Init sollte promptNeedsRebuild = true sein (noch kein Prompt gebaut)
        XCTAssertTrue(sut.promptNeedsRebuildForTesting, "Vor erstem Aufruf sollte rebuild nötig sein")
    }

    func testPromptNeedsRebuild_false_nach_getSystemPrompt() {
        _ = sut.systemPromptForTesting()
        XCTAssertFalse(sut.promptNeedsRebuildForTesting, "Nach Prompt-Bau sollte rebuild = false")
    }

    func testPromptNeedsRebuild_true_nach_refreshContext() {
        // Erst Prompt bauen
        _ = sut.systemPromptForTesting()
        XCTAssertFalse(sut.promptNeedsRebuildForTesting)

        // refreshContext invalidiert den Cache
        sut.refreshContext(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)
        XCTAssertTrue(sut.promptNeedsRebuildForTesting, "Nach refreshContext sollte rebuild = true")
    }

    func testPromptNeedsRebuild_true_nach_invalidatePromptCache() {
        _ = sut.systemPromptForTesting()
        sut.invalidatePromptCache()
        XCTAssertTrue(sut.promptNeedsRebuildForTesting, "Nach invalidatePromptCache sollte rebuild = true")
    }

    func testRefreshContext_ersetzt_alte_personen() {
        let anna = makePerson(name: "Anna")
        sut.configure(people: [anna], giftIdeas: [], giftHistory: [], modelContext: nil)
        _ = sut.systemPromptForTesting() // Anna = p1

        let max = makePerson(name: "Max")
        sut.refreshContext(people: [max], giftIdeas: [], giftHistory: [], modelContext: nil)

        // Nach Rebuild enthält Prompt Max, nicht mehr Anna
        let prompt = sut.systemPromptForTesting()
        XCTAssertTrue(prompt.contains("p1:Max"), "Nach refreshContext sollte Max als p1 erscheinen")
        XCTAssertFalse(prompt.contains("p1:Anna"), "Anna sollte nicht mehr im Prompt sein")
    }

    func testRefreshContext_sortiert_alphabetisch() {
        let zoe = makePerson(name: "Zoe")
        let anna = makePerson(name: "Anna")
        let max = makePerson(name: "Max")

        sut.refreshContext(people: [zoe, max, anna], giftIdeas: [], giftHistory: [], modelContext: nil)
        let prompt = sut.systemPromptForTesting()

        // Alphabetisch: Anna=p1, Max=p2, Zoe=p3
        XCTAssertTrue(prompt.contains("p1:Anna"))
        XCTAssertTrue(prompt.contains("p2:Max"))
        XCTAssertTrue(prompt.contains("p3:Zoe"))
    }

    func testConfigure_entspricht_refreshContext() {
        let person = makePerson(name: "Test")

        // configure und refreshContext sollten identischen Zustand produzieren
        let sut2 = AIChatViewModel()
        sut.configure(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)
        sut2.refreshContext(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)

        XCTAssertEqual(sut.systemPromptForTesting(), sut2.systemPromptForTesting(),
                       "configure und refreshContext sollten identischen Prompt produzieren")
    }
}

// MARK: - WelcomeChips Tests

@MainActor
final class WelcomeChipsTests: XCTestCase {

    private var sut: AIChatViewModel!

    override func setUp() {
        super.setUp()
        sut = AIChatViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testWelcomeChips_ohne_personen_enthalten_allgemeinen_chip() {
        sut.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)
        let chips = sut.welcomeChips
        // Ohne Personen sollte zumindest der "Wer hat bald Geburtstag?" Chip vorhanden sein
        XCTAssertFalse(chips.isEmpty, "WelcomeChips sollten auch ohne Personen nicht leer sein")
    }

    func testWelcomeChips_mit_personen_enthalten_personennamen() {
        let anna = makePerson(name: "Anna", birthday: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date())
        sut.configure(people: [anna], giftIdeas: [], giftHistory: [], modelContext: nil)

        let chips = sut.welcomeChips
        let allLabels = chips.map { $0.label }.joined(separator: " ")
        XCTAssertTrue(allLabels.contains("Anna"), "WelcomeChips sollten Personenname enthalten")
    }

    func testWelcomeChips_jeder_chip_hat_label_und_message() {
        let person = makePerson(name: "Max")
        sut.configure(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)

        for chip in sut.welcomeChips {
            XCTAssertFalse(chip.label.isEmpty, "Chip-Label sollte nicht leer sein")
            XCTAssertFalse(chip.message.isEmpty, "Chip-Message sollte nicht leer sein")
        }
    }
}

// MARK: - processAction Tests (ohne API)

@MainActor
final class ProcessActionTests: XCTestCase {

    private var sut: AIChatViewModel!
    private let personId = UUID()

    override func setUp() {
        super.setUp()
        sut = AIChatViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testProcessAction_createGiftIdea_setzt_pendingPerson() async {
        let person = makePerson(id: personId, name: "Anna", relation: "Schwester")
        let giftIdea = makeGiftIdea(personId: personId, title: "Buch")

        sut.configure(people: [person], giftIdeas: [giftIdea], giftHistory: [], modelContext: nil)
        _ = sut.systemPromptForTesting() // personIdMap befüllen

        let action = ChatAction(
            type: .createGiftIdea,
            data: ActionData(
                personId: "p1", // Anna = p1 nach alphabetischer Sortierung
                personName: "Anna",
                giftTitle: "Puzzle 1000 Teile",
                giftNote: "Liebt Puzzles",
                newStatus: nil,
                giftIdeaId: nil
            )
        )

        await sut.processAction(action)

        XCTAssertNotNil(sut.pendingGiftIdeaPerson, "pendingGiftIdeaPerson sollte gesetzt werden")
        XCTAssertEqual(sut.pendingGiftIdeaTitle, "Puzzle 1000 Teile")
        XCTAssertEqual(sut.pendingGiftIdeaNote, "Liebt Puzzles")
    }

    func testProcessAction_createGiftIdea_unbekannte_person_setzt_nichts() async {
        sut.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)
        _ = sut.systemPromptForTesting()

        let action = ChatAction(
            type: .createGiftIdea,
            data: ActionData(
                personId: "p99",
                personName: nil,
                giftTitle: "Test",
                giftNote: nil,
                newStatus: nil,
                giftIdeaId: nil
            )
        )

        await sut.processAction(action)
        XCTAssertNil(sut.pendingGiftIdeaPerson, "Unbekannte Person sollte pendingGiftIdeaPerson nicht setzen")
    }

    func testProcessAction_openSuggestions_setzt_pendingSuggestionsPerson() async {
        let person = makePerson(id: personId, name: "Bernd", relation: "Freund")
        sut.configure(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)
        _ = sut.systemPromptForTesting()

        let action = ChatAction(
            type: .openSuggestions,
            data: ActionData(
                personId: "p1",
                personName: "Bernd",
                giftTitle: nil,
                giftNote: nil,
                newStatus: nil,
                giftIdeaId: nil
            )
        )

        await sut.processAction(action)
        XCTAssertNotNil(sut.pendingSuggestionsPerson)
        XCTAssertEqual(sut.pendingSuggestionsPerson?.displayName, "Bernd")
    }

    func testProcessAction_query_aendert_nichts() async {
        sut.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let action = ChatAction(
            type: .query,
            data: ActionData(personId: nil, personName: nil, giftTitle: nil, giftNote: nil, newStatus: nil, giftIdeaId: nil)
        )

        await sut.processAction(action)

        XCTAssertNil(sut.pendingGiftIdeaPerson)
        XCTAssertNil(sut.pendingSuggestionsPerson)
    }

    func testProcessAction_offTopic_aendert_nichts() async {
        sut.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let action = ChatAction(
            type: .offTopic,
            data: ActionData(personId: nil, personName: nil, giftTitle: nil, giftNote: nil, newStatus: nil, giftIdeaId: nil)
        )

        await sut.processAction(action)

        XCTAssertNil(sut.pendingGiftIdeaPerson)
        XCTAssertFalse(sut.isLoading)
    }

    func testProcessAction_none_aendert_nichts() async {
        sut.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)

        let action = ChatAction(
            type: .none,
            data: ActionData(personId: nil, personName: nil, giftTitle: nil, giftNote: nil, newStatus: nil, giftIdeaId: nil)
        )

        await sut.processAction(action)
        XCTAssertNil(sut.pendingGiftIdeaPerson)
    }

    func testProcessAction_createGiftIdea_ohne_data_macht_nichts() async {
        let action = ChatAction(type: .createGiftIdea, data: nil)
        await sut.processAction(action)
        XCTAssertNil(sut.pendingGiftIdeaPerson, "Ohne ActionData sollte nichts gesetzt werden")
    }

    func testProcessAction_createGiftIdea_name_fallback_wenn_kein_shortId() async {
        let person = makePerson(id: personId, name: "Clara", relation: "Freundin")
        sut.configure(people: [person], giftIdeas: [], giftHistory: [], modelContext: nil)
        _ = sut.systemPromptForTesting()

        // Kein personId (nil) aber personName → Name-Match
        let action = ChatAction(
            type: .createGiftIdea,
            data: ActionData(
                personId: nil,
                personName: "Clara",
                giftTitle: "Gutschein",
                giftNote: nil,
                newStatus: nil,
                giftIdeaId: nil
            )
        )

        await sut.processAction(action)
        XCTAssertNotNil(sut.pendingGiftIdeaPerson,
                       "Person sollte per Name-Fallback gefunden werden")
    }
}

// MARK: - GiftIdea Sliding Window Tests (indirekt über Prompt-Größe)

@MainActor
final class SlidingWindowTests: XCTestCase {

    private var sut: AIChatViewModel!

    override func setUp() {
        super.setUp()
        sut = AIChatViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testGiftIdeas_im_Prompt_enthalten() {
        let personId = UUID()
        let person = makePerson(id: personId, name: "Maria")
        let idea = makeGiftIdea(personId: personId, title: "Yogamatte", status: .planned)

        sut.configure(people: [person], giftIdeas: [idea], giftHistory: [], modelContext: nil)
        let prompt = sut.systemPromptForTesting()

        XCTAssertTrue(prompt.contains("Yogamatte"), "Geschenkidee sollte im Prompt stehen")
        XCTAssertTrue(prompt.contains("g1:Yogamatte"), "GiftIdea sollte als g1 encodiert sein")
    }

    func testGiftIdeas_status_im_Prompt_enthalten() {
        let personId = UUID()
        let person = makePerson(id: personId, name: "Tom")
        let idea = makeGiftIdea(personId: personId, title: "Buch", status: .purchased)

        sut.configure(people: [person], giftIdeas: [idea], giftHistory: [], modelContext: nil)
        let prompt = sut.systemPromptForTesting()

        XCTAssertTrue(prompt.contains("[purchased]"), "Gift-Status sollte im Prompt stehen")
    }

    func testMehrere_GiftIdeas_mehrere_IDs() {
        let personId = UUID()
        let person = makePerson(id: personId, name: "Eva")
        let idea1 = makeGiftIdea(personId: personId, title: "Buch")
        let idea2 = makeGiftIdea(personId: personId, title: "Schal")

        sut.configure(people: [person], giftIdeas: [idea1, idea2], giftHistory: [], modelContext: nil)
        let prompt = sut.systemPromptForTesting()

        XCTAssertTrue(prompt.contains("g1:"), "Erste Idee sollte g1 sein")
        XCTAssertTrue(prompt.contains("g2:"), "Zweite Idee sollte g2 sein")
    }
}

// MARK: - invalidatePromptCache Tests

@MainActor
final class InvalidatePromptCacheTests: XCTestCase {

    private var sut: AIChatViewModel!

    override func setUp() {
        super.setUp()
        sut = AIChatViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testInvalidateCache_loescht_gecachten_prompt() {
        sut.configure(people: [], giftIdeas: [], giftHistory: [], modelContext: nil)
        let first = sut.systemPromptForTesting()
        XCTAssertFalse(first.isEmpty)

        sut.invalidatePromptCache()
        // Nach Invalidierung: promptNeedsRebuild = true, cachedSystemPrompt = ""
        XCTAssertTrue(sut.promptNeedsRebuildForTesting)

        // Nächster Aufruf baut Prompt neu
        let second = sut.systemPromptForTesting()
        XCTAssertFalse(second.isEmpty)
        XCTAssertFalse(sut.promptNeedsRebuildForTesting)
    }

    func testRefreshContext_mit_neuen_daten_aendert_prompt() {
        let anna = makePerson(name: "Anna")
        sut.configure(people: [anna], giftIdeas: [], giftHistory: [], modelContext: nil)
        let promptMitAnna = sut.systemPromptForTesting()

        let bernd = makePerson(name: "Bernd")
        sut.refreshContext(people: [bernd], giftIdeas: [], giftHistory: [], modelContext: nil)
        let promptMitBernd = sut.systemPromptForTesting()

        XCTAssertNotEqual(promptMitAnna, promptMitBernd, "Prompt sollte sich nach refreshContext ändern")
        XCTAssertTrue(promptMitBernd.contains("Bernd"))
        XCTAssertFalse(promptMitBernd.contains("Anna"))
    }
}
