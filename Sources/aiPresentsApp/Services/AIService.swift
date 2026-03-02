import Foundation

struct AIService {
    static let shared = AIService()

    private let apiKey = "" // OpenRouter API Key - needs to be configured
    private let baseURL = "https://openrouter.ai/api/v1"

    private init() {}

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

    // Demo mode: Generate suggestions without API
    private func generateDemoSuggestions(for person: PersonRef, budget: Double) -> [GiftSuggestion] {
        let relation = person.relation.lowercased()
        let name = person.displayName.components(separatedBy: " ").first ?? person.displayName

        let suggestions: [(title: String, reason: String)]

        if relation.contains("familie") || relation.contains("mama") || relation.contains("papa") {
            suggestions = [
                ("Fotoalbum mit Erinnerungen", "Persönlich und sentimental - perfekt für Familienmitglieder."),
                ("Hochwertige Küche/Bar Ausrüstung", "Praktisch und von hoher Qualität - ideal für häufiges Nutzen."),
                ("Gutschein für Erlebnis", "Gemeinsam Zeit verbringen schafft bleibende Erinnerungen."),
                ("Buch zum Lieblingsthema", "Zeigt Interesse und Wertschätzung für Hobbys."),
                ("Schmuck oder Accessoires", "Zeitlos und persönlich - ein Klassiker für besondere Anlässe.")
            ]
        } else if relation.contains("freund") || relation.contains("kollege") {
            suggestions = [
                ("Tech-Gadget oder Zubehör", "Modern und nützlich - perfekt für Technik-Enthusiasten."),
                ("Hochwertiges Schreibwaren-Set", "Elegant und professionell - gut für Office oder Schreibtisch."),
                ("Erlebnis-Gutschein", "Kino, Konzerte oder Ausstellungen - Erlebnisse statt Dinge."),
                ("Specialty Food & Drink", "Premium Kaffee, Tee oder Craft Beer - genießbar und nachhaltig."),
                ("Spiel für Abende", "Gesellig und unterhaltsam - bringt Menschen zusammen.")
            ]
        } else if relation.contains("partner") {
            suggestions = [
                ("Romantisches Wochenend-Ausflug", "Qualitätszeit und neue Erinnerungen schaffen."),
                ("Hochwertiges Uhrenarmband", "Schick und persönlich - täglicher Nutzen mit sentimentalem Wert."),
                ("Personalisiertes Geschenk", "Gravur oder eigenes Design - einzigartig und speziell."),
                ("Erlebnis für Zweit", "Kochkurs, Weinprobe oder Wellness - gemeinsam erleben."),
                ("Schmuckstück", "Klassisch und zeitlos - ein Symbol für Wertschätzung.")
            ]
        } else {
            suggestions = [
                ("Personalisiertes Geschenk", "Gravur oder eigenes Design - zeigt besondere Aufmerksamkeit."),
                ("Erlebnis-Gutschein", "Veranstaltungen oder Kurse - Erinnerungen statt Dinge."),
                ("Hochwertiges Buch", "Zeigt Interesse für Hobbys - geduldig und nachhaltig."),
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
        Ich brauche 5 Geschenkideen für \(person.displayName).

        Details:
        - Beziehung: \(person.relation)
        - Budget: \(Int(budgetMin))€ - \(Int(budgetMax))€
        """

        if !tags.isEmpty {
            prompt += "- Interessen/Tags: \(tags.joined(separator: ", "))\n"
        }

        if !pastGifts.isEmpty {
            prompt += "\nBereits verschenkt (vermeide ähnliche Geschenke):\n"
            for gift in pastGifts {
                prompt += "- \(gift.title) (\(gift.category))\n"
            }
        }

        prompt += """
        \nBitte gib mir 5 konkrete, kreative Geschenkideen. Für jede Idee:
        1. Name des Geschenks
        2. Kurze Begründung (1-2 Sätze)

        Format als JSON:
        [
            {
                "title": "Geschenkname",
                "reason": "Begründung"
            }
        ]
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

struct GiftSuggestion {
    let title: String
    let reason: String
}

// Retry configuration for API requests
struct RetryPolicy {
    let maxAttempts: Int
    let delay: TimeInterval

    static let `default` = RetryPolicy(maxAttempts: 3, delay: 1.0)
    static let aggressive = RetryPolicy(maxAttempts: 5, delay: 0.5)
}
