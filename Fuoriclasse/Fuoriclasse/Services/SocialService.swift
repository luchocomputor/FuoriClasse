import Foundation
import Supabase

final class SocialService {
    static let shared = SocialService()
    private init() {}

    private var client: SupabaseClient { SupabaseService.shared.client }

    // MARK: - Storage

    func uploadImages(_ images: [Data]) async throws -> [String] {
        var urls: [String] = []
        for imageData in images.prefix(3) {
            let path = "\(UUID().uuidString).jpg"
            try await client.storage
                .from("post-images")
                .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))
            let publicURL = try client.storage
                .from("post-images")
                .getPublicURL(path: path)
            urls.append(publicURL.absoluteString)
        }
        return urls
    }

    // MARK: - Posts

    func createPost(userId: UUID, outfitTitle: String?, notes: String?, imageUrls: [String]) async throws {
        struct PostInsert: Encodable {
            let user_id: UUID
            let outfit_title: String?
            let notes: String?
            let image_urls: [String]
        }
        try await client
            .from("posts")
            .insert(PostInsert(user_id: userId, outfit_title: outfitTitle, notes: notes, image_urls: imageUrls))
            .execute()
    }

    // MARK: - Feed

    func fetchFeed(currentUserId: UUID) async throws -> [FeedPost] {
        // Récupère les IDs des utilisateurs suivis
        struct FollowingResult: Decodable {
            let following_id: UUID
        }
        let followingRows: [FollowingResult] = try await client
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: currentUserId.uuidString)
            .execute()
            .value

        var followingIds = followingRows.map { $0.following_id.uuidString }
        followingIds.append(currentUserId.uuidString)

        let posts: [SocialPost] = try await client
            .from("posts")
            .select("*")
            .in("user_id", values: followingIds)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value

        return try await enrichPosts(posts, currentUserId: currentUserId)
    }

    func fetchDiscover(currentUserId: UUID) async throws -> [FeedPost] {
        let posts: [SocialPost] = try await client
            .from("posts")
            .select("*")
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value

        return try await enrichPosts(posts, currentUserId: currentUserId)
    }

    func fetchUserPosts(userId: UUID, currentUserId: UUID) async throws -> [FeedPost] {
        let posts: [SocialPost] = try await client
            .from("posts")
            .select("*")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return try await enrichPosts(posts, currentUserId: currentUserId)
    }

    // MARK: - Helpers

    private func enrichPosts(_ posts: [SocialPost], currentUserId: UUID) async throws -> [FeedPost] {
        guard !posts.isEmpty else { return [] }

        let userIds = Array(Set(posts.map { $0.userId.uuidString }))
        let postIds = posts.map { $0.id.uuidString }

        // Profils des auteurs
        struct ProfileRow: Decodable {
            let id: UUID
            let username: String?
        }
        let profiles: [ProfileRow] = try await client
            .from("profiles")
            .select("id, username")
            .in("id", values: userIds)
            .execute()
            .value
        let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0.username ?? "Utilisateur") })

        // Likes count
        struct LikeCountRow: Decodable {
            let post_id: UUID
        }
        let allLikes: [LikeCountRow] = try await client
            .from("post_likes")
            .select("post_id")
            .in("post_id", values: postIds)
            .execute()
            .value

        var likesCountMap: [UUID: Int] = [:]
        for like in allLikes {
            likesCountMap[like.post_id, default: 0] += 1
        }

        // Mes likes
        struct MyLikeRow: Decodable {
            let post_id: UUID
        }
        let myLikes: [MyLikeRow] = try await client
            .from("post_likes")
            .select("post_id")
            .eq("user_id", value: currentUserId.uuidString)
            .in("post_id", values: postIds)
            .execute()
            .value
        let myLikedIds = Set(myLikes.map { $0.post_id })

        return posts.map { post in
            FeedPost(
                id: post.id,
                post: post,
                authorId: post.userId,
                authorUsername: profileMap[post.userId] ?? "Utilisateur",
                likesCount: likesCountMap[post.id] ?? 0,
                isLiked: myLikedIds.contains(post.id)
            )
        }
    }

    // MARK: - Search

    func searchUsers(query: String) async throws -> [PublicProfile] {
        struct ProfileResult: Decodable {
            let id: UUID
            let username: String?
            let bio: String?
            let location: String?
        }
        let results: [ProfileResult] = try await client
            .from("profiles")
            .select("id, username, bio, location")
            .ilike("username", pattern: "%\(query)%")
            .limit(20)
            .execute()
            .value

        return results.map {
            PublicProfile(id: $0.id, username: $0.username ?? "Utilisateur", bio: $0.bio, location: $0.location)
        }
    }

    // MARK: - Follow

    func follow(followerId: UUID, targetId: UUID) async throws {
        struct FollowInsert: Encodable {
            let follower_id: UUID
            let following_id: UUID
        }
        try await client
            .from("follows")
            .insert(FollowInsert(follower_id: followerId, following_id: targetId))
            .execute()
    }

    func unfollow(followerId: UUID, targetId: UUID) async throws {
        try await client
            .from("follows")
            .delete()
            .eq("follower_id", value: followerId.uuidString)
            .eq("following_id", value: targetId.uuidString)
            .execute()
    }

    func isFollowing(followerId: UUID, targetId: UUID) async throws -> Bool {
        struct CheckRow: Decodable { let id: UUID }
        let rows: [CheckRow] = try await client
            .from("follows")
            .select("id")
            .eq("follower_id", value: followerId.uuidString)
            .eq("following_id", value: targetId.uuidString)
            .execute()
            .value
        return !rows.isEmpty
    }

    // MARK: - Likes

    func likePost(postId: UUID, userId: UUID) async throws {
        struct LikeInsert: Encodable {
            let post_id: UUID
            let user_id: UUID
        }
        try await client
            .from("post_likes")
            .insert(LikeInsert(post_id: postId, user_id: userId))
            .execute()
    }

    func unlikePost(postId: UUID, userId: UUID) async throws {
        try await client
            .from("post_likes")
            .delete()
            .eq("post_id", value: postId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Followers / Following lists

    func fetchFollowers(userId: UUID) async throws -> [PublicProfile] {
        struct FollowerRow: Decodable { let follower_id: UUID }
        let rows: [FollowerRow] = try await client
            .from("follows")
            .select("follower_id")
            .eq("following_id", value: userId.uuidString)
            .execute()
            .value
        let ids = rows.map { $0.follower_id.uuidString }
        guard !ids.isEmpty else { return [] }
        return try await fetchProfiles(ids: ids)
    }

    func fetchFollowing(userId: UUID) async throws -> [PublicProfile] {
        struct FollowingRow: Decodable { let following_id: UUID }
        let rows: [FollowingRow] = try await client
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: userId.uuidString)
            .execute()
            .value
        let ids = rows.map { $0.following_id.uuidString }
        guard !ids.isEmpty else { return [] }
        return try await fetchProfiles(ids: ids)
    }

    private func fetchProfiles(ids: [String]) async throws -> [PublicProfile] {
        struct ProfileResult: Decodable {
            let id: UUID; let username: String?; let bio: String?; let location: String?
        }
        let profiles: [ProfileResult] = try await client
            .from("profiles")
            .select("id, username, bio, location")
            .in("id", values: ids)
            .execute()
            .value
        return profiles.map {
            PublicProfile(id: $0.id, username: $0.username ?? "Utilisateur", bio: $0.bio, location: $0.location)
        }
    }

    // MARK: - Stats

    func fetchFollowStats(userId: UUID) async throws -> (followers: Int, following: Int) {
        struct CountRow: Decodable { let id: UUID }

        let followersRows: [CountRow] = try await client
            .from("follows")
            .select("id")
            .eq("following_id", value: userId.uuidString)
            .execute()
            .value

        let followingRows: [CountRow] = try await client
            .from("follows")
            .select("id")
            .eq("follower_id", value: userId.uuidString)
            .execute()
            .value

        return (followers: followersRows.count, following: followingRows.count)
    }
}
