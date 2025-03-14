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
                    avatarManager.fetchAvatar(fileName: "lucho3") // 🎯 Charge avatar1.usdz
                }
                
                Button("Avatar 2") {
                    avatarManager.fetchAvatar(fileName: "lucho3") // 🎯 Charge avatar2.glb
                }
            }
            .navigationTitle("Choisir Avatar")
        }
}
