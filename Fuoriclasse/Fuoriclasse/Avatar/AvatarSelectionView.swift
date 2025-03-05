//
//  AvatarSelectionView.swift
//  Fuoriclasse
//
//  Created by Louis Almairac on 05/03/2025.
//
import SwiftUI

struct AvatarSelectionView: View {
    @StateObject var avatarManager = AvatarManager()
    
    var body: some View {
        VStack {
            Text("Sélectionne ton Avatar")
                .font(.title)
                .padding()
            
            Button("Avatar 1") {
                avatarManager.avatarURL = URL(string: "https://api.readyplayer.me/v1/avatars/user1.glb")
            }
            
            Button("Avatar 2") {
                avatarManager.avatarURL = URL(string: "https://api.readyplayer.me/v1/avatars/user2.glb")
            }
        }
        .navigationTitle("Choisir Avatar")
    }
}
