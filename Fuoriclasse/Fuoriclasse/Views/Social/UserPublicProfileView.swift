import SwiftUI

struct UserPublicProfileView: View {
    @EnvironmentObject var auth: AuthManager

    let profile: PublicProfile

    @State private var posts: [FeedPost] = []
    @State private var followStats: (followers: Int, following: Int) = (0, 0)
    @State private var isFollowing = false
    @State private var isLoadingFollow = false
    @State private var isLoading = true
    @State private var followListTarget: FollowListTarget? = nil

    private var currentUserId: UUID? { auth.session?.user.id }
    private var isOwnProfile: Bool { currentUserId == profile.id }
    private var isLocked: Bool { profile.isPrivate && !isFollowing && !isOwnProfile }

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
                VStack(alignment: .leading, spacing: 0) {
                    profileHeader
                        .padding(.top, 12)
                        .padding(.bottom, 16)

                    Divider()
                        .background(Color.white.opacity(0.1))

                    if isLocked {
                        lockedState
                    } else {
                        postsGrid
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(profile.username)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $followListTarget) { target in
            switch target {
            case .followers(let id):
                FollowersListView(userId: id, mode: .followers).environmentObject(auth)
            case .following(let id):
                FollowersListView(userId: id, mode: .following).environmentObject(auth)
            }
        }
        .task { await loadData() }
    }

    // MARK: - Header (Instagram-style)

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Ligne avatar + stats
            HStack(alignment: .center, spacing: 0) {
                avatarCircle(size: 86)
                Spacer(minLength: 16)
                statsRow
            }
            .padding(.horizontal, 16)

            // Identité
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.username)
                    .font(.custom("Futura-Bold", size: 16))
                    .foregroundColor(.white)
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(3)
                }
                if let location = profile.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill").font(.system(size: 11))
                        Text(location).font(.system(size: 12, weight: .light))
                    }
                    .foregroundColor(.white.opacity(0.45))
                }
            }
            .padding(.horizontal, 16)

            // Bouton Suivre / modifier
            if !isOwnProfile {
                followButton
                    .padding(.horizontal, 16)
            }
        }
    }

    private func avatarCircle(size: CGFloat) -> some View {
        let parts = profile.username.split(separator: " ")
        let initials = parts.count >= 2
            ? String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
            : String(profile.username.prefix(2)).uppercased()
        return Circle()
            .fill(LinearGradient(
                colors: [Color(red: 120/255, green: 60/255, blue: 200/255),
                         Color(red: 80/255, green: 30/255, blue: 140/255)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.custom("Futura-Bold", size: size * 0.32))
                    .foregroundColor(.white)
            )
            .overlay(
                Circle().stroke(
                    LinearGradient(
                        colors: [Color(red: 180/255, green: 120/255, blue: 255/255).opacity(0.6),
                                 Color.clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
            )
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: posts.count, label: "publications")

            statDivider

            Button {
                followListTarget = .followers(profile.id)
            } label: {
                statCell(value: followStats.followers, label: "abonnés")
            }
            .buttonStyle(.plain)

            statDivider

            Button {
                followListTarget = .following(profile.id)
            } label: {
                statCell(value: followStats.following, label: "abonnements")
            }
            .buttonStyle(.plain)
        }
    }

    private func statCell(value: Int, label: String) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.custom("Futura-Bold", size: 18))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .tracking(0.1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1, height: 26)
    }

    private var followButton: some View {
        Button {
            Task { await toggleFollow() }
        } label: {
            HStack(spacing: 8) {
                if isLoadingFollow {
                    ProgressView().tint(.white).scaleEffect(0.85)
                } else {
                    Text(isFollowing ? "Suivi" : "Suivre")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isFollowing ? .white.opacity(0.8) : .white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(isFollowing
                          ? Color.white.opacity(0.09)
                          : Color(red: 120/255, green: 60/255, blue: 200/255))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color.white.opacity(isFollowing ? 0.2 : 0), lineWidth: 1)
                    )
                    .shadow(
                        color: Color(red: 120/255, green: 60/255, blue: 200/255).opacity(isFollowing ? 0 : 0.35),
                        radius: 8, x: 0, y: 3
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoadingFollow)
    }

    // MARK: - Locked state (profil privé)

    private var lockedState: some View {
        VStack(spacing: 18) {
            Spacer().frame(height: 32)
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 160/255, green: 100/255, blue: 240/255),
                                 Color(red: 100/255, green: 60/255, blue: 180/255)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            Text("Ce compte est privé")
                .font(.custom("Futura-Bold", size: 18))
                .foregroundColor(.white.opacity(0.7))
            Text("Abonne-toi pour voir ses publications.")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    // MARK: - Posts grid (3 colonnes, carré comme Instagram)

    @ViewBuilder
    private var postsGrid: some View {
        if isLoading {
            HStack { Spacer(); ProgressView().tint(.white.opacity(0.5)); Spacer() }
                .padding(.top, 48)
        } else if posts.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "camera")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(0.15))
                Text("Aucune publication")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 48)
        } else {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3),
                spacing: 2
            ) {
                ForEach(posts) { feedPost in
                    postSquare(feedPost: feedPost)
                }
            }
            .padding(.top, 2)
        }
    }

    @ViewBuilder
    private func postSquare(feedPost: FeedPost) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                if let firstUrl = feedPost.post.imageUrls.first {
                    AsyncImage(url: URL(string: firstUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Rectangle().fill(Color.white.opacity(0.07))
                                .overlay(Image(systemName: "hanger").foregroundColor(.white.opacity(0.2)))
                        }
                    }
                } else {
                    Rectangle().fill(Color.white.opacity(0.07))
                        .overlay(Image(systemName: "hanger").foregroundColor(.white.opacity(0.2)))
                }

                // Overlay gradient + like count
                LinearGradient(
                    colors: [.clear, .black.opacity(0.45)],
                    startPoint: .center, endPoint: .bottom
                )

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.85))
                    Text("\(feedPost.likesCount)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(6)
            }
            .frame(width: geo.size.width, height: geo.size.width) // carré
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Data loading

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
        } catch {}
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
        } catch {}
    }
}
