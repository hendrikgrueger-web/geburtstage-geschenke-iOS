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

    /// Erwähnte Personen in der letzten AI-Antwort — wird als tippbare Karten angezeigt (max 3).
    var mentionedPersons: [PersonRef] = []

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
            // Short-IDs aus Nachrichtentext entfernen (p1 → Beziehungsname)
            let cleanedMessage = cleanMessageText(response.message)
            let assistantMessage = ChatMessage(role: .assistant, content: cleanedMessage, action: action)
            messages.append(assistantMessage)

            // Erwähnte Personen aus Nachricht + Action-Daten extrahieren (max 3)
            let actionJson = [response.action?.personId, response.action?.personName, response.action?.giftIdeaId]
                .compactMap { $0 }
                .joined(separator: " ")
            let fullSearchText = cleanedMessage + " " + response.message + " " + actionJson
            mentionedPersons = extractMentionedPersons(from: fullSearchText, limit: 3)

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
                // Namen durch Short-IDs ersetzen: "für Emre" → "für p5"
                let apiContent = replaceNamesWithShortIds(msg.content)
                apiMessages.append(["role": "user", "content": apiContent])
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

        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        let region = Locale.current.region?.identifier ?? ""

        // Kompakter Prompt — passend zur Sprache, kurze Regeln, Short-IDs
        var prompt = buildLocalizedRules(lang: lang, region: region)

        // Kompakte Kontaktliste
        let contactsHeader: String = switch lang {
        case "de": "\n\nKontakte:\n"
        case "fr": "\n\nContacts :\n"
        case "es": "\n\nContactos:\n"
        default: "\n\nContacts:\n"
        }

        prompt += contactsHeader

        if people.isEmpty {
            prompt += "(keine)\n"
        } else {
            var giftCounter = 1
            for (index, person) in people.enumerated() {
                let pid = "p\(index + 1)"
                personIdMap[pid] = person.id

                prompt += buildCompactPersonEntry(person, shortId: pid, lang: lang, giftCounter: &giftCounter)
            }
        }

        return prompt
    }

    // swiftlint:disable:next function_body_length
    private func buildLocalizedRules(lang: String, region: String) -> String {
        // Kultureller Kontext je nach Region
        let culturalHint: String
        switch lang {
        case "de":
            culturalHint = "Berücksichtige deutsche Geschenkkultur (z.B. Erlebnisgeschenke, Gutscheine, regionale Spezialitäten). Preise in Euro."
        case "fr":
            if region == "CA" {
                culturalHint = "Tiens compte de la culture québécoise (cadeaux expérientiels, produits locaux). Prix en dollars canadiens."
            } else {
                culturalHint = "Tiens compte de la culture française (gastronomie, expériences, artisanat local). Prix en euros."
            }
        case "es":
            if region == "MX" {
                culturalHint = "Ten en cuenta la cultura mexicana (experiencias, artesanía, gastronomía local). Precios en pesos mexicanos."
            } else if region == "AR" || region == "CL" || region == "CO" {
                culturalHint = "Ten en cuenta la cultura latinoamericana (experiencias, regalos personalizados, gastronomía). Precios en moneda local."
            } else {
                culturalHint = "Ten en cuenta la cultura española (gastronomía, experiencias, artesanía). Precios en euros."
            }
        default:
            if region == "GB" {
                culturalHint = "Consider British gift-giving culture (experiences, vouchers, artisan products). Prices in GBP."
            } else {
                culturalHint = "Consider gift-giving culture appropriate for the recipient. Prices in USD."
            }
        }

        let actionDocs = """
        - create_gift_idea: person_id, person_name, gift_title, gift_note
        - query
        - update_gift_status: gift_idea_id, new_status (planned|purchased|given)
        - open_suggestions: person_id, person_name
        - clarify_person
        - off_topic
        - none
        """

        switch lang {
        case "de":
            return """
            Du bist der freundliche Geschenke-Assistent der App "AI Präsente".

            REGELN:
            - Antworte auf Deutsch, herzlich und natürlich wie ein guter Freund der bei Geschenken hilft.
            - Themen: Geburtstage, Geschenkideen, Geschenkplanung. Off-Topic freundlich ablehnen und IMMER einen konkreten Vorschlag machen, was du stattdessen fragen könntest (z.B. "Frag mich lieber: Wer hat bald Geburtstag?").
            - DATENSCHUTZ: Du erhältst KEINE echten Namen im Kontaktverzeichnis. Jede Person hat eine ID (z.B. p1) und eine Beziehung. Verwende in deinen Antworten den Namen den der User benutzt, oder die Beziehung.
            - KONTEXT-HINTS: Wenn der User einen Namen nennt, fügt die App automatisch einen Hint hinzu wie [context: user refers to p5 = Lukas]. Nutze diese Info um die richtige Person zu finden und antworte natürlich mit dem Namen.
            - Bei mehrdeutiger Zuordnung: nachfragen wer gemeint ist.
            - WICHTIG: Short-IDs (p1, g1 etc.) sind NUR für die action-Felder. Schreibe NIEMALS Short-IDs in die message — verwende dort die Beziehung (z.B. "deine Mutter", "dein Freund").
            - WICHTIG: Wenn eine Beschreibung zu MEHREREN Kontakten passt, IMMER clarify_person verwenden und ALLE passenden Kontakte mit ihrer Beziehung und Altersgruppe auflisten.
            - Formuliere vollständige, natürliche Sätze. Nenne konkrete Daten (z.B. "am 15. April") statt nur Tage.
            - Bei Geschenkfragen: Berücksichtige Hobbies, Altersgruppe, Geschlecht, Beziehung und bisherige Geschenke.
            - \(culturalHint)

            FORMAT: Antworte NUR mit JSON:
            {"message":"Deine natürliche Antwort hier","action":{"type":"none"}}

            Aktionstypen: \(actionDocs)

            Beispiel: {"message":"Wie wäre es mit einem Buch für deine Schwester?","action":{"type":"create_gift_idea","person_id":"p1","person_name":"Schwester","gift_title":"Buch","gift_note":""}}
            """

        case "fr":
            return """
            Tu es l'assistant cadeaux sympathique de l'app « AI Présents ».

            RÈGLES :
            - Réponds en français, chaleureusement et naturellement, comme un bon ami qui aide à trouver des cadeaux.
            - Sujets : Anniversaires, idées cadeaux, planification de cadeaux. Refuse poliment le hors-sujet et suggère TOUJOURS une question pertinente (ex. « Demande-moi plutôt : Qui a bientôt son anniversaire ? »).
            - VIE PRIVÉE : Tu ne reçois PAS de vrais noms dans la liste de contacts. Chaque personne a un ID (ex. p1) et une relation.
            - INDICES CONTEXTUELS : Quand l'utilisateur mentionne un nom, l'app ajoute un indice comme [context: user refers to p5 = Lukas]. Utilise cette info et réponds naturellement avec le nom.
            - Correspondance ambiguë : demande de préciser.
            - IMPORTANT : Les IDs courts (p1, g1 etc.) sont UNIQUEMENT pour les champs action. N'écris JAMAIS d'IDs courts dans le message — utilise la relation (ex. « ta mère », « ton ami »).
            - IMPORTANT : Si une description correspond à PLUSIEURS contacts, utilise TOUJOURS clarify_person et liste TOUS les contacts correspondants.
            - Formule des phrases complètes et naturelles. Mentionne les dates précises (ex. « le 15 avril »).
            - Pour les cadeaux : Tiens compte des hobbies, tranche d'âge, genre, relation et cadeaux précédents.
            - \(culturalHint)

            FORMAT : Réponds UNIQUEMENT en JSON :
            {"message":"Ta réponse naturelle ici","action":{"type":"none"}}

            Types d'action : \(actionDocs)

            Exemple : {"message":"Que dirais-tu d'un livre pour ta sœur ?","action":{"type":"create_gift_idea","person_id":"p1","person_name":"Sœur","gift_title":"Livre","gift_note":""}}
            """

        case "es":
            return """
            Eres el simpático asistente de regalos de la app "AI Présents".

            REGLAS:
            - Responde en español, con calidez y naturalidad, como un buen amigo que ayuda con los regalos.
            - Temas: Cumpleaños, ideas de regalo, planificación de regalos. Rechaza amablemente temas fuera de contexto y sugiere SIEMPRE una pregunta relevante (ej. "Mejor pregúntame: ¿Quién cumple años pronto?").
            - PRIVACIDAD: NO recibes nombres reales en la lista de contactos. Cada persona tiene un ID (ej. p1) y una relación.
            - PISTAS CONTEXTUALES: Cuando el usuario menciona un nombre, la app añade una pista como [context: user refers to p5 = Lukas]. Usa esta info y responde naturalmente con el nombre.
            - Coincidencia ambigua: pregunta para aclarar.
            - IMPORTANTE: Los IDs cortos (p1, g1 etc.) son SOLO para los campos de acción. NUNCA escribas IDs cortos en el mensaje — usa la relación (ej. "tu madre", "tu amigo").
            - IMPORTANTE: Si una descripción coincide con VARIOS contactos, usa SIEMPRE clarify_person y lista TODOS los contactos con su relación y grupo de edad.
            - Formula frases completas y naturales. Menciona fechas concretas (ej. "el 15 de abril").
            - Para preguntas de regalos: Considera hobbies, grupo de edad, género, relación y regalos anteriores.
            - \(culturalHint)

            FORMATO: Responde SOLO con JSON:
            {"message":"Tu respuesta natural aquí","action":{"type":"none"}}

            Tipos de acción: \(actionDocs)

            Ejemplo: {"message":"¿Qué tal un libro para tu hermana?","action":{"type":"create_gift_idea","person_id":"p1","person_name":"Hermana","gift_title":"Libro","gift_note":""}}
            """

        default:
            return """
            You are the friendly gift assistant of the app "AI Présents".

            RULES:
            - Respond warmly and naturally, like a helpful friend who's great at gift-giving.
            - Topics: Birthdays, gift ideas, gift planning. Politely decline off-topic requests and ALWAYS suggest a relevant question instead (e.g. "Try asking: Who has a birthday coming up?").
            - PRIVACY: You do NOT receive real names in the contact list. Each person has an ID (e.g. p1) and a relationship.
            - CONTEXT HINTS: When the user mentions a name, the app adds a hint like [context: user refers to p5 = Lukas]. Use this to find the right person and respond naturally using the name.
            - Ambiguous match: ask to clarify.
            - IMPORTANT: Short IDs (p1, g1 etc.) are ONLY for action fields. NEVER include short IDs in the message — always use the relationship (e.g. "your mother", "your friend").
            - IMPORTANT: If a description matches MULTIPLE contacts, ALWAYS use clarify_person and list ALL matching contacts by relationship and age group.
            - Use complete, natural sentences. Mention specific dates (e.g. "on April 15th") instead of just days.
            - For gift questions: Consider hobbies, age group, gender, relationship, and past gifts.
            - \(culturalHint)

            FORMAT: Respond ONLY with JSON:
            {"message":"Your natural response here","action":{"type":"none"}}

            Action types: \(actionDocs)

            Example: {"message":"How about a book for your sister?","action":{"type":"create_gift_idea","person_id":"p1","person_name":"Sister","gift_title":"Book","gift_note":""}}
            """
        }
    }

    private func buildCompactPersonEntry(_ person: PersonRef, shortId: String, lang: String, giftCounter: inout Int) -> String {
        // Format: p1:weiblich|Mitte 30|10d|Freund/in|Reiten,Kochen
        // DATENSCHUTZ: Kein Name, kein Geburtstag (Tag/Monat), kein exaktes Alter
        let firstName = person.displayName.split(separator: " ").first.map(String.init) ?? person.displayName
        let gender = GenderInference.infer(relation: person.relation, firstName: firstName)

        var parts: [String] = ["\(shortId):\(gender.localizedLabel)"]

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

    // MARK: - Namens-Auflösung (lokal, DSGVO-konform)

    /// Ersetzt echte Namen im User-Text durch Short-IDs für die KI.
    /// "Trag Buchgutschein für Emre ein" → "Trag Buchgutschein für p5 ein"
    /// Die KI kennt Short-IDs perfekt — kein Hint oder Injection nötig.
    private func replaceNamesWithShortIds(_ text: String) -> String {
        var result = text

        // Sortiert nach Namenslänge (längste zuerst), damit "Emre Kaya" vor "Emre" ersetzt wird
        var nameMap: [(name: String, shortId: String)] = []

        for (shortId, uuid) in personIdMap {
            guard let person = people.first(where: { $0.id == uuid }) else { continue }
            // Vollname
            nameMap.append((name: person.displayName, shortId: shortId))
            // Vorname (nur wenn >= 3 Zeichen, um Kurzformen wie "Li" zu vermeiden)
            let firstName = person.displayName.split(separator: " ").first.map(String.init) ?? ""
            if firstName.count >= 3 && firstName != person.displayName {
                nameMap.append((name: firstName, shortId: shortId))
            }
        }

        // Längste Namen zuerst ersetzen (verhindert Teil-Ersetzungen)
        nameMap.sort { $0.name.count > $1.name.count }

        for entry in nameMap {
            // Case-insensitive Ersetzung
            if let range = result.range(of: entry.name, options: .caseInsensitive) {
                result.replaceSubrange(range, with: entry.shortId)
            }
        }

        return result
    }

    // MARK: - Text-Bereinigung & Personen-Extraktion

    /// Entfernt Short-IDs aus dem Nachrichtentext.
    /// Häufige KI-Muster: "Deine Tante (p33)" → "Deine Tante", "p33" → Personenname
    private func cleanMessageText(_ text: String) -> String {
        var cleaned = text
        // 1. Klammer-IDs komplett entfernen: "(p33)" → "" (Beziehung steht schon im Text)
        cleaned = cleaned.replacing(/\s*\(p\d+\)/, with: "")
        // 2. Alleinstehende IDs durch Display-Namen ersetzen: "p33 hat..." → "Name hat..."
        for (shortId, uuid) in personIdMap {
            guard let person = people.first(where: { $0.id == uuid }) else { continue }
            cleaned = cleaned.replacing(try! Regex("\\b\(shortId)\\b"), with: person.displayName)
        }
        return cleaned
    }

    /// Extrahiert erwähnte Personen aus einem Text anhand von Short-IDs (p\d+), max `limit` Einträge.
    private func extractMentionedPersons(from text: String, limit: Int = 3) -> [PersonRef] {
        let pattern = /\bp(\d+)\b/
        var found: [PersonRef] = []
        var seen: Set<UUID> = []

        for match in text.matches(of: pattern) {
            let shortId = "p\(match.1)"
            if let uuid = personIdMap[shortId],
               !seen.contains(uuid),
               let person = people.first(where: { $0.id == uuid }) {
                found.append(person)
                seen.insert(uuid)
                if found.count >= limit { break }
            }
        }
        return found
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
            // Bei clarify_person: Personen aus User-Nachricht per Name matchen und zu mentionedPersons hinzufügen
            if let lastUserMessage = messages.last(where: { $0.role == .user })?.content.lowercased() {
                let nameMatched = people.filter { person in
                    let firstName = person.displayName.split(separator: " ").first.map(String.init) ?? person.displayName
                    return lastUserMessage.contains(firstName.lowercased())
                }
                // Name-Matches mit Short-ID-Matches zusammenführen (Duplikate entfernen)
                var merged = mentionedPersons
                for p in nameMatched where !merged.contains(where: { $0.id == p.id }) {
                    merged.append(p)
                }
                mentionedPersons = Array(merged.prefix(3))
            }

        case .query, .offTopic, .none:
            break
        }
    }

    // MARK: - Welcome Chips

    var welcomeChips: [(label: String, message: String)] {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
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
            let label: String = switch lang {
            case "de": "Wann hat \(name) Geburtstag?"
            case "fr": "C'est quand l'anniversaire de \(name) ?"
            case "es": "¿Cuándo cumple años \(name)?"
            default: "When is \(name)'s birthday?"
            }
            chips.append((label, label))
        }

        // Geschenkidee vorschlagen
        if let person = people.first {
            let label: String = switch lang {
            case "de": "Idee für \(person.displayName)"
            case "fr": "Idée pour \(person.displayName)"
            case "es": "Idea para \(person.displayName)"
            default: "Idea for \(person.displayName)"
            }
            let message: String = switch lang {
            case "de": "Schlage Geschenke für \(person.displayName) vor"
            case "fr": "Suggère des cadeaux pour \(person.displayName)"
            case "es": "Sugiere regalos para \(person.displayName)"
            default: "Suggest gifts for \(person.displayName)"
            }
            chips.append((label, message))
        }

        // Allgemeine Chips
        let soonLabel: String = switch lang {
        case "de": "Wer hat bald Geburtstag?"
        case "fr": "Qui fête bientôt son anniversaire ?"
        case "es": "¿Quién cumple años pronto?"
        default: "Who has a birthday soon?"
        }
        let soonMessage: String = switch lang {
        case "de": "Wer hat in den nächsten 7 Tagen Geburtstag?"
        case "fr": "Qui a son anniversaire dans les 7 prochains jours ?"
        case "es": "¿Quién cumple años en los próximos 7 días?"
        default: "Who has a birthday in the next 7 days?"
        }
        chips.append((soonLabel, soonMessage))

        // Geschenkidee-Eintrag Beispiel
        if let person = people.first {
            let label: String = switch lang {
            case "de": "Kinogutschein für \(person.displayName) eintragen"
            case "fr": "Ajouter un bon cinéma pour \(person.displayName)"
            case "es": "Añadir vale de cine para \(person.displayName)"
            default: "Add cinema voucher for \(person.displayName)"
            }
            let message: String = switch lang {
            case "de": "Trag einen Kinogutschein als Geschenkidee für \(person.displayName) ein"
            case "fr": "Ajoute un bon cinéma comme idée cadeau pour \(person.displayName)"
            case "es": "Añade un vale de cine como idea de regalo para \(person.displayName)"
            default: "Add a cinema voucher as a gift idea for \(person.displayName)"
            }
            chips.append((label, message))
        }

        return chips
    }
}
