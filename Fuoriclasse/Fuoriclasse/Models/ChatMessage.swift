import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let text: String
    let imageData: Data?
    let timestamp = Date()

    enum Role { case user, assistant }
}
