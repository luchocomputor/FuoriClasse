import Foundation

// MARK: - Erreurs

enum Mesh3DError: LocalizedError {
    case apiKeyMissing
    case noImage
    case apiError(Int)
    case generationFailed(String)
    case timeout
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:           return "Clé REPLICATE_API_KEY manquante dans Secrets.plist"
        case .noImage:                 return "Ajoute d'abord une photo à cette pièce"
        case .apiError(let code):      return "Erreur API Replicate (\(code))"
        case .generationFailed(let m): return m
        case .timeout:                 return "Temps dépassé — réessaie avec une photo plus simple"
        case .downloadFailed:          return "Téléchargement du modèle 3D échoué"
        }
    }
}

// MARK: - Service

actor Mesh3DService {
    static let shared = Mesh3DService()

    private let pollInterval: UInt64 = 4_000_000_000 // 4 secondes
    private let maxPolls = 25                         // ~100 secondes max

    // MARK: - API token

    private var apiToken: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key  = dict["REPLICATE_API_KEY"] as? String,
              !key.isEmpty, key != "YOUR_REPLICATE_KEY_HERE"
        else { return "" }
        return key
    }

    // MARK: - Public

    /// Génère un mesh 3D depuis `imageData` et retourne l'URL locale du fichier .glb
    func generate(imageData: Data, itemID: UUID) async throws -> URL {
        guard !apiToken.isEmpty  else { throw Mesh3DError.apiKeyMissing }

        // Encode image en data URI
        let b64 = imageData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(b64)"

        // 1. Créer la prédiction Replicate (TripoSR)
        let predID = try await createPrediction(imageInput: dataURI)

        // 2. Poller jusqu'à succès
        let outputURL = try await pollPrediction(id: predID)

        // 3. Télécharger et stocker localement
        return try await downloadMesh(from: outputURL, itemID: itemID)
    }

    /// Vérifie si un mesh local existe pour cet item
    nonisolated func localMeshURL(for itemID: UUID) -> URL? {
        let url = meshFileURL(for: itemID)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Supprime le mesh local
    nonisolated func deleteMesh(for itemID: UUID) {
        try? FileManager.default.removeItem(at: meshFileURL(for: itemID))
    }

    // MARK: - Replicate API

    private func createPrediction(imageInput: String) async throws -> String {
        // Utilise l'endpoint "latest version" du modèle TripoSR
        let url = URL(string: "https://api.replicate.com/v1/models/stability-ai/triposr/predictions")!

        var req = URLRequest(url: url, timeoutInterval: 30)
        req.httpMethod = "POST"
        req.setValue("Token \(apiToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json",  forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "input": [
                "image":                 imageInput,
                "do_remove_background":  true,
                "foreground_ratio":      0.85
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard status == 201 else { throw Mesh3DError.apiError(status) }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id   = json["id"] as? String
        else { throw Mesh3DError.generationFailed("ID de prédiction introuvable") }

        return id
    }

    private func pollPrediction(id: String) async throws -> URL {
        let url = URL(string: "https://api.replicate.com/v1/predictions/\(id)")!

        for _ in 0..<maxPolls {
            try await Task.sleep(nanoseconds: pollInterval)

            var req = URLRequest(url: url, timeoutInterval: 15)
            req.setValue("Token \(apiToken)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { continue }

            let predStatus = json["status"] as? String ?? ""

            switch predStatus {
            case "succeeded":
                // Output : tableau de strings ou string directe
                if let arr = json["output"] as? [String], let first = arr.first, let u = URL(string: first) {
                    return u
                }
                if let s = json["output"] as? String, let u = URL(string: s) {
                    return u
                }
                throw Mesh3DError.generationFailed("Format de sortie inattendu")

            case "failed", "canceled":
                let msg = json["error"] as? String ?? "Génération annulée"
                throw Mesh3DError.generationFailed(msg)

            default:
                continue // starting / processing
            }
        }
        throw Mesh3DError.timeout
    }

    private func downloadMesh(from remoteURL: URL, itemID: UUID) async throws -> URL {
        let (data, response) = try await URLSession.shared.data(from: remoteURL)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw Mesh3DError.downloadFailed
        }
        let localURL = meshFileURL(for: itemID)
        try data.write(to: localURL, options: .atomic)
        return localURL
    }

    // MARK: - Chemins locaux

    nonisolated private func meshFileURL(for itemID: UUID) -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(itemID.uuidString).glb")
    }
}
