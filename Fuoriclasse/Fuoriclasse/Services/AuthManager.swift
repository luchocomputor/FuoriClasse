import Foundation
import Supabase
import GoogleSignIn
import UIKit

struct UserProfile: Codable {
    var username: String?
    var location: String?
    var bio: String?
}

@MainActor
final class AuthManager: ObservableObject {
    @Published var session: Session?
    @Published var isLoading = true

    private var listenerTask: Task<Void, Never>?

    enum AuthError: LocalizedError {
        case missingIdToken
        case noRootViewController
        case googleNotConfigured

        var errorDescription: String? {
            switch self {
            case .missingIdToken:       return "Token Google manquant."
            case .noRootViewController: return "Impossible d'afficher la connexion Google."
            case .googleNotConfigured:  return "Google Sign-In non configuré. Ajoutez GIDClientID dans Info.plist."
            }
        }
    }

    // MARK: - Initialisation (appelée au lancement depuis SplashView)

    func initialize() {
        guard listenerTask == nil else { return }
        listenerTask = Task {
            for await (_, session) in SupabaseService.shared.client.auth.authStateChanges {
                self.session = session
                if self.isLoading {
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Email / Password

    func signIn(email: String, password: String) async throws {
        try await SupabaseService.shared.client.auth.signIn(email: email, password: password)
    }

    /// Retourne `true` si une confirmation par email est requise (session == nil après inscription).
    @discardableResult
    func signUp(email: String, password: String, username: String) async throws -> Bool {
        let response = try await SupabaseService.shared.client.auth.signUp(
            email: email,
            password: password
        )
        let user = response.user
        struct ProfileInsert: Encodable {
            let id: UUID
            let username: String
        }
        try? await SupabaseService.shared.client
            .from("profiles")
            .insert(ProfileInsert(id: user.id, username: username))
            .execute()
        return response.session == nil
    }

    // MARK: - Google Sign-In

    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        guard
            let iosClientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String
        else { throw AuthError.googleNotConfigured }

        let webClientID = Bundle.main.object(forInfoDictionaryKey: "GIDServerClientID") as? String
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: iosClientID,
            serverClientID: webClientID
        )

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingIdToken
        }
        let accessToken = result.user.accessToken.tokenString
        try await SupabaseService.shared.client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
    }


    // MARK: - Sign Out

    func signOut() async throws {
        try await SupabaseService.shared.client.auth.signOut()
    }

    // MARK: - Profile

    func loadProfile() async throws -> UserProfile {
        guard let userId = session?.user.id else { return UserProfile() }
        do {
            let profile: UserProfile = try await SupabaseService.shared.client
                .from("profiles")
                .select("username, location, bio")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            return profile
        } catch {
            // Aucun profil trouvé (ex : premier login Google) → profil vide
            return UserProfile()
        }
    }

    func updateProfile(username: String, location: String, bio: String) async throws {
        guard let userId = session?.user.id else { return }
        struct ProfileUpsert: Encodable {
            let id: UUID
            let username: String
            let location: String
            let bio: String
        }
        try await SupabaseService.shared.client
            .from("profiles")
            .upsert(ProfileUpsert(id: userId, username: username, location: location, bio: bio))
            .execute()
    }
}
