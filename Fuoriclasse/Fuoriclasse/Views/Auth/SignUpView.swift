import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var auth: AuthManager

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @State private var confirmationMessage: String? = nil

    @FocusState private var focused: Field?
    enum Field { case username, email, password, confirm }

    // MARK: - Validation

    private var passwordTooShort: Bool { !password.isEmpty && password.count < 8 }
    private var passwordMismatch: Bool { !confirmPassword.isEmpty && password != confirmPassword }
    private var canSubmit: Bool {
        !username.isEmpty && !email.isEmpty
            && password.count >= 8 && password == confirmPassword
            && !isLoading
    }

    var body: some View {
        Group {
            if confirmationMessage != nil {
                confirmationScreen
            } else {
                formScreen
            }
        }
        .animation(.easeInOut(duration: 0.35), value: confirmationMessage != nil)
    }

    // MARK: - Écran confirmation

    private var confirmationScreen: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "envelope.badge.checkmark.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 100/255, green: 200/255, blue: 140/255),
                                 Color(red: 60/255, green: 160/255, blue: 100/255)],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            VStack(spacing: 10) {
                Text("Vérifie ta boîte mail")
                    .font(.custom("Futura-Bold", size: 22))
                    .foregroundColor(.white)

                Text("Un lien de confirmation a été envoyé à\n**\(email)**\n\nClique dessus pour activer ton compte.")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Text("Pense à vérifier tes spams si tu ne vois rien.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Formulaire

    private var formScreen: some View {
        ScrollView {
            VStack(spacing: 20) {
                authField(placeholder: "Nom d'utilisateur", text: $username, icon: "person", isSecure: false, field: .username)
                authField(placeholder: "Adresse e-mail", text: $email, icon: "envelope", isSecure: false, field: .email)

                VStack(spacing: 4) {
                    authField(placeholder: "Mot de passe (8 caractères min.)", text: $password, icon: "lock", isSecure: true, field: .password)
                    if passwordTooShort {
                        Text("Le mot de passe doit contenir au moins 8 caractères.")
                            .font(.system(size: 12))
                            .foregroundColor(.orange.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                }

                VStack(spacing: 4) {
                    authField(placeholder: "Confirmer le mot de passe", text: $confirmPassword, icon: "lock.fill", isSecure: true, field: .confirm)
                    if passwordMismatch {
                        Text("Les mots de passe ne correspondent pas.")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                }

                Button(action: signUp) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 130/255, green: 70/255, blue: 210/255),
                                        Color(red: 80/255, green: 30/255, blue: 160/255)
                                    ],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Créer mon compte")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 50)
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.6)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .animation(.spring(response: 0.3), value: passwordTooShort)
            .animation(.spring(response: 0.3), value: passwordMismatch)
        }
        .scrollDismissesKeyboard(.interactively)
        .overlay(alignment: .top) {
            if showError, let msg = errorMessage {
                ErrorToast(message: msg)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Champ de saisie

    @ViewBuilder
    private func authField(
        placeholder: String,
        text: Binding<String>,
        icon: String,
        isSecure: Bool,
        field: Field
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 160/255, green: 100/255, blue: 240/255))
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: text)
                    .focused($focused, equals: field)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .tint(Color(red: 180/255, green: 120/255, blue: 255/255))
            } else {
                TextField(placeholder, text: text)
                    .focused($focused, equals: field)
                    .keyboardType(field == .email ? .emailAddress : .default)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .tint(Color(red: 180/255, green: 120/255, blue: 255/255))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    focused == field
                        ? Color(red: 160/255, green: 100/255, blue: 240/255).opacity(0.6)
                        : Color.white.opacity(0.1),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Action

    private func signUp() {
        focused = nil
        isLoading = true
        Task {
            do {
                let needsConfirmation = try await auth.signUp(
                    email: email,
                    password: password,
                    username: username
                )
                if needsConfirmation {
                    withAnimation {
                        confirmationMessage = "Consultez votre boîte mail pour confirmer votre compte."
                    }
                }
                // Si needsConfirmation == false, la session sera mise à jour
                // automatiquement via authStateChanges → route vers MainTabView
            } catch {
                showToast(error.localizedDescription)
            }
            isLoading = false
        }
    }

    private func showToast(_ message: String) {
        errorMessage = message
        withAnimation(.spring(response: 0.4)) { showError = true }
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            withAnimation(.spring(response: 0.4)) { showError = false }
        }
    }
}
