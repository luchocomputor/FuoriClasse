import SwiftUI
import CoreData

struct ProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DressingItem.title, ascending: true)],
        animation: .default
    ) private var dressingItems: FetchedResults<DressingItem>

    @StateObject private var avatarManager = AvatarManager()

    @State private var username         = ""
    @State private var location         = ""
    @State private var bio              = ""

    @State private var profileImageData: Data? = UserDefaults.standard.data(forKey: "profile_photo")
    @State private var showPhotoPicker  = false

    @State private var editingUsername  = false
    @State private var usernameBuffer   = ""
    @FocusState private var usernameFocused: Bool

    @State private var showSettings     = false

    private var itemCount: Int { dressingItems.count }

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    avatarSection
                    wardrobePreview
                    statsBar
                    Spacer().frame(height: 20)
                }
                .padding(.top, 16)
            }
        }
        .onAppear { avatarManager.fetchAvatar(fileName: "lucho3") }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.75))
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(photoData: Binding(
                get: { profileImageData },
                set: { data in
                    profileImageData = data
                    if let data { UserDefaults.standard.set(data, forKey: "profile_photo") }
                }
            ))
        }
        .sheet(isPresented: $showSettings, onDismiss: { Task { await reloadProfile() } }) {
            SettingsView()
                .environmentObject(auth)
        }
        .sheet(isPresented: $editingUsername) {
            usernameEditSheet
        }
        .task { await reloadProfile() }
    }

    // MARK: - Chargement profil

    @MainActor
    private func reloadProfile() async {
        guard let profile = try? await auth.loadProfile() else { return }
        username = profile.username ?? ""
        location = profile.location ?? ""
        bio      = profile.bio      ?? ""
    }

    // MARK: - Fond

    private var background: some View {
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

    // MARK: - Hero (compact)

    private var heroSection: some View {
        HStack(spacing: 16) {
            // Photo de profil
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let data = profileImageData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [Color(red: 100/255, green: 50/255, blue: 180/255),
                                         Color(red: 50/255, green: 15/255, blue: 100/255)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                            Image(systemName: "person.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(
                        LinearGradient(
                            colors: [Color(red: 180/255, green: 120/255, blue: 255/255),
                                     Color(red: 80/255, green: 30/255, blue: 160/255)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                )
                .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 3)

                Button { showPhotoPicker = true } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 140/255, green: 80/255, blue: 220/255))
                            .frame(width: 22, height: 22)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 1, y: 1)
            }

            // Pseudo + localisation
            VStack(alignment: .leading, spacing: 4) {
                Button { usernameBuffer = username; editingUsername = true } label: {
                    HStack(spacing: 5) {
                        Text(username.isEmpty ? "Ajouter un pseudo" : username)
                            .font(.custom("Futura-Bold", size: 20))
                            .foregroundColor(username.isEmpty ? .white.opacity(0.3) : .white)
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }

                if !location.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin")
                            .font(.system(size: 10))
                        Text(location)
                            .font(.system(size: 12, weight: .light))
                    }
                    .foregroundColor(.white.opacity(0.45))
                }

                if !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Avatar 3D

    private var avatarSection: some View {
        ZStack(alignment: .bottom) {
            Avatar3DView(avatarManager: avatarManager)
                .frame(maxWidth: .infinity)
                .frame(height: 300)

            // Hint de rotation
            Text("Glisser pour tourner")
                .font(.system(size: 11, weight: .light))
                .foregroundColor(.white.opacity(0.3))
                .padding(.bottom, 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Stats bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            Spacer()
            StatTile(value: "\(itemCount)", label: "pièces")
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 32)
            StatTile(value: "0", label: "styles adoptés")
            Spacer()
        }
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Aperçu dressing

    private var wardrobePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mon dressing")
                    .font(.custom("Futura-Bold", size: 16))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)

            if dressingItems.isEmpty {
                GlassCard {
                    VStack(spacing: 10) {
                        Image(systemName: "hanger")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.18))
                        Text("Ton dressing est vide")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.white.opacity(0.32))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                }
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(dressingItems.prefix(8)), id: \.id) { item in
                            NavigationLink(destination: DressingItemDetailView(item: item)) {
                                WardrobePreviewCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Sheet édition pseudo

    @ViewBuilder
    private var usernameEditSheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 15/255, green: 5/255, blue: 35/255).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nom d'utilisateur")
                        .font(.custom("Futura-Bold", size: 18))
                        .foregroundColor(.white)
                        .padding(.top, 8)

                    TextField("Nom d'utilisateur", text: $usernameBuffer)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .tint(Color(red: 180/255, green: 120/255, blue: 255/255))
                        .focused($usernameFocused)
                        .padding(14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { editingUsername = false }
                        .foregroundColor(.white.opacity(0.6))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        let newUsername = usernameBuffer
                        username = newUsername
                        editingUsername = false
                        Task { try? await auth.updateProfile(username: newUsername, location: location, bio: bio) }
                    }
                    .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(220)])
        .presentationBackground(Color(red: 15/255, green: 5/255, blue: 35/255))
        .onAppear { usernameFocused = true }
    }
}

// MARK: - StatTile

struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.custom("Futura-Bold", size: 24))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - WardrobePreviewCard

struct WardrobePreviewCard: View {
    let item: DressingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let data = item.image, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [Color(red: 70/255, green: 30/255, blue: 140/255),
                                 Color(red: 40/255, green: 10/255, blue: 80/255)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    Image(systemName: "hanger")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.22))
                }
            }
            .frame(width: 110, height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(item.category)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(red: 140/255, green: 80/255, blue: 220/255).opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .frame(width: 110)
    }
}

// MARK: - GlassCard

struct GlassCard<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

    var body: some View {
        content()
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - ProfileRow

struct ProfileRow: View {
    let icon: String
    let label: String
    let value: String
    let isEmpty: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 160/255, green: 100/255, blue: 240/255))
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(0.5)
                    Text(value)
                        .font(.system(size: 15))
                        .foregroundColor(isEmpty ? .white.opacity(0.25) : .white)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - SettingsToggleRow

struct SettingsToggleRow: View {
    let icon: String
    let label: String
    let color: Color
    let key: String
    @AppStorage var isOn: Bool

    init(icon: String, label: String, color: Color, key: String) {
        self.icon  = icon
        self.label = label
        self.color = color
        self.key   = key
        self._isOn = AppStorage(wrappedValue: false, key)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.85))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Color(red: 140/255, green: 80/255, blue: 220/255))
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
