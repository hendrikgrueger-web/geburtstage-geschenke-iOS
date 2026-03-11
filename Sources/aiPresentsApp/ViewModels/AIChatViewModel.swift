import Foundation
import SwiftData
import SwiftUI

/// ViewModel für den KI-Chat. Orchestriert System-Prompt-Bau, API-Calls und Action-Processing.
@MainActor
@Observable
final class AIChatViewModel {
    var messages: [ChatMessage] = []
    var isLoading = false

    /// Wird gesetzt wenn eine Aktion ein Sheet öffnen soll.
    var pendingGiftIdeaPerson: PersonRef?
    var pendingGiftIdeaTitle: String = ""
    var pendingGiftIdeaNote: String = ""
    var pendingSuggestionsPerson: PersonRef?

    /// Matching Personen bei clarify_person — wird als tippbare Buttons angezeigt.
    var clarifyOptions: [PersonRef] = []

    private var people: [PersonRef] = []
    private var giftIdeas: [GiftIdea] = []
    private var giftHistory: [GiftHistory] = []
    private var modelContext: ModelContext?

    /// Short-ID → UUID Lookup-Maps (werden beim System-Prompt-Bau befüllt)
    private var personIdMap: [String: UUID] = [:]
    private var giftIdeaIdMap: [String: UUID] = [:]

    /// Gecachter System-Prompt — wird einmalig in configure() gebaut, nicht bei jeder Nachricht neu.
    private var cachedSystemPrompt: String = ""

    // MARK: - Setup

    func configure(people: [PersonRef], giftIdeas: [GiftIdea], giftHistory: [GiftHistory], modelContext: ModelContext) {
        self.people = people
        self.giftIdeas = giftIdeas
        self.giftHistory = giftHistory
        self.modelContext = modelContext
        cachedSystemPrompt = buildSystemPrompt()
    }

    /// Invalidiert den gecachten System-Prompt, z.B. nach Änderungen an giftIdeas/giftHistory.
    func invalidatePromptCache() {
        cachedSystemPrompt = buildSystemPrompt()
    }

    // MARK: - Senden

    func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        isLoading = true

        do {
            let apiMessages = buildAPIMessages()
            let response = try await AIService.shared.callOpenRouterChat(messages: apiMessages)

            let action = parseAction(from: response.action)
            let assistantMessage = ChatMessage(role: .assistant, content: response.message, action: action)
            messages.append(assistantMessage)

            if let action {
                await processAction(action)
            }
        } catch {
            let errorChat = ChatMessage(role: .assistant, content: String(localized: "Entschuldigung, es gab einen Fehler. Bitte versuche es erneut."))
            messages.append(errorChat)
            AppLogger.data.error("Chat-Fehler", error: error)
        }

        isLoading = false
    }

    // MARK: - API Messages

    private func buildAPIMessages() -> [[String: String]] {
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": cachedSystemPrompt]
        ]

        for msg in messages {
            switch msg.role {
            case .user:
                apiMessages.append(["role": "user", "content": msg.content])
            case .assistant:
                apiMessages.append(["role": "assistant", "content": msg.content])
            case .system:
                break
            }
        }

        return apiMessages
    }

    // MARK: - System Prompt

    private func buildSystemPrompt() -> String {
        // ID-Maps bei jedem Prompt-Bau neu aufbauen
        personIdMap.removeAll()
        giftIdeaIdMap.removeAll()

        let isGerman = Locale.current.language.languageCode?.identifier == "de"

        // Kompakter Prompt — eine Sprache, kurze Regeln, Short-IDs
        var prompt: String
        if isGerman {
            prompt = """
            Du bist der freundliche Geschenke-Assistent der App "AI Präsente".

            REGELN:
            - Antworte auf Deutsch, herzlich und natürlich wie ein guter Freund der bei Geschenken hilft.
            - Themen: Geburtstage, Geschenkideen, Geschenkplanung. Off-Topic freundlich ablehnen.
            - DATENSCHUTZ: Du erhältst KEINE echten Namen. Jede Person hat eine ID (z.B. p1) und eine Beziehung (z.B. "deine Schwester"). Verwende in deinen Antworten immer die Beziehung statt eines Namens.
            - Bei mehrdeutiger Beziehung: nachfragen wer gemeint ist.
            - WICHTIG: Short-IDs (p1, g1 etc.) sind NUR für die action-Felder. Schreibe NIEMALS Short-IDs in die message — verwende dort die Beziehung (z.B. "deine Mutter", "dein Freund").
            - WICHTIG: Wenn eine Beschreibung zu MEHREREN Kontakten passt, IMMER clarify_person verwenden und ALLE passenden Kontakte mit ihrer Beziehung und Altersgruppe auflisten.
            - Formuliere vollständige, natürliche Sätze. Nenne konkrete Daten (z.B. "am 15. April") statt nur Tage.
            - Bei Geschenkfragen: Berücksichtige Hobbies, Altersgruppe, Geschlecht, Beziehung und bisherige Geschenke.

            FORMAT: Antworte NUR mit JSON:
            {"message":"Deine natürliche Antwort hier","action":{"type":"none"}}

            Aktionstypen (in action.type):
            - create_gift_idea: person_id, person_name, gift_title, gift_note
            - query: (keine zusätzlichen Felder)
            - update_gift_status: gift_idea_id, new_status (planned|purchased|given)
            - open_suggestions: person_id, person_name — KI-Vorschläge-Sheet öffnen
            - clarify_person: (keine zusätzlichen Felder)
            - off_topic: (keine zusätzlichen Felder)
            - none: (keine zusätzlichen Felder)

            Beispiel: {"message":"Wie wäre es mit einem Buch für deine Schwester?","action":{"type":"create_gift_idea","person_id":"p1","person_name":"Schwester","gift_title":"Buch","gift_note":""}}
            """
        } else {
            prompt = """
            You are the friendly gift assistant of the app "AI Präsente".

            RULES:
            - Respond warmly and naturally, like a helpful friend who's great at gift-giving.
            - Topics: Birthdays, gift ideas, gift planning. Politely decline off-topic requests.
            - PRIVACY: You do NOT receive real names. Each person has an ID (e.g. p1) and a relationship (e.g. "your sister"). Always use the relationship in your responses instead of a name.
            - Ambiguous relationship: ask to clarify.
            - IMPORTANT: Short IDs (p1, g1 etc.) are ONLY for action fields. NEVER include short IDs in the message — always use the relationship (e.g. "your mother", "your friend").
            - IMPORTANT: If a description matches MULTIPLE contacts, ALWAYS use clarify_person and list ALL matching contacts by relationship and age group.
            - Use complete, natural sentences. Mention specific dates (e.g. "on April 15th") instead of just days.
            - For gift questions: Consider hobbies, age group, gender, relationship, and past gifts.

            FORMAT: Respond ONLY with JSON:
            {"message":"Your natural response here","action":{"type":"none"}}

            Action types (in action.type):
            - create_gift_idea: person_id, person_name, gift_title, gift_note
            - query: (no additional fields)
            - update_gift_status: gift_idea_id, new_status (planned|purchased|given)
            - open_suggestions: person_id, person_name — Open AI suggestions sheet
            - clarify_person: (no additional fields)
            - off_topic: (no additional fields)
            - none: (no additional fields)

            Example: {"message":"How about a book for your sister?","action":{"type":"create_gift_idea","person_id":"p1","person_name":"Sister","gift_title":"Book","gift_note":""}}
            """
        }

        // Kompakte Kontaktliste
        prompt += isGerman ? "\n\nKontakte:\n" : "\n\nContacts:\n"

        if people.isEmpty {
            prompt += "(keine)\n"
        } else {
            var giftCounter = 1
            for (index, person) in people.enumerated() {
                let pid = "p\(index + 1)"
                personIdMap[pid] = person.id

                prompt += buildCompactPersonEntry(person, shortId: pid, isGerman: isGerman, giftCounter: &giftCounter)
            }
        }

        return prompt
    }

    private func buildCompactPersonEntry(_ person: PersonRef, shortId: String, isGerman: Bool, giftCounter: inout Int) -> String {
        // Format: p1:weiblich|Mitte 30|10d|Freund/in|Reiten,Kochen
        // DATENSCHUTZ: Kein Name, kein Geburtstag (Tag/Monat), kein exaktes Alter
        let firstName = person.displayName.split(separator: " ").first.map(String.init) ?? person.displayName
        let gender = GenderInference.infer(relation: person.relation, firstName: firstName)

        var parts: [String] = ["\(shortId):\(isGerman ? gender.localizedLabel : gender.englishLabel)"]

        if person.birthYearKnown {
            let exactAge = BirthdayDateHelper.age(from: person.birthday)
            parts.append(AgeObfuscator.approximateAge(exactAge))
        }

        if let days = BirthdayDateHelper.daysUntilBirthday(from: person.birthday) {
            parts.append(days == 0 ? "HEUTE!" : "\(days)d")
        }

        parts.append(person.relation)

        if !person.hobbies.isEmpty {
            parts.append(person.hobbies.joined(separator: ","))
        }

        if person.skipGift {
            parts.append("skip")
        }

        var entry = parts.joined(separator: "|")

        // Geschenkideen kompakt
        let ideas = giftIdeas.filter { $0.personId == person.id }
        if !ideas.isEmpty {
            let ideaParts = ideas.map { idea -> String in
                let gid = "g\(giftCounter)"
                giftIdeaIdMap[gid] = idea.id
                giftCounter += 1
                return "\(gid):\(idea.title)[\(idea.status.rawValue)]"
            }
            entry += " >" + ideaParts.joined(separator: ",")
        }

        // Geschenkhistorie kompakt (nur Titel, keine Jahreszahlen — DATENSCHUTZ, max 3)
        let history = giftHistory.filter { $0.personId == person.id }
            .sorted { $0.year > $1.year }
            .prefix(3)
        if !history.isEmpty {
            let histParts = history.map { $0.title }
            entry += " h:" + histParts.joined(separator: ",")
        }

        entry += "\n"
        return entry
    }

    // MARK: - Action Parsing

    private func parseAction(from json: ChatActionJSON?) -> ChatAction? {
        guard let json else { return nil }
        guard let type = ChatAction.ActionType(rawValue: json.type) else { return nil }

        let data = ActionData(
            personId: json.personId,
            personName: json.personName,
            giftTitle: json.giftTitle,
            giftNote: json.giftNote,
            newStatus: json.newStatus,
            giftIdeaId: json.giftIdeaId
        )
        return ChatAction(type: type, data: data)
    }

    // MARK: - Action Processing

    /// Löst eine Short-ID (z.B. "p1") oder volle UUID zu einer PersonRef auf.
    private func resolvePerson(from idString: String?) -> PersonRef? {
        guard let idString else { return nil }
        let lower = idString.lowercased()
        // Short-ID Lookup
        if let uuid = personIdMap[lower] ?? personIdMap[idString] {
            return people.first { $0.id == uuid }
        }
        // Fallback: volle UUID
        if let uuid = UUID(uuidString: idString) {
            return people.first { $0.id == uuid }
        }
        // Exakter Name-Match
        if let exact = people.first(where: { $0.displayName.lowercased() == lower }) {
            return exact
        }
        // Teilname-Match (Vorname oder Nachname)
        return people.first { $0.displayName.lowercased().contains(lower) }
    }

    /// Löst eine Short-ID (z.B. "g1") oder volle UUID zu einer GiftIdea auf.
    private func resolveGiftIdea(from idString: String?) -> GiftIdea? {
        guard let idString else { return nil }
        if let uuid = giftIdeaIdMap[idString] {
            return giftIdeas.first { $0.id == uuid }
        }
        if let uuid = UUID(uuidString: idString) {
            return giftIdeas.first { $0.id == uuid }
        }
        return nil
    }

    func processAction(_ action: ChatAction) async {
        guard let data = action.data else { return }

        switch action.type {
        case .createGiftIdea:
            guard let person = resolvePerson(from: data.personId) ?? resolvePerson(from: data.personName) else { return }
            pendingGiftIdeaTitle = data.giftTitle ?? ""
            pendingGiftIdeaNote = data.giftNote ?? ""
            pendingGiftIdeaPerson = person

        case .openSuggestions:
            guard let person = resolvePerson(from: data.personId) ?? resolvePerson(from: data.personName) else {
                AppLogger.data.error("openSuggestions: Person nicht gefunden — personId=\(data.personId ?? "nil"), personName=\(data.personName ?? "nil")")
                return
            }
            pendingSuggestionsPerson = person

        case .updateGiftStatus:
            guard let idea = resolveGiftIdea(from: data.giftIdeaId),
                  let newStatusStr = data.newStatus,
                  let newStatus = GiftStatus(rawValue: newStatusStr) else { return }

            let dateString = FormatterHelper.shortLogDateFormatter.string(from: Date())
            let oldStatus = idea.status
            idea.statusLog.append("\(dateString) - \(oldStatus.rawValue) \u{2192} \(newStatus.rawValue)")
            idea.status = newStatus
            HapticFeedback.success()

        case .clarifyPerson:
            // Finde alle Personen deren Name im letzten User-Message erwähnt wurde
            if let lastUserMessage = messages.last(where: { $0.role == .user })?.content.lowercased() {
                clarifyOptions = people.filter { person in
                    let firstName = person.displayName.split(separator: " ").first.map(String.init) ?? person.displayName
                    return lastUserMessage.contains(firstName.lowercased())
                }
            }

        case .query, .offTopic, .none:
            break
        }
    }

    // MARK: - Welcome Chips

    var welcomeChips: [(label: String, message: String)] {
        let isGerman = Locale.current.language.languageCode?.identifier == "de"
        var chips: [(String, String)] = []

        // Nächster Geburtstag
        let today = Calendar.current.startOfDay(for: Date())
        if let nextPerson = people
            .compactMap({ person -> (PersonRef, Int)? in
                guard let days = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) else { return nil }
                return (person, days)
            })
            .sorted(by: { $0.1 < $1.1 })
            .first {
            let name = nextPerson.0.displayName
            chips.append((
                isGerman ? "Wann hat \(name) Geburtstag?" : "When is \(name)'s birthday?",
                isGerman ? "Wann hat \(name) Geburtstag?" : "When is \(name)'s birthday?"
            ))
        }

        // Geschenkidee vorschlagen
        if let person = people.first {
            chips.append((
                isGerman ? "Idee für \(person.displayName)" : "Idea for \(person.displayName)",
                isGerman ? "Schlage Geschenke für \(person.displayName) vor" : "Suggest gifts for \(person.displayName)"
            ))
        }

        // Allgemeine Chips
        chips.append((
            isGerman ? "Wer hat bald Geburtstag?" : "Who has a birthday soon?",
            isGerman ? "Wer hat in den nächsten 7 Tagen Geburtstag?" : "Who has a birthday in the next 7 days?"
        ))

        // Geschenkidee-Eintrag Beispiel
        if let person = people.first {
            chips.append((
                isGerman ? "Kinogutschein für \(person.displayName) eintragen" : "Add cinema voucher for \(person.displayName)",
                isGerman ? "Trag einen Kinogutschein als Geschenkidee für \(person.displayName) ein" : "Add a cinema voucher as a gift idea for \(person.displayName)"
            ))
        }

        return chips
    }
}
