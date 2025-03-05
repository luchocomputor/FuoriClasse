//
//  FuoriclasseApp.swift
//  Fuoriclasse
//
//  Created by Louis Almairac on 02/03/2025.
//

// FuoriclasseApp.swift
import SwiftUI

@main
struct FuoriclasseApp: App {
    let coreDataController = CoreDataController.shared
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, coreDataController.context)
        }
    }
}
