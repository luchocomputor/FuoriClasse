import SwiftUI

struct SocialFeedView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.managedObjectContext) var viewContext

    @State private var selectedTab = 0
    @State private var feedPosts: [FeedPost] = []
    @State private var discoverPosts: [FeedPost] = []
    @State private var isLoading = false
    @State private var showCreatePost = false
    @State private var showSearch = false
    @State private var navigateToProfile: PublicProfile? = nil

    private var currentUserId: UUID? { auth.session?.user.id }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    HStack(alignment: .center) {
                        Text("Social")
                            .font(.custom("Futura-Bold", size: 30))
                            .foregroundStyle(LinearGradient(
                                colors: [.white, Color(red: 210/255, green: 170/255, blue: 255/255)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                        Spacer()
                        Button { showSearch = true } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 120/255, green: 60/255, blue: 200/255))
                                    .frame(width: 40, height: 40)
                                    .shadow(
                                        color: Color(red: 120/255, green: 60/255, blue: 200/255).opacity(0.45),
                                        radius: 8, x: 0, y: 3
                                    )
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    segmentedControl
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)

                    if selectedTab == 0 {
                        feedContent
                    } else {
                        discoverContent
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bouton + flottant
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { showCreatePost = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Publier")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 24)
                            .background(
                                Capsule()
                                    .fill(Color(red: 120/255, green: 60/255, blue: 200/255))
                                    .shadow(color: Color(red: 120/255, green: 60/255, blue: 200/255).opacity(0.5),
                                            radius: 12, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background {
                ZStack {
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 40/255, green: 10/255, blue: 90/255),
                            Color(red: 15/255, green: 5/255, blue: 40/255)
                        ]),
                        center: .center, startRadius: 100, endRadius: 500
                    )
                    FluidBackgroundView()
                }
                .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $navigateToProfile) { profile in
                UserPublicProfileView(profile: profile)
                    .environmentObject(auth)
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(onPosted: {
                    await refreshFeed()
                })
                .environmentObject(auth)
                .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showSearch) {
                UserSearchView()
                    .environmentObject(auth)
            }
            .task { await refreshFeed() }
        }
    }

    // MARK: - Segmented control

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach([("Abonnements", 0), ("Découvrir", 1)], id: \.1) { label, tag in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tag }
                } label: {
                    Text(label)
                        .font(.system(size: 14, weight: selectedTab == tag ? .semibold : .regular))
                        .foregroundColor(selectedTab == tag ? .white : .white.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if selectedTab == tag {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(Color.white.opacity(0.15))
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Feed (Abonnements)

    private var feedContent: some View {
        Group {
            if isLoading && feedPosts.isEmpty {
                loadingState
            } else if feedPosts.isEmpty {
                emptyFeedState
            } else {
                postList(posts: $feedPosts)
            }
        }
    }

    // MARK: - Découvrir

    private var discoverContent: some View {
        Group {
            if isLoading && discoverPosts.isEmpty {
                loadingState
            } else if discoverPosts.isEmpty {
                emptyDiscoverState
            } else {
                postList(posts: $discoverPosts)
            }
        }
    }

    // MARK: - Post list

    private func postList(posts: Binding<[FeedPost]>) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(posts.indices, id: \.self) { index in
                    SocialPostCard(
                        feedPost: posts[index].wrappedValue,
                        onLikeTap: { Task { await toggleLike(index: index, in: posts) } },
                        onUsernameTap: {
                            let authorId = posts[index].wrappedValue.authorId
                            let authorName = posts[index].wrappedValue.authorUsername
                            navigateToProfile = PublicProfile(
                                id: authorId,
                                username: authorName,
                                bio: nil,
                                location: nil
                            )
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Empty states

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(.white.opacity(0.5))
                .scaleEffect(1.2)
            Spacer()
        }
    }

    private var emptyFeedState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.2.fill")
                .font(.system(size: 52))
                .foregroundColor(.white.opacity(0.2))
            Text("Aucun post pour l'instant")
                .font(.custom("Futura-Bold", size: 20))
                .foregroundColor(.white.opacity(0.4))
            Text("Suis des utilisateurs ou publie ta première tenue !")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var emptyDiscoverState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "globe")
                .font(.system(size: 52))
                .foregroundColor(.white.opacity(0.2))
            Text("Aucun post public")
                .font(.custom("Futura-Bold", size: 20))
                .foregroundColor(.white.opacity(0.4))
            Text("Sois le premier à publier une tenue !")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.white.opacity(0.3))
            Spacer()
        }
    }

    // MARK: - Actions

    private func refreshFeed() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        do {
            async let feed = SocialService.shared.fetchFeed(currentUserId: userId)
            async let discover = SocialService.shared.fetchDiscover(currentUserId: userId)
            let (f, d) = try await (feed, discover)
            feedPosts = f
            discoverPosts = d
        } catch { /* Silently ignore */ }
        isLoading = false
    }

    private func toggleLike(index: Int, in posts: Binding<[FeedPost]>) async {
        guard let userId = currentUserId else { return }
        let post = posts[index].wrappedValue
        let wasLiked = post.isLiked

        // Optimistic update
        posts[index].wrappedValue.isLiked = !wasLiked
        posts[index].wrappedValue.likesCount += wasLiked ? -1 : 1

        do {
            if wasLiked {
                try await SocialService.shared.unlikePost(postId: post.id, userId: userId)
            } else {
                try await SocialService.shared.likePost(postId: post.id, userId: userId)
            }
        } catch {
            // Rollback on failure
            posts[index].wrappedValue.isLiked = wasLiked
            posts[index].wrappedValue.likesCount += wasLiked ? 1 : -1
        }
    }
}
