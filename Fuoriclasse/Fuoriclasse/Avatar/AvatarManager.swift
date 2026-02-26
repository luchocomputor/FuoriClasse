import Foundation
import Combine

@MainActor
final class AvatarManager: ObservableObject {

    @Published var avatarURL: URL?

    var hasAvatar: Bool { avatarURL != nil }

    init() {
        loadLocalAvatar()
    }

    /// Charge l'avatar depuis le filesystem (Documents/avatar.glb).
    /// Appeler en onAppear si plusieurs vues utilisent la même instance.
    func loadLocalAvatar() {
        let url = AvaturnService.shared.localAvatarURL
        avatarURL = FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Supprime l'avatar local et réinitialise l'état.
    func deleteAvatar() {
        AvaturnService.shared.deleteAvatar()
        avatarURL = nil
    }
}
