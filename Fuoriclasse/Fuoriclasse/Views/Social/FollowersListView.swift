import SwiftUI

struct FollowersListView: View {
    @EnvironmentObject var auth: AuthManager

    let userId: UUID
    let mode: FollowMode

    enum FollowMode {
        case followers, following
        var title: String { self == .followers ? "Abonnés" : "Abonnements" }
    }

    @State private var profiles: [PublicProfile] = []
    @State private var isLoading = true
    @State private var followingSet: Set<UUID> = []
    @State private var loadingIds: Set<UUID> = []
    @State private var navigateTo: PublicProfile? = nil

    private var currentUserId: UUID? { auth.session?.user.id }

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

            if isLoading {
                ProgressView()
                    .tint(.white.opacity(0.5))
                    .scaleEffect(1.2)
            } else if profiles.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(profiles) { profile in
                            Button { navigateTo = profile } label: {
                                userRow(profile: profile)
                            }
                            .buttonStyle(.plain)
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 1)
                                .padding(.leading, 76)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $navigateTo) { profile in
            UserPublicProfileView(profile: profile)
                .environmentObject(auth)
        }
        .task { await loadData() }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: mode == .followers ? "person.2" : "person.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.15))
            Text(mode == .followers ? "Aucun abonné" : "Aucun abonnement")
                .font(.custom("Futura-Bold", size: 18))
                .foregroundColor(.white.opacity(0.35))
        }
    }

    // MARK: - User row

    @ViewBuilder
    private func userRow(profile: PublicProfile) -> some View {
        HStack(spacing: 14) {
            avatarCircle(for: profile.username, size: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.username)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }

            Spacer()

            if let currentId = currentUserId, profile.id != currentId {
                followButton(for: profile)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func followButton(for profile: PublicProfile) -> some View {
        let isFollowing = followingSet.contains(profile.id)
        let isLoading = loadingIds.contains(profile.id)

        Button {
            Task { await toggleFollow(profile: profile) }
        } label: {
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.75)
                    .frame(width: 84, height: 32)
            } else {
                Text(isFollowing ? "Suivi" : "Suivre")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isFollowing ? .white.opacity(0.8) : .white)
                    .frame(width: 84, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isFollowing
                                  ? Color.white.opacity(0.1)
                                  : Color(red: 120/255, green: 60/255, blue: 200/255))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(isFollowing ? 0.2 : 0), lineWidth: 1)
                            )
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    // MARK: - Helpers

    private func avatarCircle(for username: String, size: CGFloat) -> some View {
        let parts = username.split(separator: " ")
        let initials = parts.count >= 2
            ? String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
            : String(username.prefix(2)).uppercased()
        return Circle()
            .fill(LinearGradient(
                colors: [Color(red: 120/255, green: 60/255, blue: 200/255),
                         Color(red: 80/255, green: 30/255, blue: 140/255)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundColor(.white)
            )
    }

    // MARK: - Data

    private func loadData() async {
        guard let currentId = currentUserId else { return }
        isLoading = true
        do {
            async let profilesTask: [PublicProfile] = mode == .followers
                ? SocialService.shared.fetchFollowers(userId: userId)
                : SocialService.shared.fetchFollowing(userId: userId)
            async let followingTask: [PublicProfile] = SocialService.shared.fetchFollowing(userId: currentId)
            let (fetched, currentFollowing) = try await (profilesTask, followingTask)
            profiles = fetched
            followingSet = Set(currentFollowing.map { $0.id })
        } catch {}
        isLoading = false
    }

    private func toggleFollow(profile: PublicProfile) async {
        guard let currentId = currentUserId else { return }
        loadingIds.insert(profile.id)
        defer { loadingIds.remove(profile.id) }
        do {
            if followingSet.contains(profile.id) {
                try await SocialService.shared.unfollow(followerId: currentId, targetId: profile.id)
                followingSet.remove(profile.id)
            } else {
                try await SocialService.shared.follow(followerId: currentId, targetId: profile.id)
                followingSet.insert(profile.id)
            }
        } catch {}
    }
}
