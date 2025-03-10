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
        ZStack {
            // 🔹 1. Fond Radial (violet) identique à HomeView
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 40/255, green: 10/255, blue: 90/255),
                    Color(red: 15/255, green: 5/255, blue: 40/255)
                ]),
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()

            // 🔹 2. Effets fluides (blobs, particules)
            FluidBackgroundView()

            // 🔹 3. Avatar directement intégré sans cadre blanc
            Avatar3DView()
                .frame(maxWidth: .infinity, maxHeight: 500) // 🔥 Reduce height for a better layout
                .offset(y: -50) // 🔥 Adjust vertical positioning slightly
                .ignoresSafeArea()

            // 🔹 4. Bouton flottant en bas
            VStack {
                Spacer()
                Button("Changer d'Avatar") {
                    avatarManager.fetchAvatar()
                }
                .padding()
                .background(Color.white.opacity(0.15)) // Transparence légère
                .foregroundColor(.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            avatarManager.fetchAvatar()
        }
        .navigationTitle("Mon Avatar")
    }
}
