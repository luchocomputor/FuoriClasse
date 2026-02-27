import Foundation

struct SocialPost: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let outfitTitle: String?
    let notes: String?
    let imageUrls: [String]
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, notes
        case userId = "user_id"
        case outfitTitle = "outfit_title"
        case imageUrls = "image_urls"
        case createdAt = "created_at"
    }
}

struct FollowRow: Codable {
    let id: UUID
    let followerId: UUID
    let followingId: UUID
    enum CodingKeys: String, CodingKey {
        case id
        case followerId = "follower_id"
        case followingId = "following_id"
    }
}

struct PostLikeRow: Codable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
    }
}

// ViewModel enrichi pour l'affichage dans le feed
struct FeedPost: Identifiable {
    let id: UUID
    let post: SocialPost
    let authorId: UUID
    let authorUsername: String
    var likesCount: Int
    var isLiked: Bool
}

// Profil public pour recherche / UserPublicProfileView
struct PublicProfile: Identifiable, Hashable {
    let id: UUID
    let username: String
    let bio: String?
    let location: String?
}
