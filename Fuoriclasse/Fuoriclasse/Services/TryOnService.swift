import UIKit

// MARK: - Erreurs

enum TryOnError: LocalizedError {
    case noPersonPhoto
    case noGarmentPhoto
    case generationFailed(String)
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .noPersonPhoto:           return "Ajoute une photo de profil dans ton profil"
        case .noGarmentPhoto:          return "Ajoute une photo à cette pièce"
        case .generationFailed(let m): return m
        case .downloadFailed:          return "Téléchargement de l'image échoué"
        }
    }
}

// MARK: - Service

actor TryOnService {
    static let shared = TryOnService()

    private var supabaseURL: String { secret("SUPABASE_URL") }
    private var supabaseAnon: String { secret("SUPABASE_ANON_KEY") }

    private func secret(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let val  = dict[key] as? String, !val.isEmpty
        else { return "" }
        return val
    }

    // MARK: - Public

    func generate(personImage: Data, garmentImage: Data, category: String, itemTitle: String) async throws -> UIImage {
        let personJPEG  = resized(personImage,  maxSide: 768) ?? personImage
        let garmentJPEG = resized(garmentImage, maxSide: 768) ?? garmentImage

        // 1. Edge function fait tout : créer + poller + retourner l'URL
        let outputURL = try await callEdgeFunction(
            personJPEG: personJPEG,
            garmentJPEG: garmentJPEG,
            category: mapCategory(category),
            description: "\(itemTitle) \(category)"
        )

        // 2. Télécharger l'image résultante
        return try await downloadImage(from: outputURL)
    }

    // MARK: - Resize

    private func resized(_ data: Data, maxSide: CGFloat) -> Data? {
        guard let img = UIImage(data: data) else { return nil }
        let size = img.size
        let ratio = min(maxSide / size.width, maxSide / size.height, 1.0)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let out = renderer.image { _ in img.draw(in: CGRect(origin: .zero, size: newSize)) }
        return out.jpegData(compressionQuality: 0.75)
    }

    // MARK: - Mapping catégories

    private func mapCategory(_ french: String) -> String {
        let lower = french.lowercased()
        if lower.contains("bas") || lower.contains("pantalon") ||
           lower.contains("jupe") || lower.contains("short") { return "lower_body" }
        if lower.contains("robe") { return "dresses" }
        return "upper_body"
    }

    // MARK: - Edge Function (crée + poll + retourne URL)

    private func callEdgeFunction(personJPEG: Data, garmentJPEG: Data,
                                   category: String, description: String) async throws -> URL {
        let edgeURL = URL(string: "\(supabaseURL)/functions/v1/tryon-start")!

        var req = URLRequest(url: edgeURL, timeoutInterval: 120) // ~100s de polling côté serveur
        req.httpMethod = "POST"
        req.setValue("Bearer \(supabaseAnon)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json",       forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "personBase64":  personJPEG.base64EncodedString(),
            "garmentBase64": garmentJPEG.base64EncodedString(),
            "category":      category,
            "description":   description
        ])

        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]

        if status != 200 {
            let msg = json["error"] as? String ?? "Erreur Edge Function (\(status))"
            throw TryOnError.generationFailed(msg)
        }

        guard let urlString = json["outputUrl"] as? String, let url = URL(string: urlString)
        else { throw TryOnError.generationFailed("URL de résultat introuvable") }

        return url
    }

    // MARK: - Download image

    private func downloadImage(from url: URL) async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw TryOnError.downloadFailed
        }
        guard let image = UIImage(data: data) else { throw TryOnError.downloadFailed }
        return image
    }
}
