import SwiftUI

struct UserSearchView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [PublicProfile] = []
    @State private var isSearching = false
    @State private var navigateTo: PublicProfile? = nil
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 40/255, green: 10/255, blue: 90/255),
                        Color(red: 15/255, green: 5/255, blue: 40/255)
                    ]),
                    center: .center, startRadius: 100, endRadius: 500
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    Divider()
                        .background(Color.white.opacity(0.08))

                    resultContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Rechercher")
                        .font(.custom("Futura-Bold", size: 17))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
                }
            }
            .navigationDestination(item: $navigateTo) { profile in
                UserPublicProfileView(profile: profile)
                    .environmentObject(auth)
            }
        }
        .onAppear { searchFocused = true }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.4))
                .font(.system(size: 15))
            TextField("", text: $searchText, prompt:
                Text("Rechercher un utilisateur...")
                    .foregroundColor(.white.opacity(0.3))
            )
            .foregroundColor(.white)
            .font(.system(size: 15))
            .autocorrectionDisabled()
            .focused($searchFocused)
            .onChange(of: searchText) { _, newValue in
                Task { await performSearch(query: newValue) }
            }
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Result content

    @ViewBuilder
    private var resultContent: some View {
        if searchText.isEmpty {
            emptyPrompt
        } else if isSearching {
            Spacer()
            ProgressView().tint(.white.opacity(0.5)).scaleEffect(1.1)
            Spacer()
        } else if searchResults.isEmpty {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "person.slash")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(0.18))
                Text("Aucun utilisateur trouvé")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(searchResults) { profile in
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
                .padding(.bottom, 40)
            }
        }
    }

    private var emptyPrompt: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "person.2.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 160/255, green: 100/255, blue: 240/255).opacity(0.6),
                                 Color(red: 100/255, green: 60/255, blue: 180/255).opacity(0.3)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            Text("Trouve des personnes à suivre")
                .font(.custom("Futura-Bold", size: 19))
                .foregroundColor(.white.opacity(0.45))
            Text("Recherche par pseudo pour découvrir\nde nouveaux styles")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - User row

    @ViewBuilder
    private func userRow(profile: PublicProfile) -> some View {
        HStack(spacing: 14) {
            avatarCircle(username: profile.username, size: 48)

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

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.25))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func avatarCircle(username: String, size: CGFloat) -> some View {
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

    // MARK: - Search logic

    private func performSearch(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        do {
            searchResults = try await SocialService.shared.searchUsers(query: query)
        } catch { searchResults = [] }
        isSearching = false
    }
}
