import SwiftUI
import CoreData

struct ProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DressingItem.title, ascending: true)],
        animation: .default
    ) private var dressingItems: FetchedResults<DressingItem>

    @FetchRequest(
        sortDescriptors: [],
        animation: .default
    ) private var outfits: FetchedResults<Outfit>

    @StateObject private var avatarManager = AvatarManager()

    @State private var username         = ""
    @State private var location         = ""
    @State private var bio              = ""

    @State private var profileImageData: Data? = UserDefaults.standard.data(forKey: "profile_photo")
    @State private var showPhotoPicker      = false
    @State private var showEditSheet        = false
    @State private var showSettings         = false

    // Avatar création
    @State private var showAvatarCreator    = false
    @State private var isDownloadingAvatar  = false
    @State private var avatarDownloadError: String?
    @State private var capturedGLBURL: URL?
    @State private var avaturnCoordinator: AvaturnCreatorView.Coordinator?
    @State private var showDeleteAvatarAlert = false

    private var itemCount: Int { dressingItems.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroSection
                statsBar
                wardrobePreview
                avatarSection
                Spacer().frame(height: 20)
            }
            .padding(.top, 16)
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
        .onAppear { avatarManager.loadLocalAvatar() }
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .topTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.60))
                    .padding(16)
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
        .sheet(isPresented: $showEditSheet, onDismiss: { Task { await reloadProfile() } }) {
            ProfileEditSheet(auth: auth, username: $username, location: $location, bio: $bio)
        }
        .sheet(isPresented: $showAvatarCreator, onDismiss: { capturedGLBURL = nil }) {
            avatarCreatorSheet
        }
        .alert("Supprimer l'avatar ?", isPresented: $showDeleteAvatarAlert) {
            Button("Supprimer", role: .destructive) { avatarManager.deleteAvatar() }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("L'avatar sera définitivement supprimé.")
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

    // MARK: - Hero (centré)

    private var heroSection: some View {
        VStack(spacing: 14) {
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
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .frame(width: 88, height: 88)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(
                        LinearGradient(
                            colors: [Color(red: 180/255, green: 120/255, blue: 255/255),
                                     Color(red: 80/255, green: 30/255, blue: 160/255)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                )
                .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 4)

                Button { showPhotoPicker = true } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 140/255, green: 80/255, blue: 220/255))
                            .frame(width: 28, height: 28)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 2, y: 2)
            }

            // Pseudo + localisation + bio
            VStack(spacing: 6) {
                Text(username.isEmpty ? "Ajouter un pseudo" : username)
                    .font(.custom("Futura-Bold", size: 22))
                    .foregroundColor(username.isEmpty ? .white.opacity(0.3) : .white)

                if !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11))
                        Text(location)
                            .font(.system(size: 13, weight: .light))
                    }
                    .foregroundColor(.white.opacity(0.45))
                }

                if !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 24)
                }
            }

            // Bouton modifier
            Button { showEditSheet = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                    Text("Modifier le profil")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(Color(red: 140/255, green: 80/255, blue: 220/255).opacity(0.75))
                )
                .overlay(
                    Capsule()
                        .stroke(Color(red: 180/255, green: 120/255, blue: 255/255).opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
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
            StatTile(value: "\(outfits.count)", label: "styles adoptés")
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
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(LinearGradient(
                        colors: [
                            Color(red: 180/255, green: 120/255, blue: 255/255).opacity(0.85),
                            Color(red: 140/255, green: 80/255, blue: 220/255).opacity(0.35)
                        ],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 2, height: 14)
                Text("Mon dressing")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.65))
                    .tracking(0.3)
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

    // MARK: - Avatar 3D

    private var avatarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(LinearGradient(
                        colors: [
                            Color(red: 180/255, green: 120/255, blue: 255/255).opacity(0.85),
                            Color(red: 140/255, green: 80/255, blue: 220/255).opacity(0.35)
                        ],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 2, height: 14)
                Text("Mon Avatar")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.65))
                    .tracking(0.3)
                Spacer()
                if avatarManager.hasAvatar {
                    Button { showDeleteAvatarAlert = true } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 4)
                    Button { showAvatarCreator = true } label: {
                        Label("Recréer", systemImage: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)

            if isDownloadingAvatar {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(Color(red: 160/255, green: 100/255, blue: 240/255))
                    Text("Téléchargement…")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if avatarManager.hasAvatar {
                ZStack(alignment: .bottom) {
                    Avatar3DView(avatarManager: avatarManager)
                        .frame(maxWidth: .infinity)
                        .frame(height: 320)
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
            } else {
                // Empty state
                GlassCard {
                    VStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 36))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 160/255, green: 100/255, blue: 240/255),
                                             Color(red: 100/255, green: 60/255, blue: 180/255)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                        Text("Génère ton avatar 3D")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        if let err = avatarDownloadError {
                            Text(err)
                                .font(.system(size: 12))
                                .foregroundColor(.red.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        Button { showAvatarCreator = true } label: {
                            Label("Créer mon avatar", systemImage: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 11)
                                .background(
                                    Capsule().fill(
                                        LinearGradient(
                                            colors: [Color(red: 140/255, green: 80/255, blue: 220/255),
                                                     Color(red: 100/255, green: 50/255, blue: 180/255)],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Avatar creator sheet

    private var avatarCreatorSheet: some View {
        NavigationStack {
            AvaturnCreatorView(
                embedURL: AvaturnService.shared.embedURL,
                capturedGLBURL: $capturedGLBURL,
                coordinator: $avaturnCoordinator
            ) { remoteURL in
                showAvatarCreator = false
                handleAvatarExport(url: remoteURL)
            }
            .ignoresSafeArea()
            // Hint : l'import se déclenche en cliquant le bouton dans Avaturn
            .overlay(alignment: .top) {
                Text("Clique sur le bouton d'export dans l'éditeur — l'import se fait automatiquement")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.black.opacity(0.55)))
                    .padding(.top, 10)
                    .allowsHitTesting(false)
            }
            .navigationTitle("Créer mon avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        capturedGLBURL = nil
                        showAvatarCreator = false
                    }
                    .foregroundColor(.white.opacity(0.65))
                }
            }
        }
    }

    // MARK: - Export handler

    private func handleAvatarExport(url: URL) {
        isDownloadingAvatar = true
        avatarDownloadError = nil
        Task {
            do {
                let local = try await AvaturnService.shared.downloadAvatar(from: url)
                await MainActor.run {
                    avatarManager.avatarURL = local
                    isDownloadingAvatar = false
                }
            } catch {
                await MainActor.run {
                    avatarDownloadError = error.localizedDescription
                    isDownloadingAvatar = false
                }
            }
        }
    }
}

// MARK: - ProfileEditSheet

struct ProfileEditSheet: View {
    let auth: AuthManager
    @Binding var username: String
    @Binding var location: String
    @Binding var bio: String
    @Environment(\.dismiss) private var dismiss

    @State private var usernameBuffer = ""
    @State private var locationBuffer = ""
    @State private var bioBuffer = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    editSectionHeader("IDENTITÉ")
                    GlassInputCard {
                        AddFieldRow(icon: "at", placeholder: "Pseudo", text: $usernameBuffer)
                        editDivider
                        AddFieldRow(icon: "mappin.circle.fill", placeholder: "Ville", text: $locationBuffer)
                    }
                    editSectionHeader("BIO")
                    GlassInputCard {
                        AddMultilineRow(icon: "text.quote", placeholder: "Parle de toi...", text: $bioBuffer)
                    }
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
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
            .navigationTitle("Modifier le profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundColor(.white.opacity(0.6))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { save() }
                        .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            usernameBuffer = username
            locationBuffer = location
            bioBuffer = bio
        }
    }

    private func editSectionHeader(_ text: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 1)
                .fill(LinearGradient(
                    colors: [
                        Color(red: 180/255, green: 120/255, blue: 255/255).opacity(0.75),
                        Color(red: 140/255, green: 80/255, blue: 220/255).opacity(0.25)
                    ],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: 2, height: 11)
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.50))
                .tracking(1.2)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    private var editDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 1)
            .padding(.leading, 52)
    }

    private func save() {
        username = usernameBuffer
        location = locationBuffer
        bio = bioBuffer
        let u = usernameBuffer, l = locationBuffer, b = bioBuffer
        dismiss()
        Task { try? await auth.updateProfile(username: u, location: l, bio: b) }
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
