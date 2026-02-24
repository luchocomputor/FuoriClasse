//
//  FuoriclasseApp.swift
//  Fuoriclasse
//
//  Created by Louis Almairac on 02/03/2025.
//

import SwiftUI

@main
struct FuoriclasseApp: App {
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environment(\.managedObjectContext, CoreDataController.shared.context)
        }
    }
}
