import Foundation

// MARK: - ProductInfo

struct ProductInfo {
    var title:    String = ""
    var brand:    String = ""
    var color:    String = ""
    var material: String = ""
    var price:    String = ""
    var imageURL: URL?   = nil
}

// MARK: - Errors

enum ProductFetchError: LocalizedError {
    case invalidURL
    case pageNotAccessible(Int)
    case noProductFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:               return "URL invalide"
        case .pageNotAccessible(let c): return "Page inaccessible (erreur \(c))"
        case .noProductFound:           return "Aucun produit trouvé sur cette page"
        }
    }
}

// MARK: - Service

actor ProductFetchService {
    static let shared = ProductFetchService()

    // MARK: Public entry point

    func fetch(urlString: String) async throws -> ProductInfo {
        let trimmed  = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixed = trimmed.hasPrefix("http") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: prefixed) else { throw ProductFetchError.invalidURL }

        var req = URLRequest(url: url, timeoutInterval: 15)
        req.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        req.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: req)
        if let code = (response as? HTTPURLResponse)?.statusCode, code >= 400 {
            throw ProductFetchError.pageNotAccessible(code)
        }

        let html = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1)
                ?? ""

        // 1. Schema.org JSON-LD (fiable, ~80 % des e-commerces)
        if let info = parseSchemaOrg(html: html), !info.title.isEmpty {
            return info
        }

        // 2. Fallback Gemini
        return try await parseWithGemini(html: html)
    }

    // Télécharge l'image produit pour la stocker localement
    func downloadImage(from url: URL) async -> Data? {
        try? await URLSession.shared.data(from: url).0
    }

    // MARK: - Schema.org parser

    private func parseSchemaOrg(html: String) -> ProductInfo? {
        let pattern = #"<script[^>]*type=["']application/ld\+json["'][^>]*>([\s\S]*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }

        let ns    = html as NSString
        let range = NSRange(location: 0, length: ns.length)

        for match in regex.matches(in: html, range: range) {
            guard match.numberOfRanges > 1 else { continue }
            let r = match.range(at: 1)
            guard r.location != NSNotFound else { continue }
            let jsonStr = ns.substring(with: r)
            guard let jsonData = jsonStr.data(using: .utf8) else { continue }

            let obj = try? JSONSerialization.jsonObject(with: jsonData)

            // Objet direct
            if let dict = obj as? [String: Any], let info = extractProduct(from: dict) { return info }

            // Tableau
            if let arr = obj as? [[String: Any]] {
                for dict in arr { if let info = extractProduct(from: dict) { return info } }
            }

            // Pattern @graph
            if let dict = obj as? [String: Any],
               let graph = dict["@graph"] as? [[String: Any]] {
                for item in graph { if let info = extractProduct(from: item) { return info } }
            }
        }
        return nil
    }

    private func extractProduct(from json: [String: Any]) -> ProductInfo? {
        let type = json["@type"] as? String ?? ""
        guard type.contains("Product") else { return nil }

        var info = ProductInfo()
        info.title = json["name"] as? String ?? ""

        if let brandObj = json["brand"] as? [String: Any] {
            info.brand = brandObj["name"] as? String ?? ""
        } else if let brand = json["brand"] as? String {
            info.brand = brand
        }

        info.color    = json["color"]    as? String ?? ""
        info.material = json["material"] as? String ?? ""

        func priceFrom(_ offers: [String: Any]) -> String {
            if let p = offers["price"] as? Double  { return String(format: "%.2f", p) }
            if let p = offers["price"] as? String  { return p }
            return ""
        }
        if let o = json["offers"] as? [String: Any] { info.price = priceFrom(o) }
        else if let arr = json["offers"] as? [[String: Any]], let first = arr.first { info.price = priceFrom(first) }

        if let s = json["image"] as? String                                            { info.imageURL = URL(string: s) }
        else if let arr = json["image"] as? [String], let s = arr.first               { info.imageURL = URL(string: s) }
        else if let obj = json["image"] as? [String: Any], let s = obj["url"] as? String { info.imageURL = URL(string: s) }

        return info.title.isEmpty ? nil : info
    }

    // MARK: - Gemini fallback

    private func parseWithGemini(html: String) async throws -> ProductInfo {
        // Nettoyage HTML pour réduire les tokens
        let stripped = html
            .replacingOccurrences(of: "<script[\\s\\S]*?</script>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "<style[\\s\\S]*?</style>",  with: " ", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let truncated = String(stripped.prefix(3000))

        let prompt = """
        Extrait les informations d'un vêtement depuis ce contenu de page produit e-commerce.
        Réponds UNIQUEMENT avec un objet JSON valide, sans markdown, avec exactement ces clés \
        (laisser vide si absent) :
        {"title":"","brand":"","color":"","material":"","price":""}

        Contenu :
        \(truncated)
        """

        let response = try await GeminiService.shared.generate(prompt: prompt)

        // Extraire le JSON de la réponse (peut avoir du texte autour)
        guard let start = response.firstIndex(of: "{"),
              let end   = response.lastIndex(of: "}")
        else { return ProductInfo() }

        let jsonStr = String(response[start...end])
        guard let jsonData = jsonStr.data(using: .utf8),
              let dict = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: String]
        else { return ProductInfo() }

        var info = ProductInfo()
        info.title    = dict["title"]    ?? ""
        info.brand    = dict["brand"]    ?? ""
        info.color    = dict["color"]    ?? ""
        info.material = dict["material"] ?? ""
        info.price    = dict["price"]    ?? ""
        return info
    }
}
