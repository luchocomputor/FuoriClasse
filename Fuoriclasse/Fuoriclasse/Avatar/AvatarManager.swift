//
//  AvatarManager.swift
//  Fuoriclasse
//
//  Created by Louis Almairac on 05/03/2025.
//

import Foundation

class AvatarManager: ObservableObject {
    @Published var avatarURL: URL?

    func fetchAvatar(fileName: String) {
        let possibleExtensions = ["usdz", "glb"]  // ✅ Liste des formats acceptés
        
        for ext in possibleExtensions {
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                DispatchQueue.main.async {
                    self.avatarURL = url
                    print("✅ Avatar local chargé : \(url)")
                }
                return  // ✅ Arrête dès qu'on trouve un fichier existant
            }
        }

        print("❌ Aucun fichier \(fileName).usdz ou \(fileName).glb trouvé dans le bundle")
    }
}


