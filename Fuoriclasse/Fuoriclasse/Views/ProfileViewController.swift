import SwiftUI
import PhotosUI

struct ProfileView: View {
    // Persistance légère via AppStorage
    @AppStorage("profile_username")    private var username    = ""
    @AppStorage("profile_email")       private var email       = ""
    @AppStorage("profile_location")    private var location    = ""
    @AppStorage("profile_bio")         private var bio         = ""

    // Photo de profil stockée dans UserDefaults
    @State private var profileImageData: Data? = UserDefaults.standard.data(forKey: "profile_photo")
    @State private var showPhotoPicker   = false

    // Édition inline
    @State private var editingField: EditableField? = nil
    @State private var editBuffer      = ""
    @FocusState private var fieldFocused: Bool

    enum EditableField: Identifiable {
        case username, email, location, bio
        var id: Self { self }
        var label: String {
            switch self {
            case .username: return "Nom d'utilisateur"
            case .email:    return "E-mail"
            case .location: return "Ville"
            case .bio:      return "Bio"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    infoCard
                    avatarCard
                    settingsCard
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
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
        .sheet(item: $editingField) { field in
            editSheet(for: field)
        }
    }

    // MARK: - Hero

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
                                .font(.system(size: 52))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 180/255, green: 120/255, blue: 255/255),
                                         Color(red: 80/255, green: 30/255, blue: 160/255)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                )
                .shadow(color: .purple.opacity(0.4), radius: 12, x: 0, y: 4)

                // Bouton éditer photo
                Button { showPhotoPicker = true } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 140/255, green: 80/255, blue: 220/255))
                            .frame(width: 28, height: 28)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 2, y: 2)
            }

            // Nom + localisation
            VStack(spacing: 4) {
                Button { startEditing(.username) } label: {
                    HStack(spacing: 6) {
                        Text(username.isEmpty ? "Nom d'utilisateur" : username)
                            .font(.custom("Futura-Bold", size: 22))
                            .foregroundColor(username.isEmpty ? .white.opacity(0.3) : .white)
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }

                if !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 11))
                        Text(location)
                            .font(.system(size: 13, weight: .light))
                    }
                    .foregroundColor(.white.opacity(0.5))
                }

                if !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Carte infos

    private var infoCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                ProfileRow(
                    icon: "envelope.fill",
                    label: "E-mail",
                    value: email.isEmpty ? "Ajouter" : email,
                    isEmpty: email.isEmpty
                ) { startEditing(.email) }

                divider

                ProfileRow(
                    icon: "mappin.circle.fill",
                    label: "Ville",
                    value: location.isEmpty ? "Ajouter" : location,
                    isEmpty: location.isEmpty
                ) { startEditing(.location) }

                divider

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

    // MARK: - Carte avatar

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

    // MARK: - Carte settings

    private var settingsCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                SettingsToggleRow(icon: "bell.fill",  label: "Notifications",  color: Color(red: 255/255, green: 100/255, blue: 80/255),  key: "setting_notifs")
                divider
                SettingsToggleRow(icon: "lock.fill",  label: "Profil privé",   color: Color(red: 80/255, green: 160/255, blue: 255/255),  key: "setting_private")
                divider
                SettingsToggleRow(icon: "sparkles",   label: "Suggestions IA", color: Color(red: 160/255, green: 100/255, blue: 240/255), key: "setting_ai")
            }
        }
        .padding(.horizontal, 20)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 1)
            .padding(.leading, 56)
    }

    // MARK: - Édition

    private func startEditing(_ field: EditableField) {
        editBuffer = {
            switch field {
            case .username: return username
            case .email:    return email
            case .location: return location
            case .bio:      return bio
            }
        }()
        editingField = field
    }

    private func commitEdit(for field: EditableField) {
        switch field {
        case .username: username = editBuffer
        case .email:    email    = editBuffer
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

// MARK: - Composants réutilisables

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
