import Foundation

@MainActor
final class AvatarManager: ObservableObject {

    @Published var avatarURL: URL?

    var hasAvatar: Bool { avatarURL != nil }

    init() {
        loadLocalAvatar()
    }

    func loadLocalAvatar() {
        avatarURL = AvaturnService.shared.localAvatarURL
    }

    func deleteAvatar() {
        AvaturnService.shared.deleteAvatar()
        avatarURL = nil
    }
}
