import Foundation

// MARK: - Erreurs

enum AvaturnError: LocalizedError {
    case embedURLMissing
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .embedURLMissing: return "AVATURN_EMBED_URL manquante dans Secrets.plist"
        case .downloadFailed:  return "Téléchargement de l'avatar échoué"
        }
    }
}

// MARK: - Service

actor AvaturnService {
    static let shared = AvaturnService()

    // MARK: - URL embed du projet (free tier — pas besoin d'API token)

    nonisolated var embedURL: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let url  = dict["AVATURN_EMBED_URL"] as? String,
              !url.isEmpty, url != "YOUR_AVATURN_EMBED_URL_HERE"
        else { return "" }
        return url
    }

    // MARK: - Chemin local

    /// URL locale du fichier avatar (Documents/avatar.glb)
    /// Cherche l'avatar local (usdz en priorité, puis glb)
    nonisolated var localAvatarURL: URL? {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for ext in ["usdz", "glb"] {
            let url = base.appendingPathComponent("avatar.\(ext)")
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        return nil
    }

    nonisolated var hasAvatar: Bool { localAvatarURL != nil }

    // MARK: - Download

    /// Télécharge/décode le GLB et le sauvegarde dans Documents/avatar.glb.
    /// Gère deux formats :
    /// - HttpURL (recommandé) : URL HTTP → téléchargement standard
    /// - DataURL (fallback)   : data:model/gltf-binary;base64,... → décodage base64
    func downloadAvatar(from source: URL) async throws -> URL {
        let data: Data

        if source.scheme == "data" {
            let raw = source.absoluteString
            guard let commaRange = raw.range(of: ",") else { throw AvaturnError.downloadFailed }
            let b64 = String(raw[commaRange.upperBound...])
            guard let decoded = Data(base64Encoded: b64, options: .ignoreUnknownCharacters) else {
                throw AvaturnError.downloadFailed
            }
            data = decoded
        } else {
            let (downloaded, response) = try await URLSession.shared.data(from: source)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw AvaturnError.downloadFailed
            }
            data = downloaded
        }

        // Sauvegarde avec la bonne extension (usdz ou glb)
        let ext  = source.pathExtension.lowercased()
        let name = (ext == "usdz" || ext == "glb") ? "avatar.\(ext)" : "avatar.glb"
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let local = base.appendingPathComponent(name)

        // Supprime les anciens fichiers avatar (évite les conflits d'extension)
        for old in ["avatar.usdz", "avatar.glb"] {
            try? FileManager.default.removeItem(at: base.appendingPathComponent(old))
        }
        try data.write(to: local, options: .atomic)
        return local
    }

    /// Supprime l'avatar local
    /// Récupère l'URL du dernier avatar via l'API Avaturn (avec token Firebase user)
    func fetchLatestAvatarURL(bearerToken: String) async throws -> URL? {
        var req = URLRequest(url: URL(string: "https://api.avaturn.me/avatars")!)
        req.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return nil }

        // Formats possibles : tableau ou {"items":[...]} ou {"avatars":[...]}
        var items: [[String: Any]] = []
        if let arr = json as? [[String: Any]] { items = arr }
        else if let obj = json as? [String: Any] {
            items = (obj["items"] as? [[String: Any]])
                 ?? (obj["avatars"] as? [[String: Any]])
                 ?? []
        }
        // Préfère le plus récent (premier élément), priorité usdz > glb
        for item in items {
            let urlStr = (item["usdzUrl"] as? String)
                      ?? (item["modelUrl"] as? String)
                      ?? (item["glbUrl"] as? String)
                      ?? (item["url"] as? String)
            if let urlStr, let url = URL(string: urlStr) { return url }
        }
        return nil
    }

    nonisolated func deleteAvatar() {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for ext in ["usdz", "glb"] {
            try? FileManager.default.removeItem(at: base.appendingPathComponent("avatar.\(ext)"))
        }
    }
}
