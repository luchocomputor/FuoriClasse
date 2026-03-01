//
//  FuoriclasseApp.swift
//  Fuoriclasse
//
//  Created by Louis Almairac on 02/03/2025.
//

import SwiftUI

@main
struct FuoriclasseApp: App {
    @StateObject private var auth = AuthManager()

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environment(\.managedObjectContext, CoreDataController.shared.context)
                .environmentObject(auth)
                .onOpenURL { url in
                    Task {
                        try? await SupabaseService.shared.client.auth.session(from: url)
                    }
                }
        }
    }
}
