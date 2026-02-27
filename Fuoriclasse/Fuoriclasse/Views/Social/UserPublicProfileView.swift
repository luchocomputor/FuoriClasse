import SwiftUI

struct UserPublicProfileView: View {
    @EnvironmentObject var auth: AuthManager

    let profile: PublicProfile

    @State private var posts: [FeedPost] = []
    @State private var followStats: (followers: Int, following: Int) = (0, 0)
    @State private var isFollowing = false
    @State private var isLoadingFollow = false
    @State private var isLoading = true

    private var currentUserId: UUID? { auth.session?.user.id }
    private var isOwnProfile: Bool { currentUserId == profile.id }

    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 40/255, green: 10/255, blue: 90/255),
                    Color(red: 15/255, green: 5/255, blue: 40/255)
                ]),
                center: .center, startRadius: 100, endRadius: 500
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Avatar + infos
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color(red: 120/255, green: 60/255, blue: 200/255))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Text(String(profile.username.prefix(2)).uppercased())
                                    .font(.custom("Futura-Bold", size: 24))
                                    .foregroundColor(.white)
                            )

                        Text("@\(profile.username)")
                            .font(.custom("Futura-Bold", size: 20))
                            .foregroundColor(.white)

                        if let bio = profile.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }

                        if let location = profile.location, !location.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                                Text(location)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.top, 8)

                    // Stats
                    HStack(spacing: 32) {
                        statsItem(value: followStats.followers, label: "Abonnés")
                        statsItem(value: followStats.following, label: "Abonnements")
                        statsItem(value: posts.count, label: "Posts")
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)

                    // Follow button
                    if !isOwnProfile {
                        Button {
                            Task { await toggleFollow() }
                        } label: {
                            HStack(spacing: 8) {
                                if isLoadingFollow {
                                    ProgressView().tint(.white).scaleEffect(0.85)
                                } else {
                                    Image(systemName: isFollowing ? "person.badge.minus" : "person.badge.plus")
                                    Text(isFollowing ? "Ne plus suivre" : "Suivre")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 32)
                            .background(
                                Capsule()
                                    .fill(isFollowing
                                          ? Color.white.opacity(0.12)
                                          : Color(red: 120/255, green: 60/255, blue: 200/255))
                                    .shadow(color: Color(red: 120/255, green: 60/255, blue: 200/255).opacity(isFollowing ? 0 : 0.4),
                                            radius: 10, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoadingFollow)
                    }

                    // Posts grid
                    if isLoading {
                        ProgressView()
                            .tint(.white.opacity(0.5))
                            .padding(.top, 32)
                    } else if posts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.2))
                            Text("Aucun post pour l'instant")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        .padding(.top, 32)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(posts) { feedPost in
                                postGridCell(feedPost: feedPost)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(profile.username)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadData() }
    }

    @ViewBuilder
    private func statsItem(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.custom("Futura-Bold", size: 20))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    @ViewBuilder
    private func postGridCell(feedPost: FeedPost) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let firstUrl = feedPost.post.imageUrls.first {
                AsyncImage(url: URL(string: firstUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipped()
                    default:
                        Rectangle()
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 120)
                            .overlay(Image(systemName: "hanger").foregroundColor(.white.opacity(0.2)))
                    }
                }
                .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 120)
                    .overlay(Image(systemName: "hanger").foregroundColor(.white.opacity(0.2)))
            }

            if let title = feedPost.post.outfitTitle {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.bottom, 4)
    }

    private func loadData() async {
        guard let currentId = currentUserId else { return }
        isLoading = true
        async let postsTask = SocialService.shared.fetchUserPosts(userId: profile.id, currentUserId: currentId)
        async let statsTask = SocialService.shared.fetchFollowStats(userId: profile.id)
        async let followTask = SocialService.shared.isFollowing(followerId: currentId, targetId: profile.id)

        do {
            let (fetchedPosts, stats, following) = try await (postsTask, statsTask, followTask)
            posts = fetchedPosts
            followStats = stats
            isFollowing = following
        } catch {
            // Silently ignore — affiche état vide
        }
        isLoading = false
    }

    private func toggleFollow() async {
        guard let currentId = currentUserId else { return }
        isLoadingFollow = true
        defer { isLoadingFollow = false }
        do {
            if isFollowing {
                try await SocialService.shared.unfollow(followerId: currentId, targetId: profile.id)
                isFollowing = false
                followStats.followers = max(0, followStats.followers - 1)
            } else {
                try await SocialService.shared.follow(followerId: currentId, targetId: profile.id)
                isFollowing = true
                followStats.followers += 1
            }
        } catch { /* Silently ignore */ }
    }
}
