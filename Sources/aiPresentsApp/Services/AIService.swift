import Foundation

struct AIService {
    static let shared = AIService()

    private let apiKey = "" // OpenRouter API Key - needs to be configured
    private let baseURL = "https://openrouter.ai/api/v1"

    private init() {}

    // MARK: - Context Helpers

    /// Calculate age for a person
    private func age(for person: PersonRef, on date: Date = Date()) -> Int {
        BirthdayDateHelper.age(from: person.birthday, asOf: date)
    }

    /// Get milestone information for a person
    private func milestone(for person: PersonRef, on date: Date = Date()) -> (age: Int, name: String?)? {
        let currentAge = age(for: person, on: date)
        if BirthdayDateHelper.isMilestoneAge(age: currentAge) {
            return (currentAge, BirthdayDateHelper.milestoneName(for: currentAge))
        }
        return nil
    }

    /// Build context string for AI prompts
    private func contextString(for person: PersonRef, on date: Date = Date()) -> String {
        var context = ""

        // Age context
        let currentAge = age(for: person, on: date)
        context += "- Alter: \(currentAge) Jahre"

        // Add age group context
        if currentAge < 18 {
            context += " (Kind/Jugendlicher)\n"
        } else if currentAge < 30 {
            context += " (Junge Erwachsene)\n"
        } else if currentAge < 50 {
            context += " (Erwachsene)\n"
        } else {
            context += " (Reif/Erfahrung)\n"
        }

        // Milestone context
        if let milestone = milestone(for: person, on: date) {
            context += "- Meilenstein: \(milestone.name!) - Besonderer Anlass!\n"
        }

        // Zodiac sign with personality hints
        let zodiac = BirthdayDateHelper.zodiacSign(from: person.birthday)
        if !zodiac.isEmpty {
            let personalityHint = personalityHint(for: zodiac)
            context += "- Sternzeichen: \(zodiac) (\(personalityHint))\n"
        }

        // Relative birthday timing with urgency context
        let daysUntil = BirthdayDateHelper.daysUntilBirthday(from: person.birthday, asOf: date)
        if let days = daysUntil {
            if days == 0 {
                context += "- Anlass: Geburtstag ist HEUTE! 🎉 (Sofortige Idee nötig)\n"
            } else if days == 1 {
                context += "- Anlass: Geburtstag ist morgen (Zeit für etwas Persönliches)\n"
            } else if days <= 7 {
                context += "- Anlass: Geburtstag in \(days) Tagen (Zeit für Planung)\n"
            } else {
                context += "- Anlass: Geburtstag in \(days) Tagen (Genug Zeit für etwas Besonderes)\n"
            }
        }

        return context
    }

    /// Personality hints based on zodiac sign (for AI context)
    private func personalityHint(for zodiac: String) -> String {
        switch zodiac.lowercased() {
        case "widder": return "energisch, spontan"
        case "stier": return "genussvoll, bodenständig"
        case "zwillinge": return "neugierig, kommunikativ"
        case "krebs": return "fürsorglich, emotional"
        case "löwe": return "kreativ, selbstbewusst"
        case "jungfrau": return "perfektionistisch, praktisch"
        case "waage": return "harmonisch, ästhetisch"
        case "skorpion": return "intensiv, leidenschaftlich"
        case "schütze": return "abenteuerlustig, optimistisch"
        case "steinbock": return "ehrgeizig, diszipliniert"
        case "wassermann": return "eigenständig, innovativ"
        case "fische": return "künstlerisch, einfühlsam"
        default: return "einzigartig"
        }
    }

    /// Zodiac-based birthday wishes for demo mode
    private func zodiacWish(for zodiac: String) -> String {
        switch zodiac.lowercased() {
        case "widder": return "Möge deine Energie und Spontaneität dich weiterbringen!"
        case "stier": return "Genieß die schönen Momente des Lebens!"
        case "zwillinge": return "Möge deine Neugier immer neue Wege öffnen!"
        case "krebs": return "Deine Fürsorge ist unbezahlbar - genieß diesen Tag!"
        case "löwe": return "Strahle weiter hell und inspiriere uns alle!"
        case "jungfrau": return "Deine Perfektion ist beeindruckend - bleib so!"
        case "waage": return "Bringe weiterhin Harmonie und Schönheit in die Welt!"
        case "skorpion": return "Deine Leidenschaft und Tiefe sind einzigartig!"
        case "schütze": return "Möge dein Optimismus dich zu neuen Höhen führen!"
        case "steinbock": return "Dein Ehrgeiz und Disziplin sind vorbildlich!"
        case "wassermann": return "Deine Kreativität und Unabhängigkeit inspirieren!"
        case "fische": return "Deine Empathie und Kreativität sind ein Geschenk!"
        default: return "Bleib so einzigartig wie du bist!"
        }
    }

    func generateGiftIdeas(
        for person: PersonRef,
        budgetMin: Double,
        budgetMax: Double,
        tags: [String],
        pastGifts: [GiftHistory]
    ) async throws -> [GiftSuggestion] {
        // If API key is not configured, use demo mode
        if apiKey.isEmpty {
            return generateDemoSuggestions(for: person, budget: budgetMax)
        }

        // Build prompt
        let prompt = buildPrompt(
            person: person,
            budgetMin: budgetMin,
            budgetMax: budgetMax,
            tags: tags,
            pastGifts: pastGifts
        )

        // Make API request
        let response = try await makeRequest(prompt: prompt)

        // Parse response
        return try parseResponse(response)
    }

    /// Generate a personalized birthday message draft
    func generateBirthdayMessage(for person: PersonRef, pastGifts: [GiftHistory] = []) async throws -> BirthdayMessage {
        // If API key is not configured, use demo mode
        if apiKey.isEmpty {
            return generateDemoBirthdayMessage(for: person, pastGifts: pastGifts)
        }

        // Build prompt
        let prompt = buildBirthdayMessagePrompt(for: person, pastGifts: pastGifts)

        // Make API request
        let response = try await makeRequest(prompt: prompt)

        // Parse response
        return try parseBirthdayMessageResponse(response)
    }

    // Demo mode: Generate birthday message without API
    private func generateDemoBirthdayMessage(for person: PersonRef, pastGifts: [GiftHistory]) -> BirthdayMessage {
        let name = person.displayName.components(separatedBy: " ").first ?? person.displayName
        let relation = person.relation
        let currentAge = age(for: person)
        let milestone = milestone(for: person)
        let zodiac = BirthdayDateHelper.zodiacSign(from: person.birthday)

        var greeting = "Liebe(r) \(name),"
        var body = ""

        if milestone != nil {
            body = """
            alles Gute zum \(currentAge). Geburtstag! 🎉

            Das ist ein ganz besonderer Meilenstein, den du jetzt erreichst. Ich wünsche dir für dieses neue Lebensjahr alles Gute - Gesundheit, Glück und dass alle deine Träume und Wünsche in Erfüllung gehen. \(zodiacWish(for: zodiac))

            Du bist ein wertvoller Teil meines Lebens und ich freue mich darauf, viele weitere schöne Momente mit dir zu erleben. Feier diesen Tag so, wie du es verdienst!

            Herzlichst,
            Dein(e) \(relation)
            """
        } else if currentAge < 30 {
            body = """
            alles Gute zum \(currentAge). Geburtstag! 🎂

            Ich wünsche dir einen fantastischen Tag, an dem du rundum verwöhnt wirst. Möge das kommende Jahr voller toller Erlebnisse und glücklicher Momente sein. \(zodiacWish(for: zodiac))

            Lass dich feiern und genieß jeden Augenblick dieses besonderen Tages!

            Alles Gute,
            Dein(e) \(relation)
            """
        } else {
            body = """
            herzlichen Glückwunsch zum \(currentAge). Geburtstag! 🎉

            Möge dieser Tag so schön sein wie du. Ich wünsche dir Gesundheit, Freude und alles Gute für das kommende Jahr. \(zodiacWish(for: zodiac))

            Danke, dass du Teil meines Lebens bist. Genieß deinen Festtag und feiere ordentlich!

            Warmherzig,
            Dein(e) \(relation)
            """
        }

        return BirthdayMessage(greeting: greeting, body: body.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func buildBirthdayMessagePrompt(for person: PersonRef, pastGifts: [GiftHistory]) -> String {
        var prompt = """
        Als erfahrener Texter: Schreibe eine herzliche, persönliche Geburtstagsgrußkarte für \(person.displayName).

        ===== PERSON KONTEXT =====
        \(contextString(for: person))
        - Beziehung: \(person.relation)
        =====
        """

        if !pastGifts.isEmpty {
            let lastGift = pastGifts.sorted { $0.year > $1.year }.first
            if let gift = lastGift {
                prompt += "\n===== GESCHICHTE =====\n"
                prompt += "- Letztes Geschenk (\(gift.year)): \(gift.title)\n"
                if !gift.note.isEmpty {
                    prompt += "- Anmerkung: \(gift.note)\n"
                }
                prompt += "===== Nutze dies für einen persönlichen Bezug =====\n"
            }
        }

        prompt += """
        ===== TONFALL & STIL =====
        - Herzlich, wertschätzend und authentisch
        - Angemessen für die Beziehung (\(person.relation))
        - Bei Meilensteinen: Besondere Erwähnung des Anlasses
        - Keine Floskeln, echte Emotionen
        =====

        ===== STRUKTUR =====
        1. Greeting: Persönliche Anrede (nicht "Sehr geehrter/r")
        2. Body: 3-5 Sätze mit:
           - Glückwünsche für das neue Jahr
           - Wertschätzung der Beziehung
           - Eventuell persönlicher Bezug aus der Vergangenheit
           - Bei Meilenstein: Bedeutung dieses Anlasses
        =====

        ===== AUSGABE FORMAT =====
        {
            "greeting": "Persönliche Anrede (z.B. 'Liebe Anna,' oder 'Hallo Thomas,')",
            "body": "Vollständiger Nachrichtentext (3-5 Sätze, herzlich und persönlich)"
        }
        =====

        Jetzt: Eine einzigartige, herzliche Geburtstagsnachricht schreiben.
        """

        return prompt
    }

    private func parseBirthdayMessageResponse(_ data: Data) throws -> BirthdayMessage {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.invalidResponse
        }

        guard let contentData = content.data(using: .utf8),
              let parsedMessage = try JSONSerialization.jsonObject(with: contentData) as? [String: Any],
              let greeting = parsedMessage["greeting"] as? String,
              let body = parsedMessage["body"] as? String else {
            throw AIError.invalidResponse
        }

        return BirthdayMessage(greeting: greeting, body: body)
    }

    // Demo mode: Generate suggestions without API
    private func generateDemoSuggestions(for person: PersonRef, budget: Double) -> [GiftSuggestion] {
        let relation = person.relation.lowercased()
        let name = person.displayName.components(separatedBy: " ").first ?? person.displayName
        let currentAge = age(for: person)
        let milestone = milestone(for: person)
        let zodiac = BirthdayDateHelper.zodiacSign(from: person.birthday)

        var suggestions: [(title: String, reason: String)]

        // Zodiak-basierte Variationen
        func zodiacSuffix() -> String {
            let personality = personalityHint(for: zodiac)
            return "Passt perfekt zu einem \(zodiac) (\(personalityHint(for: zodiac)))."
        }

        // Milestone-based suggestions
        if let milestone = milestone {
            if milestone.age == 18 {
                suggestions = [
                    ("Erlebnis-Gutschein für etwas Spezielles", "Zum 18. Geburtstag unvergessliche Erinnerungen schaffen. \(zodiacSuffix())"),
                    ("Hochwertiges Technik-Gadget", "Einstieg ins Erwachsenenleben - modern und nützlich. \(zodiacSuffix())"),
                    ("Reisegutschein oder Weekend-Trip", "Freiheit erleben und neue Orte entdecken. \(zodiacSuffix())"),
                    ("Personalisiertes Geschenk mit Gravur", "Einzigartiges Andenken an diesen besonderen Meilenstein."),
                    ("Abo für Streaming/Musik/etc.", "Jahrlange Freude an digitalen Diensten. \(zodiacSuffix())")
                ]
            } else if milestone.age >= 30 && milestone.age <= 60 {
                suggestions = [
                    ("Erlebnis für zwei Personen", "Qualitätszeit und gemeinsame Erlebnisse schätzen. \(zodiacSuffix())"),
                    ("Hochwertiges Lifestyle-Produkt", "Qualität vor Quantität - für den genussvollen Alltag."),
                    ("Personalisiertes Geschenk mit Foto", "Erinnerungen hochleben lassen - besonders wertvoll."),
                    ("Gourmet-Essen oder Weinprobe", "Genussmomente zum Anlass genießen. \(zodiacSuffix())"),
                    ("Praktisches aber elegantes Zubehör", "Nützlich und ästhetisch - für den gepflegten Alltag.")
                ]
            } else {
                suggestions = [
                    ("Besonderes Erlebnis", "Für diesen Meilenstein etwas unvergessliches erleben. \(zodiacSuffix())"),
                    ("Hochwertiges Geschenk mit persönlichem Touch", "Zeigt Wertschätzung für diese besondere Stufe im Leben."),
                    ("Erinnerungsstück scrapen oder Album", "Auf das bisherige Leben zurückblicken und feiern."),
                    ("Gutschein für das Lieblingshobby", "Interessen fördern und Freude schenken. \(zodiacSuffix())"),
                    ("Zeitloses Accessoire", "Klassisch und elegant - ein Bleibendes zum Meilenstein.")
                ]
            }
        }
        // Relation-based suggestions
        else if relation.contains("familie") || relation.contains("mama") || relation.contains("papa") {
            suggestions = [
                ("Fotoalbum mit Erinnerungen", "Persönlich und sentimental - perfekt für Familienmitglieder."),
                ("Hochwertige Küche/Bar Ausrüstung", "Praktisch und von hoher Qualität - ideal für häufiges Nutzen. \(zodiacSuffix())"),
                ("Gutschein für Erlebnis", "Gemeinsam Zeit verbringen schafft bleibende Erinnerungen."),
                ("Buch zum Lieblingsthema", "Zeigt Interesse und Wertschätzung für Hobbys. \(zodiacSuffix())"),
                ("Schmuck oder Accessoires", "Zeitlos und persönlich - ein Klassiker für besondere Anlässe.")
            ]
        } else if relation.contains("freund") || relation.contains("kollege") {
            suggestions = [
                ("Tech-Gadget oder Zubehör", "Modern und nützlich - perfekt für Technik-Enthusiasten. \(zodiacSuffix())"),
                ("Hochwertiges Schreibwaren-Set", "Elegant und professionell - gut für Office oder Schreibtisch."),
                ("Erlebnis-Gutschein", "Kino, Konzerte oder Ausstellungen - Erlebnisse statt Dinge. \(zodiacSuffix())"),
                ("Specialty Food & Drink", "Premium Kaffee, Tee oder Craft Beer - genießbar und nachhaltig."),
                ("Spiel für Abende", "Gesellig und unterhaltsam - bringt Menschen zusammen.")
            ]
        } else if relation.contains("partner") {
            suggestions = [
                ("Romantisches Wochenend-Ausflug", "Qualitätszeit und neue Erinnerungen schaffen."),
                ("Hochwertiges Uhrenarmband", "Schick und persönlich - täglicher Nutzen mit sentimentalem Wert."),
                ("Personalisiertes Geschenk", "Gravur oder eigenes Design - einzigartig und speziell. \(zodiacSuffix())"),
                ("Erlebnis für Zweit", "Kochkurs, Weinprobe oder Wellness - gemeinsam erleben. \(zodiacSuffix())"),
                ("Schmuckstück", "Klassisch und zeitlos - ein Symbol für Wertschätzung.")
            ]
        } else {
            suggestions = [
                ("Personalisiertes Geschenk", "Gravur oder eigenes Design - zeigt besondere Aufmerksamkeit."),
                ("Erlebnis-Gutschein", "Veranstaltungen oder Kurse - Erinnerungen statt Dinge. \(zodiacSuffix())"),
                ("Hochwertiges Buch", "Zeigt Interesse für Hobbys - geduldig und nachhaltig. \(zodiacSuffix())"),
                ("Praktisches Gadget", "Nützlich und modern - guter Alltagsbegleiter."),
                ("Kreative Bastel-Kits", "Selbstgemacht und kreativ - persönlich und einzigartig.")
            ]
        }

        return suggestions.map { GiftSuggestion(title: $0.title, reason: $0.reason) }
    }

    private func buildPrompt(
        person: PersonRef,
        budgetMin: Double,
        budgetMax: Double,
        tags: [String],
        pastGifts: [GiftHistory]
    ) -> String {
        var prompt = """
        Als erfahrener Geschenkberater: Erstelle 5 hochqualitative Geschenkideen für \(person.displayName).

        ===== PERSON KONTEXT =====
        \(contextString(for: person))
        - Beziehung: \(person.relation)
        =====

        ===== BESCHRÄNKUNGEN =====
        - Budget: \(Int(budgetMin))€ - \(Int(budgetMax))€ (STRIKT - keine Vorschläge außerhalb dieses Bereichs)
        """

        if !tags.isEmpty {
            prompt += "- Interessen/Tags: \(tags.joined(separator: ", ")) (nutze diese als Inspiration)\n"
        }

        if !pastGifts.isEmpty {
            prompt += "\n===== BEREITS VERSCHENKT (NICHT NOCHMAL) =====\n"
            for gift in pastGifts {
                prompt += "- \(gift.title) (\(gift.category))\n"
            }
            prompt += "===== ACHTUNG: Keine ähnlichen Geschenke vorschlagen!\n"
        }

        prompt += """
        =====

        ===== QUALITÄTSKRITERIEN =====
        1. Jede Idee muss einzigartig sein (keine Dopplungen untereinander)
        2. Preisgenau im Budget-Bereich (keine "ca" - konkrete Preisschätzung)
        3. Altersgerecht (Kind/Jugendlicher/Erwachsener/Reif)
        4. Beziehungsgemäß (Familie/Freunde/Partner/Kollege - unterschiedliche Tonart)
        5. Persönlich (nutze Alter, Sternzeichen-Charakter, Meilenstein-Bedeutung)
        6. Meilenstein-Sensibilität: Besondere Bedeutung für runde Geburtstage
        7. Sternzeichen: Berücksichtige typische Eigenschaften (\(personalityHint(for: BirthdayDateHelper.zodiacSign(from: person.birthday))))
        =====

        ===== AUSGABE FORMAT =====
        Für jede Idee:
        - title: Konkreter Geschenkname (keine allgemeinen Begriffe)
        - reason: Kurze Begründung (max 2 Sätze) mit persönlichem Bezug zur Person

        Striktes JSON-Array:
        [
            {
                "title": "Konkreter Geschenkname",
                "reason": "Begründung mit persönlichem Bezug"
            }
        ]
        =====

        Jetzt: 5 einzigartige, budgetgerechte, personalisierte Geschenkideen generieren.
        """

        return prompt
    }

    private func makeRequest(prompt: String) async throws -> Data {
        let retryPolicy = RetryPolicy.default

        for attempt in 1...retryPolicy.maxAttempts {
            do {
                let url = URL(string: "\(baseURL)/chat/completions")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

                let body: [String: Any] = [
                    "model": "anthropic/claude-3-haiku",
                    "messages": [
                        [
                            "role": "user",
                            "content": prompt
                        ]
                    ],
                    "response_format": ["type": "json_object"]
                ]

                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AIError.requestFailed
                }

                if httpResponse.statusCode == 200 {
                    return data
                } else if httpResponse.statusCode >= 500 {
                    // Server errors - retry
                    throw AIError.serverError(httpResponse.statusCode)
                } else if httpResponse.statusCode == 429 {
                    // Rate limit - retry with backoff
                    throw AIError.rateLimit
                } else {
                    // Client errors - don't retry
                    throw AIError.clientError(httpResponse.statusCode)
                }
            } catch let error as AIError {
                // Don't retry client errors
                if case .clientError = error {
                    throw error
                }

                // Retry for other errors
                if attempt < retryPolicy.maxAttempts {
                    let delay = retryPolicy.delay * Double(attempt)
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }

                throw error
            }
        }

        throw AIError.requestFailed
    }

    private func parseResponse(_ data: Data) throws -> [GiftSuggestion] {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.invalidResponse
        }

        guard let contentData = content.data(using: .utf8),
              let suggestions = try JSONSerialization.jsonObject(with: contentData) as? [[String: Any]] else {
            throw AIError.invalidResponse
        }

        return suggestions.compactMap { suggestion -> GiftSuggestion? in
            guard let title = suggestion["title"] as? String,
                  let reason = suggestion["reason"] as? String else {
                return nil
            }
            return GiftSuggestion(title: title, reason: reason)
        }
    }

    enum AIError: LocalizedError {
        case apiKeyNotConfigured
        case requestFailed
        case invalidResponse
        case serverError(Int)
        case rateLimit
        case clientError(Int)

        var errorDescription: String? {
            switch self {
            case .apiKeyNotConfigured:
                return "OpenRouter API-Key nicht konfiguriert"
            case .requestFailed:
                return "API-Anfrage fehlgeschlagen nach mehreren Versuchen"
            case .invalidResponse:
                return "Ungültige API-Antwort"
            case .serverError(let code):
                return "Server-Fehler (\(code)): Bitte versuche es erneut"
            case .rateLimit:
                return "Zu viele Anfragen. Bitte warte einen Moment"
            case .clientError(let code):
                return "Client-Fehler (\(code)): Überprüfe deine Konfiguration"
            }
        }

        var isRetryable: Bool {
            switch self {
            case .serverError, .rateLimit, .requestFailed:
                return true
            case .apiKeyNotConfigured, .invalidResponse, .clientError:
                return false
            }
        }
    }
}

struct GiftSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let reason: String
}

/// Personalized birthday message draft
struct BirthdayMessage {
    let greeting: String
    let body: String

    /// Full message with greeting and body
    var fullText: String {
        return "\(greeting)\n\n\(body)"
    }
}

// Retry configuration for API requests
struct RetryPolicy {
    let maxAttempts: Int
    let delay: TimeInterval

    static let `default` = RetryPolicy(maxAttempts: 3, delay: 1.0)
    static let aggressive = RetryPolicy(maxAttempts: 5, delay: 0.5)
}
