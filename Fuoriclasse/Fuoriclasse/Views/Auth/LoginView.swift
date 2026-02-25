import SwiftUI
import UIKit

struct LoginView: View {
    @EnvironmentObject var auth: AuthManager

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showError = false

    @FocusState private var focused: Field?
    enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Champ email
                authField(
                    placeholder: "Adresse e-mail",
                    text: $email,
                    icon: "envelope",
                    isSecure: false,
                    field: .email
                )

                // Champ mot de passe
                authField(
                    placeholder: "Mot de passe",
                    text: $password,
                    icon: "lock",
                    isSecure: true,
                    field: .password
                )

                // Bouton connexion
                Button(action: signIn) {
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
                            Text("Se connecter")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 50)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1)

                // Séparateur
                HStack {
                    Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
                    Text("ou")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.horizontal, 12)
                    Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
                }
                .padding(.vertical, 4)

                // Bouton Google
                Button(action: signInWithGoogle) {
                    HStack(spacing: 10) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 66/255, green: 133/255, blue: 244/255))
                        Text("Continuer avec Google")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 30/255, green: 30/255, blue: 30/255))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 40)
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
                    .keyboardType(.emailAddress)
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

    // MARK: - Actions

    private func signIn() {
        focused = nil
        isLoading = true
        Task {
            do {
                try await auth.signIn(email: email, password: password)
            } catch {
                showToast(error.localizedDescription)
            }
            isLoading = false
        }
    }

    private func signInWithGoogle() {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = scene.keyWindow?.rootViewController
        else { return }
        isLoading = true
        Task {
            do {
                try await auth.signInWithGoogle(presenting: rootVC)
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
