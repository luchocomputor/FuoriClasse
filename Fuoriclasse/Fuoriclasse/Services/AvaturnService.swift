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
    nonisolated var localAvatarURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("avatar.glb")
    }

    nonisolated var hasAvatar: Bool {
        FileManager.default.fileExists(atPath: localAvatarURL.path)
    }

    // MARK: - Download

    /// Télécharge/décode le GLB et le sauvegarde dans Documents/avatar.glb.
    /// Gère deux formats :
    /// - HttpURL (recommandé) : URL HTTP → téléchargement standard
    /// - DataURL (fallback)   : data:model/gltf-binary;base64,... → décodage base64
    func downloadAvatar(from source: URL) async throws -> URL {
        let data: Data

        if source.scheme == "data" {
            // DataURL : extraire la partie base64 après la virgule
            let raw = source.absoluteString
            guard let commaRange = raw.range(of: ",") else { throw AvaturnError.downloadFailed }
            let b64 = String(raw[commaRange.upperBound...])
            guard let decoded = Data(base64Encoded: b64, options: .ignoreUnknownCharacters) else {
                throw AvaturnError.downloadFailed
            }
            data = decoded
        } else {
            // HttpURL : téléchargement réseau standard
            let (downloaded, response) = try await URLSession.shared.data(from: source)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw AvaturnError.downloadFailed
            }
            data = downloaded
        }

        let local = localAvatarURL
        try data.write(to: local, options: .atomic)
        return local
    }

    /// Supprime l'avatar local
    nonisolated func deleteAvatar() {
        try? FileManager.default.removeItem(at: localAvatarURL)
    }
}
