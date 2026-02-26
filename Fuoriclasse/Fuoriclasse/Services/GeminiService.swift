import Foundation

final class GeminiService {
    static let shared = GeminiService()

    private let apiKey: String
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    private let historyWindow = 10

    private init() {
        guard
            let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path),
            let key = dict["GEMINI_API_KEY"] as? String,
            !key.isEmpty,
            key != "YOUR_KEY_HERE"
        else {
            fatalError("Secrets.plist manquant ou clé GEMINI_API_KEY non renseignée.")
        }
        self.apiKey = key
    }

    func send(messages: [ChatMessage], wardrobeContext: String, imageData: Data?) async throws -> String {
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }

        let systemPrompt = """
        Tu es Fuoriclasse, un styliste personnel expert.
        Voici le dressing complet de l'utilisateur :
        \(wardrobeContext.isEmpty ? "(dressing vide)" : wardrobeContext)
        Donne des conseils personnalisés, suggère des tenues complètes, \
        analyse les photos de vêtements. Réponds en français, de façon \
        concise et pratique.
        """

        // Build history (last N messages, excluding the last user message which we handle separately)
        let recentMessages = messages.suffix(historyWindow)
        var contents: [[String: Any]] = []

        for msg in recentMessages {
            let geminiRole = msg.role == .user ? "user" : "model"
            var parts: [[String: Any]] = [["text": msg.text]]

            if let data = msg.imageData, msg.role == .user {
                let b64 = data.base64EncodedString()
                parts.insert(["inlineData": ["mimeType": "image/jpeg", "data": b64]], at: 0)
            }

            contents.append(["role": geminiRole, "parts": parts])
        }

        // If the last message is from the user and has imageData, we've already included it above.
        // No extra handling needed.

        let body: [String: Any] = [
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": contents,
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 1024
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard statusCode == 200 else {
            // Essaye d'extraire le message lisible depuis le JSON d'erreur Gemini
            let friendly: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = json["error"] as? [String: Any],
               let msg = err["message"] as? String {
                switch statusCode {
                case 429: friendly = "Quota dépassé. Réessayez dans quelques instants."
                case 401, 403: friendly = "Clé API invalide. Vérifiez Secrets.plist."
                case 400: friendly = "Requête invalide : \(msg.prefix(80))"
                default:   friendly = "Erreur \(statusCode) : \(msg.prefix(100))"
                }
            } else {
                friendly = "Erreur réseau (\(statusCode))."
            }
            throw NSError(domain: "GeminiService", code: statusCode,
                          userInfo: [NSLocalizedDescriptionKey: friendly])
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let first = candidates.first,
            let content = first["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let text = parts.first?["text"] as? String
        else {
            throw NSError(domain: "GeminiService", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Réponse inattendue de Gemini."])
        }

        return text
    }

    // MARK: - One-shot generation (sans contexte chat)

    func generate(prompt: String) async throws -> String {
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }

        let body: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 256
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String
        else { throw URLError(.cannotParseResponse) }

        return text
    }
}
