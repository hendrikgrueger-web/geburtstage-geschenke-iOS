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
        // Check if API key is configured
        guard !apiKey.isEmpty else {
            throw AIError.apiKeyNotConfigured
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

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.requestFailed
        }

        return data
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

        var errorDescription: String? {
            switch self {
            case .apiKeyNotConfigured:
                return "OpenRouter API-Key nicht konfiguriert"
            case .requestFailed:
                return "API-Anfrage fehlgeschlagen"
            case .invalidResponse:
                return "Ungültige API-Antwort"
            }
        }
    }
}

struct GiftSuggestion {
    let title: String
    let reason: String
}
