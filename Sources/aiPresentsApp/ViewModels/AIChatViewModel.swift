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

    /// Gecachter System-Prompt — wird lazy beim nächsten API-Call gebaut.
    private var cachedSystemPrompt: String = ""
    /// Flag: System-Prompt muss beim nächsten API-Call neu gebaut werden.
    private var promptNeedsRebuild = true

    /// Laufender API-Task — wird bei cancelPendingRequests() abgebrochen.
    private var currentTask: Task<Void, Never>?

    // MARK: - Setup

    func configure(
        people: [PersonRef],
        giftIdeas: [GiftIdea],
        giftHistory: [GiftHistory],
        modelContext: ModelContext?
    ) {
        refreshContext(
            people: people,
            giftIdeas: giftIdeas,
            giftHistory: giftHistory,
            modelContext: modelContext
        )
    }

    func refreshContext(
        people: [PersonRef],
        giftIdeas: [GiftIdea],
        giftHistory: [GiftHistory],
        modelContext: ModelContext?
    ) {
        // FIX: Stabile Sortierung — verhindert dass p1 auf verschiedene Personen zeigt
        self.people = people.sorted { $0.displayName < $1.displayName }
        self.giftIdeas = giftIdeas
        self.giftHistory = giftHistory
        self.modelContext = modelContext
        invalidatePromptCache()
    }

    /// Invalidiert den gecachten System-Prompt lazy — rebuild erfolgt erst beim nächsten API-Call.
    func invalidatePromptCache() {
        promptNeedsRebuild = true
        cachedSystemPrompt = ""
    }

    /// Gibt den (ggf. neu gebauten) System-Prompt zurück.
    private func getSystemPrompt() -> String {
        if promptNeedsRebuild || cachedSystemPrompt.isEmpty {
            cachedSystemPrompt = buildSystemPrompt()
            promptNeedsRebuild = false
        }
        return cachedSystemPrompt
    }

    // MARK: - Senden

    func sendMessage(_ text: String) {
        currentTask?.cancel()
        currentTask = Task { @MainActor in
            await self.performSend(text)
        }
    }

    /// Bricht einen laufenden API-Call ab — z.B. wenn das Chat-Sheet geschlossen wird.
    func cancelPendingRequests() {
        currentTask?.cancel()
        currentTask = nil
        isLoading = false
    }

    private func performSend(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        isLoading = true

        do {
            let apiMessages = buildAPIMessages()
            let response = try await AIService.shared.callOpenRouterChat(messages: apiMessages)

            guard !Task.isCancelled else {
                isLoading = false
                return
            }

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
            if !Task.isCancelled {
                let errorChat = ChatMessage(role: .assistant, content: String(localized: "Entschuldigung, es gab einen Fehler. Bitte versuche es erneut."))
                messages.append(errorChat)
                AppLogger.data.error("Chat-Fehler", error: error)
            }
        }

        isLoading = false
    }

    // MARK: - API Messages

    private func buildAPIMessages() -> [[String: String]] {
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": getSystemPrompt()]
        ]

        // Sliding window: max. 20 letzte Nachrichten, um Token-Verbrauch zu begrenzen
        let recentMessages = messages.suffix(20)
        for msg in recentMessages {
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
            Du bist der freundliche Geschenke-Assistent der App "Geschenke AI".

            REGELN:
            - Antworte auf Deutsch, herzlich und natürlich wie ein guter Freund der bei Geschenken hilft.
            - Themen: Geburtstage, Geschenkideen, Geschenkplanung. Off-Topic freundlich ablehnen und IMMER einen konkreten Vorschlag machen, was du stattdessen fragen könntest (z.B. "Frag mich lieber: Wer hat bald Geburtstag?").
            - AKTION SOFORT AUSFÜHREN: Wenn der User dich bittet eine Geschenkidee einzutragen oder zu speichern, TU ES SOFORT mit create_gift_idea. Frage NICHT nach Details, Budget oder Varianten — trage genau das ein was der User sagt.
            - NAMEN: Du kennst die Vornamen aller Kontakte. Verwende sie natürlich. Bei eindeutigem Vornamen: sofort zuordnen.
            - Bei MEHREREN Kontakten mit gleichem Vornamen: Frage welcher gemeint ist (mit Beziehung und Altersgruppe). Sage dabei: "Ich darf Nachnamen nämlich nicht online verarbeiten — Datenschutz! 🔒". Verwende clarify_person.
            - Short-IDs (p1, g1 etc.) sind NUR für die action-Felder. NIEMALS in die message — verwende Vornamen oder Beziehung.
            - Formuliere kurze, natürliche Sätze. Nenne konkrete Daten (z.B. "am 15. April") statt nur Tage.
            - Bei Geschenkfragen: Berücksichtige Hobbies, Altersgruppe, Geschlecht, Beziehung und bisherige Geschenke.
            - \(culturalHint)

            FORMAT: Antworte NUR mit JSON:
            {"message":"Deine natürliche Antwort hier","action":{"type":"none"}}

            Aktionstypen: \(actionDocs)

            Beispiel: {"message":"Wie wäre es mit einem Buch für deine Schwester?","action":{"type":"create_gift_idea","person_id":"p1","person_name":"Schwester","gift_title":"Buch","gift_note":""}}
            """

        case "fr":
            return """
            Tu es l'assistant cadeaux sympathique de l'app « Cadeaux AI ».

            RÈGLES :
            - Réponds en français, chaleureusement et naturellement, comme un bon ami qui aide à trouver des cadeaux.
            - Sujets : Anniversaires, idées cadeaux, planification de cadeaux. Refuse poliment le hors-sujet et suggère TOUJOURS une question pertinente (ex. « Demande-moi plutôt : Qui a bientôt son anniversaire ? »).
            - ACTION IMMÉDIATE : Quand l'utilisateur demande d'ajouter une idée cadeau, FAIS-LE immédiatement avec create_gift_idea. Ne demande PAS de détails.
            - PRÉNOMS : Tu connais les prénoms de tous les contacts. Utilise-les naturellement. Prénom unique : assigne directement.
            - PLUSIEURS contacts avec le même prénom : Demande lequel (relation + tranche d'âge). Dis : « Je ne peux pas traiter les noms de famille en ligne — protection des données ! 🔒 ». Utilise clarify_person.
            - IDs courts (p1, g1) UNIQUEMENT dans les champs action. JAMAIS dans le message — utilise prénoms ou relations.
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
            Eres el simpático asistente de regalos de la app "Regalos AI".

            REGLAS:
            - Responde en español, con calidez y naturalidad, como un buen amigo que ayuda con los regalos.
            - Temas: Cumpleaños, ideas de regalo, planificación de regalos. Rechaza amablemente temas fuera de contexto y sugiere SIEMPRE una pregunta relevante (ej. "Mejor pregúntame: ¿Quién cumple años pronto?").
            - ACCIÓN INMEDIATA: Cuando el usuario pide guardar una idea de regalo, HAZLO ya con create_gift_idea. NO pidas detalles.
            - NOMBRES: Conoces los nombres de pila de todos los contactos. Úsalos naturalmente. Nombre único: asigna directamente.
            - VARIOS contactos con el mismo nombre: Pregunta cuál (relación + grupo de edad). Di: "No puedo procesar apellidos online — ¡protección de datos! 🔒". Usa clarify_person.
            - IDs cortos (p1, g1) SOLO en campos de acción. NUNCA en el mensaje — usa nombres de pila o relaciones.
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
            You are the friendly gift assistant of the app "Gifts AI".

            RULES:
            - Respond warmly and naturally, like a helpful friend who's great at gift-giving.
            - Topics: Birthdays, gift ideas, gift planning. Politely decline off-topic requests and ALWAYS suggest a relevant question instead.
            - EXECUTE IMMEDIATELY: When the user asks to save or add a gift idea, DO IT NOW with create_gift_idea. Do NOT ask for details, budget or variants — save exactly what the user said.
            - NAMES: You know the first names of all contacts. Use them naturally. For unique first names: assign immediately.
            - For MULTIPLE contacts with the same first name: Ask which one (using relationship and age group). Say: "I can't process last names online — privacy! 🔒". Use clarify_person.
            - Short IDs (p1, g1 etc.) are ONLY for action fields. NEVER in the message — use first names or relationships.
            - Use short, natural sentences. Mention specific dates (e.g. "on April 15th") instead of just days.
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
        // Format: p1:Dennis|männlich|Mitte 30|10d|Freund|Reiten,Kochen
        // DSGVO: Nur Vorname wird übertragen (für KI-Qualität), NIEMALS Nachname
        let firstName = person.displayName.split(separator: " ").first.map(String.init) ?? person.displayName
        let gender = GenderInference.infer(relation: person.relation, firstName: firstName)

        var parts: [String] = ["\(shortId):\(firstName)|\(gender.localizedLabel)"]

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

    // Namens-Auflösung nicht mehr nötig — Vornamen werden im System-Prompt mitgesendet.

    // MARK: - Text-Bereinigung & Personen-Extraktion

    /// Entfernt Short-IDs aus dem Nachrichtentext.
    /// Häufige KI-Muster: "Deine Tante (p33)" → "Deine Tante", "p33" → Personenname
    private func cleanMessageText(_ text: String) -> String {
        var cleaned = text
        // 1. Klammer-IDs komplett entfernen: "(p33)" → "" (Beziehung steht schon im Text)
        cleaned = cleaned.replacing(/\s*\(p\d+\)/, with: "")
        // 2. Alleinstehende IDs durch Display-Namen ersetzen: "p33 hat..." → "Name hat..."
        // Wortgrenzen-Matching via einfachem String-Check statt Regex (Short-IDs haben bekannte Formate wie "p1", "p42")
        for (shortId, uuid) in personIdMap {
            guard let person = people.first(where: { $0.id == uuid }) else { continue }
            // Ersetze " p42 ", " p42.", " p42,", etc. — alle Positionen wo shortId von Nicht-Alphanumerik umgeben ist
            if let regex = try? Regex("\\b\(shortId)\\b") {
                cleaned = cleaned.replacing(regex, with: person.displayName)
            }
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
            invalidatePromptCache()
            WidgetDataService.refresh(using: modelContext)
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

    func systemPromptForTesting() -> String {
        getSystemPrompt()
    }

    var promptNeedsRebuildForTesting: Bool {
        promptNeedsRebuild
    }
}
