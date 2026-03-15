import Foundation

// MARK: - Sendable Kontext-Structs
// Werden genutzt, um SwiftData-Objekte (non-Sendable) sicher über Actor-Grenzen zu übergeben.

private struct GiftContext: Sendable {
    /// Geschlecht als Label (z.B. "weiblich", "männlich", "Person") — KEIN Name
    let genderLabel: String
    /// Ungefähre Altersgruppe (z.B. "Mitte 30") — KEIN exaktes Alter. Nil wenn unbekannt.
    let ageGroup: String?
    let relation: String
    let zodiac: String
    let daysUntil: Int?
    /// Dauerhafte Hobbies/Interessen der Person (max. 10, aus PersonRef.hobbies).
    let hobbies: [String]
    let tags: [String]
    let pastGiftTitles: [String] // Nur Titel, kein ganzes GiftHistory-Objekt
}

private struct BirthdayContext: Sendable {
    /// Geschlecht als Label — KEIN Name
    let genderLabel: String
    /// Ungefähre Altersgruppe — KEIN exaktes Alter. Nil wenn unbekannt.
    let ageGroup: String?
    let relation: String
    let zodiac: String
    let lastGiftTitle: String?
    let lastGiftYear: Int?
    /// Absender-Name (lokal gespeichert, wird NICHT an API gesendet)
    let senderName: String?
}

// MARK: - AIService

/// KI-Service für Geschenkvorschläge und Geburtstagsgrüße via Cloudflare Worker Proxy → OpenRouter (Google Gemini).
///
/// ## Datenschutz: Cloud-Verarbeitung (DSGVO-konform anonymisiert)
/// Übertragene Daten sind ANONYMISIERT: Geschlecht (lokal abgeleitet), Altersgruppe (z.B. "Mitte 30"),
/// Beziehungstyp, Sternzeichen, Interessen/Tags, Budget-Rahmen, Geschenktitel (ohne Jahr).
/// NICHT übertragen: Name, Geburtsdatum, exaktes Alter, Links, Notizen, Telefonnummer.
///
/// ## Voraussetzungen
/// - Proxy-Secret in Info.plist (AIProxySecret)
/// - Einwilligung via AIConsentManager
///
/// Wirft Fehler wenn Proxy-Secret fehlt oder Netzwerkprobleme auftreten (kein Demo-Modus).
struct AIService {
    static let shared = AIService()
    private init() {}

    // MARK: - Sprach-Erkennung für KI-Prompts

    /// Erkennt die aktuelle Gerätesprache für sprachabhängige KI-Prompts.
    private var promptLanguage: String {
        Locale.current.language.languageCode?.identifier == "de" ? "de" : "en"
    }

    // MARK: - Verfügbarkeit

    /// True wenn API-Key konfiguriert ist UND Einwilligung gegeben wurde.
    /// Nur auf dem MainActor aufrufbar (da AIConsentManager MainActor-isoliert ist).
    @MainActor
    static var isAvailable: Bool {
        isAPIKeyConfigured && AIConsentManager.shared.consentGiven
    }

    static var isAPIKeyConfigured: Bool {
        AppConfig.AI.isAPIKeyConfigured
    }

    private static var proxySecret: String {
        AppConfig.AI.proxySecret
    }

    // MARK: - Öffentliche API (@MainActor — SwiftData-Objekte extrahieren)

    @MainActor
    func generateGiftIdeas(
        for person: PersonRef,
        budgetMin: Double,
        budgetMax: Double,
        tags: [String],
        pastGifts: [GiftHistory],
        excludeTitles: [String] = []
    ) async throws -> [GiftSuggestion] {

        // DATENSCHUTZ: Geschlecht lokal ableiten, Alter verrauschen, kein Name an API
        let firstName = person.displayName.split(separator: " ").first.map(String.init) ?? person.displayName
        let gender = GenderInference.infer(relation: person.relation, firstName: firstName)
        let isGerman = Locale.current.language.languageCode?.identifier == "de"

        let context = GiftContext(
            genderLabel: isGerman ? gender.localizedLabel : gender.englishLabel,
            ageGroup: person.birthYearKnown ? AgeObfuscator.approximateAge(BirthdayDateHelper.age(from: person.birthday)) : nil,
            relation: person.relation,
            zodiac: BirthdayDateHelper.zodiacSign(from: person.birthday),
            daysUntil: BirthdayDateHelper.daysUntilBirthday(from: person.birthday),
            hobbies: person.hobbies,
            tags: tags,
            pastGiftTitles: pastGifts.map { $0.title }
        )
        let budgetRange = (min: budgetMin, max: budgetMax)

        guard AIService.isAPIKeyConfigured else {
            throw AIError.notConfigured
        }
        guard AIService.isAvailable && AIConsentManager.shared.canUseAI else {
            throw AIError.noConsent
        }

        let budgetString = CurrencyManager.shared.formatBudgetRange(min: budgetMin, max: budgetMax)
        return try await generateGiftIdeasWithOpenRouter(context: context, budget: budgetRange, budgetString: budgetString, excludeTitles: excludeTitles)
    }

    @MainActor
    func generateBirthdayMessage(for person: PersonRef, pastGifts: [GiftHistory] = [], senderName: String? = nil) async throws -> BirthdayMessage {

        // DATENSCHUTZ: Geschlecht lokal ableiten, Alter verrauschen, kein Name an API
        let firstName = person.displayName.split(separator: " ").first.map(String.init) ?? person.displayName
        let gender = GenderInference.infer(relation: person.relation, firstName: firstName)
        let isGerman = Locale.current.language.languageCode?.identifier == "de"

        let lastGift = pastGifts.sorted(by: { $0.year > $1.year }).first
        let context = BirthdayContext(
            genderLabel: isGerman ? gender.localizedLabel : gender.englishLabel,
            ageGroup: person.birthYearKnown ? AgeObfuscator.approximateAge(BirthdayDateHelper.age(from: person.birthday)) : nil,
            relation: person.relation,
            zodiac: BirthdayDateHelper.zodiacSign(from: person.birthday),
            lastGiftTitle: lastGift?.title,
            lastGiftYear: lastGift.map { $0.year },
            senderName: senderName
        )

        guard AIService.isAPIKeyConfigured else {
            throw AIError.notConfigured
        }
        guard AIService.isAvailable && AIConsentManager.shared.canUseAI else {
            throw AIError.noConsent
        }

        return try await generateBirthdayMessageWithOpenRouter(context: context)
    }

    // MARK: - OpenRouter API

    private func generateGiftIdeasWithOpenRouter(
        context: GiftContext,
        budget: (min: Double, max: Double),
        budgetString: String,
        excludeTitles: [String] = []
    ) async throws -> [GiftSuggestion] {

        var userPrompt: String

        if promptLanguage == "de" {
            // DATENSCHUTZ: Geschlecht + Beziehung statt Name, Altersgruppe statt exaktes Alter
            userPrompt = "Erstelle 5 passende Geschenkideen für eine \(context.genderLabel)e Person, Beziehung: \(context.relation)."

            if let ageGroup = context.ageGroup {
                userPrompt += "\n⚠️ ALTERSGRUPPE: \(ageGroup) — Vorschläge MÜSSEN altersgerecht sein!"
            }

            if !context.hobbies.isEmpty {
                userPrompt += "\n⭐ HOBBIES (höchste Priorität, mindestens 3 Vorschläge müssen darauf eingehen): \(context.hobbies.joined(separator: ", "))."
            }

            if !context.tags.isEmpty {
                userPrompt += "\nWeitere Interessen: \(context.tags.joined(separator: ", "))."
            }

            userPrompt += "\nSternzeichen: \(context.zodiac)."
            userPrompt += "\nBudget: \(budgetString) (strikt einhalten)."

            let allExcluded = context.pastGiftTitles + excludeTitles
            if !allExcluded.isEmpty {
                userPrompt += "\nBereits vorgeschlagen oder verschenkt (NICHT wiederholen): \(allExcluded.joined(separator: ", "))."
            }

            if let days = context.daysUntil {
                switch days {
                case 0:     userPrompt += "\nWichtig: Geburtstag ist HEUTE!"
                case 1:     userPrompt += "\nWichtig: Geburtstag ist morgen!"
                case 2...7: userPrompt += "\nWichtig: Geburtstag in \(days) Tagen — schnell verfügbare Ideen bevorzugen."
                default: break
                }
            }
        } else {
            userPrompt = "Create 5 suitable gift ideas for a \(context.genderLabel) person, relationship: \(context.relation)."

            if let ageGroup = context.ageGroup {
                userPrompt += "\n⚠️ AGE GROUP: \(ageGroup) — suggestions MUST be age-appropriate!"
            }

            if !context.hobbies.isEmpty {
                userPrompt += "\n⭐ HOBBIES (highest priority, at least 3 suggestions must relate to these): \(context.hobbies.joined(separator: ", "))."
            }

            if !context.tags.isEmpty {
                userPrompt += "\nAdditional interests: \(context.tags.joined(separator: ", "))."
            }

            userPrompt += "\nZodiac sign: \(context.zodiac)."
            userPrompt += "\nBudget: \(budgetString) (strictly adhere)."

            let allExcluded = context.pastGiftTitles + excludeTitles
            if !allExcluded.isEmpty {
                userPrompt += "\nAlready suggested or gifted (DO NOT repeat): \(allExcluded.joined(separator: ", "))."
            }

            if let days = context.daysUntil {
                switch days {
                case 0:     userPrompt += "\nImportant: Birthday is TODAY!"
                case 1:     userPrompt += "\nImportant: Birthday is tomorrow!"
                case 2...7: userPrompt += "\nImportant: Birthday in \(days) days — prefer quickly available ideas."
                default: break
                }
            }
        }

        let systemPrompt: String
        if promptLanguage == "de" {
            systemPrompt = """
            Du bist ein erfahrener Geschenkberater. WICHTIGSTE REGELN:
            1) ALTERSGERECHT: Geschenke MÜSSEN zum Alter passen. Kinder (0-12): Spielzeug, Bücher, Bastelsets, Sport-Equipment, kindgerechte Erlebnisse. Teenager (13-17): Tech, Fashion, Erlebnisse, kreative Hobbies. NIEMALS Erwachsenen-Geschenke (Kaffee, Wein, Parfüm) an Kinder/Jugendliche.
            2) HOBBIES PRIORISIEREN: Wenn Hobbies/Interessen angegeben sind, müssen mindestens 3 von 5 Vorschlägen DIREKT darauf eingehen.
            3) KONKRET: title = konkretes, kaufbares Geschenk in 1-4 Worten (z.B. "Lego Technic Bausatz", "Hip-Hop Tanzkurs", "Konzertkarten"). NICHT generisch wie "Personalisiertes Geschenk".
            4) reason = kurze Begründung (1 Satz) mit Bezug auf Person, Hobby oder Alter. ANDERS als title.
            5) BUDGET strikt einhalten.
            Antworte NUR mit validem JSON ohne Markdown-Codeblöcke. Format: {"suggestions":[{"title":"...","reason":"..."}]}
            """
        } else {
            systemPrompt = """
            You are an experienced gift advisor. MOST IMPORTANT RULES:
            1) AGE-APPROPRIATE: Gifts MUST match the recipient's age. Children (0-12): toys, books, craft kits, sports equipment, child-friendly experiences. Teenagers (13-17): tech, fashion, experiences, creative hobbies. NEVER give adult gifts (coffee, wine, perfume) to children/teens.
            2) PRIORITIZE HOBBIES: When hobbies/interests are provided, at least 3 of 5 suggestions MUST directly relate to them.
            3) SPECIFIC: title = specific, purchasable gift in 1-4 words (e.g. "Lego Technic Set", "Hip-Hop Dance Class", "Concert Tickets"). NOT generic like "Personalized Gift".
            4) reason = short explanation (1 sentence) referencing the person, hobby, or age. DIFFERENT from title.
            5) STRICTLY adhere to budget.
            Reply ONLY with valid JSON without Markdown code blocks. Format: {"suggestions":[{"title":"...","reason":"..."}]}
            """
        }

        let responseData = try await callOpenRouter(system: systemPrompt, user: userPrompt)

        guard let suggestions = AIService.decodeGiftSuggestions(from: responseData) else {
            AppLogger.data.error("JSON-Parse-Fehler bei Gift Ideas")
            throw AIError.invalidResponse
        }
        return suggestions
    }

    private func generateBirthdayMessageWithOpenRouter(context: BirthdayContext) async throws -> BirthdayMessage {

        var userPrompt: String

        if promptLanguage == "de" {
            // DATENSCHUTZ: Geschlecht + Beziehung statt Name, Altersgruppe statt exaktes Alter
            userPrompt = "Schreibe eine herzliche Geburtstagsnachricht für eine \(context.genderLabel)e Person, Beziehung: \(context.relation)."

            if let ageGroup = context.ageGroup {
                userPrompt += "\n⚠️ ALTERSGRUPPE: \(ageGroup) — Sprache und Ton MÜSSEN zur Altersgruppe passen!"
            }

            userPrompt += "\nSternzeichen: \(context.zodiac)."

            if let title = context.lastGiftTitle {
                userPrompt += "\nLetztes Geschenk: \(title)."
            }
        } else {
            userPrompt = "Write a heartfelt birthday message for a \(context.genderLabel) person, relationship: \(context.relation)."

            if let ageGroup = context.ageGroup {
                userPrompt += "\n⚠️ AGE GROUP: \(ageGroup) — language and tone MUST match the age group!"
            }

            userPrompt += "\nZodiac sign: \(context.zodiac)."

            if let title = context.lastGiftTitle {
                userPrompt += "\nLast gift: \(title)."
            }
        }

        // Absender-Name wird NICHT an die API gesendet (Datenschutz)
        // Er wird erst danach lokal in die Nachricht eingefügt

        let systemPrompt: String
        if promptLanguage == "de" {
            systemPrompt = """
            Du bist ein Texter für Geburtstagsnachrichten. WICHTIGE REGELN:
            1) ALTERSGERECHT: Für Kinder (0-12): liebevoll, einfache Sprache, Bezug auf Spielen/Abenteuer. Für Teenager (13-17): cool, nicht kindlich, respektvoll. Für Erwachsene: warmherzig und persönlich.
            2) Die Anrede ("greeting") soll passend sein: "Liebe/r" für Erwachsene, "Liebe" + Name für Kinder.
            3) Der Text ("body") soll 3-5 Sätze lang sein, persönlich klingen und zum Alter passen.
            4) KEINE Unterschrift im body — die wird vom Nutzer selbst hinzugefügt.
            Antworte NUR mit validem JSON ohne Markdown-Codeblöcke. Format: {"greeting":"...","body":"..."}
            """
        } else {
            systemPrompt = """
            You are a birthday greeting writer. IMPORTANT RULES:
            1) AGE-APPROPRIATE: For children (0-12): loving, simple language, reference to play/adventures. For teenagers (13-17): cool, not childish, respectful. For adults: warm and personal.
            2) The greeting should be appropriate: "Dear" for adults, more casual for children.
            3) The body should be 3-5 sentences, sound personal, and match the age.
            4) NO signature in the body — the user will add their own.
            Reply ONLY with valid JSON without Markdown code blocks. Format: {"greeting":"...","body":"..."}
            """
        }

        let responseData = try await callOpenRouter(system: systemPrompt, user: userPrompt)

        guard let message = AIService.decodeBirthdayMessage(from: responseData, senderName: context.senderName) else {
            AppLogger.data.error("JSON-Parse-Fehler bei Birthday Message")
            throw AIError.invalidResponse
        }
        return message
    }

    // MARK: - Chat API (Multi-Turn)

    /// Sendet eine Multi-Turn-Konversation via Cloudflare Worker Proxy und gibt die rohe Antwort zurück.
    func callOpenRouterChat(messages: [[String: String]]) async throws -> ChatResponseJSON {
        let secret = AIService.proxySecret
        guard !secret.isEmpty else { throw AIError.noAPIKey }

        guard let url = URL(string: AppConfig.AI.openRouterBaseURL) else {
            throw AIError.notConfigured
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(secret, forHTTPHeaderField: "X-App-Secret")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": AppConfig.AI.model,
            "messages": messages
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            AppLogger.data.error("OpenRouter Chat HTTP \(httpResponse.statusCode)")
            throw AIError.httpError(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw AIError.emptyResponse
        }

        // JSON aus Markdown-Codeblock extrahieren falls nötig
        let cleanedContent = AIService.extractJSON(from: content)

        guard let contentData = cleanedContent.data(using: .utf8),
              let chatResponse = try? JSONDecoder().decode(ChatResponseJSON.self, from: contentData) else {
            // Fallback: Wenn kein valides JSON, Rohtext als message zurückgeben
            return ChatResponseJSON(message: content, action: nil)
        }
        return chatResponse
    }

    /// Extrahiert JSON aus einem String, der optional in Markdown-Codeblöcke eingebettet ist.
    static func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Entferne ```json ... ``` oder ``` ... ```
        if trimmed.hasPrefix("```") {
            let lines = trimmed.components(separatedBy: "\n")
            let filtered = lines.dropFirst().reversed().drop(while: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("```") }).reversed()
            return filtered.joined(separator: "\n")
        }
        return trimmed
    }

    static func decodeGiftSuggestions(from responseData: Data) -> [GiftSuggestion]? {
        guard let rawContent = String(data: responseData, encoding: .utf8) else {
            return nil
        }
        let cleanedContent = extractJSON(from: rawContent)
        guard let contentData = cleanedContent.data(using: .utf8),
              let json = try? JSONDecoder().decode(GiftSuggestionsJSON.self, from: contentData) else {
            return nil
        }
        return json.suggestions.map { GiftSuggestion(title: $0.title, reason: $0.reason) }
    }

    static func decodeBirthdayMessage(from responseData: Data, senderName: String? = nil) -> BirthdayMessage? {
        guard let rawContent = String(data: responseData, encoding: .utf8) else {
            return nil
        }
        let cleanedContent = extractJSON(from: rawContent)
        guard let contentData = cleanedContent.data(using: .utf8),
              let json = try? JSONDecoder().decode(BirthdayMessageJSON.self, from: contentData) else {
            return nil
        }

        let signature = senderName.map { "\n\n\($0)" } ?? ""
        return BirthdayMessage(greeting: json.greeting, body: json.body + signature)
    }

    // MARK: - Single-Turn API

    private func callOpenRouter(system: String, user: String) async throws -> Data {
        let secret = AIService.proxySecret
        guard !secret.isEmpty else { throw AIError.noAPIKey }

        guard let url = URL(string: AppConfig.AI.openRouterBaseURL) else {
            throw AIError.notConfigured
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(secret, forHTTPHeaderField: "X-App-Secret")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": AppConfig.AI.model,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            AppLogger.data.error("OpenRouter HTTP \(httpResponse.statusCode)")
            throw AIError.httpError(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw AIError.emptyResponse
        }

        guard let contentData = content.data(using: .utf8) else {
            throw AIError.emptyResponse
        }
        return contentData
    }

    // MARK: - Response Structs (privat)

    private struct OpenRouterResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String }
            let message: Message
        }
        let choices: [Choice]
    }

    private struct GiftSuggestionsJSON: Decodable {
        struct Item: Decodable { let title: String; let reason: String }
        let suggestions: [Item]
    }

    private struct BirthdayMessageJSON: Decodable {
        let greeting: String
        let body: String
    }

    // MARK: - Fehler

    enum AIError: LocalizedError {
        case noAPIKey
        case notConfigured
        case noConsent
        case httpError(Int)
        case emptyResponse
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .noAPIKey, .notConfigured:
                return String(localized: "KI-Dienst nicht konfiguriert. Bitte prüfe die App-Einrichtung.")
            case .noConsent:
                return String(localized: "KI-Einwilligung erforderlich. Bitte erteile die Einwilligung in den Einstellungen.")
            case .httpError(let code):
                return String(localized: "KI-Dienst Fehler (HTTP \(code)). Bitte versuche es später erneut.")
            case .emptyResponse:
                return String(localized: "Leere Antwort vom KI-Dienst erhalten.")
            case .invalidResponse:
                return String(localized: "Ungültige Antwort vom KI-Dienst. Bitte versuche es erneut.")
            }
        }
    }
}

// MARK: - Datenstrukturen

struct GiftSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let reason: String
}

struct BirthdayMessage {
    let greeting: String
    let body: String

    var fullText: String { "\(greeting)\n\n\(body)" }
}
