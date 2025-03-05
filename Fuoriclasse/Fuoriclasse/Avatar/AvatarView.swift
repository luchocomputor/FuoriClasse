//
//  AvatarView.swift
//  Fuoriclasse
//
//  Created by Louis Almairac on 05/03/2025.
//
import SwiftUI

struct AvatarView: View {
    @StateObject var avatarManager = AvatarManager()
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack {
            Avatar3DView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Button("Changer d'Avatar") {
                avatarManager.fetchAvatar()
            }
            .padding()
        }
        .onAppear {
            avatarManager.fetchAvatar()
        }
        .navigationTitle("Mon Avatar")
    }
}
