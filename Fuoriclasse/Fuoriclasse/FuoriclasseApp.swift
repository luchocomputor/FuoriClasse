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
    var body: some Scene {
        WindowGroup {
            MainViewRepresentable()
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct MainViewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return MainTabBarController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
