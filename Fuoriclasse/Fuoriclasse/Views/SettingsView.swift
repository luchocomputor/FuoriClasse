import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) private var dismiss

    // Champs profil (location + bio éditables, username chargé mais non affiché)
    @State private var currentUsername  = ""
    @State private var location         = ""
    @State private var bio              = ""
    @State private var initialLocation  = ""
    @State private var initialBio       = ""

    @State private var editingField: EditableField? = nil
    @State private var editBuffer       = ""
    @FocusState private var fieldFocused: Bool

    @State private var showLogoutAlert  = false

    private var email: String { auth.session?.user.email ?? "" }

    enum EditableField: Identifiable {
        case location, bio
        var id: Self { self }
        var label: String {
            switch self {
            case .location: return "Ville"
            case .bio:      return "Bio"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    avatarCard
                    infoCard
                    settingsCard
                    logoutCard
                    Spacer().frame(height: 20)
                }
                .padding(.top, 20)
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
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") { dismiss() }
                        .foregroundColor(.white.opacity(0.65))
                }
            }
        }
        .sheet(item: $editingField) { field in
            editSheet(for: field)
        }
        .alert("Se déconnecter ?", isPresented: $showLogoutAlert) {
            Button("Déconnecter", role: .destructive) {
                Task { try? await auth.signOut() }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Vous devrez vous reconnecter pour accéder à l'application.")
        }
        .task {
            guard let profile = try? await auth.loadProfile() else { return }
            currentUsername = profile.username ?? ""
            location        = profile.location ?? ""
            bio             = profile.bio      ?? ""
            initialLocation = location
            initialBio      = bio
        }
        .onDisappear {
            let hasChanges = location != initialLocation || bio != initialBio
            guard hasChanges else { return }
            let username = currentUsername
            let loc = location
            let b = bio
            Task { try? await auth.updateProfile(username: username, location: loc, bio: b) }
        }
    }

    // MARK: - Carte Avatar

    private var avatarCard: some View {
        GlassCard {
            NavigationLink(destination: AvatarView()) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(red: 130/255, green: 70/255, blue: 210/255),
                                         Color(red: 60/255, green: 20/255, blue: 120/255)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 36, height: 36)
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mon Avatar")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        Text("Personnaliser votre avatar 3D")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Carte infos

    private var infoCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color(red: 160/255, green: 100/255, blue: 240/255))
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("E-mail")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(0.5)
                        Text(email.isEmpty ? "—" : email)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.2))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                settingsDivider

                ProfileRow(
                    icon: "mappin.circle.fill",
                    label: "Ville",
                    value: location.isEmpty ? "Ajouter" : location,
                    isEmpty: location.isEmpty
                ) { startEditing(.location) }

                settingsDivider

                ProfileRow(
                    icon: "text.quote",
                    label: "Bio",
                    value: bio.isEmpty ? "Ajouter" : bio,
                    isEmpty: bio.isEmpty
                ) { startEditing(.bio) }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Carte paramètres

    private var settingsCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                SettingsToggleRow(icon: "bell.fill",  label: "Notifications",  color: Color(red: 255/255, green: 100/255, blue: 80/255),  key: "setting_notifs")
                settingsDivider
                SettingsToggleRow(icon: "lock.fill",  label: "Profil privé",   color: Color(red: 80/255, green: 160/255, blue: 255/255),  key: "setting_private")
                settingsDivider
                SettingsToggleRow(icon: "sparkles",   label: "Suggestions IA", color: Color(red: 160/255, green: 100/255, blue: 240/255), key: "setting_ai")
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Carte déconnexion

    private var logoutCard: some View {
        GlassCard {
            Button { showLogoutAlert = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15))
                    Text("Se déconnecter")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.red.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
        }
        .padding(.horizontal, 20)
    }

    private var settingsDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 1)
            .padding(.leading, 56)
    }

    // MARK: - Édition

    private func startEditing(_ field: EditableField) {
        editBuffer = field == .location ? location : bio
        editingField = field
    }

    private func commitEdit(for field: EditableField) {
        switch field {
        case .location: location = editBuffer
        case .bio:      bio      = editBuffer
        }
        editingField = nil
    }

    @ViewBuilder
    private func editSheet(for field: EditableField) -> some View {
        NavigationStack {
            ZStack {
                Color(red: 15/255, green: 5/255, blue: 35/255).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 12) {
                    Text(field.label)
                        .font(.custom("Futura-Bold", size: 18))
                        .foregroundColor(.white)
                        .padding(.top, 8)

                    TextField(field.label, text: $editBuffer, axis: field == .bio ? .vertical : .horizontal)
                        .lineLimit(field == .bio ? 4 : 1)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .tint(Color(red: 180/255, green: 120/255, blue: 255/255))
                        .focused($fieldFocused)
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
                    Button("Annuler") { editingField = nil }
                        .foregroundColor(.white.opacity(0.6))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { commitEdit(for: field) }
                        .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(240)])
        .presentationBackground(Color(red: 15/255, green: 5/255, blue: 35/255))
        .onAppear { fieldFocused = true }
    }
}
