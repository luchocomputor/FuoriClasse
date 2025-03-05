//
//  AvatarManager.swift
//  Fuoriclasse
//
//  Created by Louis Almairac on 05/03/2025.
//

import Foundation

class AvatarManager: ObservableObject {
    @Published var avatarURL: URL?
    
    func fetchAvatar() {
        let userID = "user123"
        let urlString = "https://api.readyplayer.me/v1/avatars/\(userID).glb"
        
        guard let url = URL(string: urlString) else {
            print("❌ URL de l'avatar invalide")
            return
        }
        
        print("✅ Avatar téléchargé depuis : \(url)")
        self.avatarURL = url
    }
}

