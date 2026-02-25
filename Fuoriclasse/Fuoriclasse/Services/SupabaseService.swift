import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        guard
            let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path),
            let urlString = dict["SUPABASE_URL"] as? String,
            let anonKey = dict["SUPABASE_ANON_KEY"] as? String,
            !urlString.isEmpty, urlString != "YOUR_SUPABASE_URL",
            !anonKey.isEmpty, anonKey != "YOUR_SUPABASE_ANON_KEY",
            let url = URL(string: urlString)
        else {
            fatalError("Secrets.plist manquant ou clés SUPABASE_URL / SUPABASE_ANON_KEY non renseignées.")
        }
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }
}
