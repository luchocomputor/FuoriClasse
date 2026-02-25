//
//  SplashView.swift
//  Fuoriclasse
//
//  Created by Louis Almairac on 05/03/2025.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var opacity = 0.0
    @State private var animationDone = false

    var body: some View {
        Group {
            if !animationDone || auth.isLoading {
                splashContent
            } else if auth.session != nil {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) { opacity = 1.0 }
            auth.initialize()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                animationDone = true
            }
        }
    }

    private var splashContent: some View {
        ZStack {
            FluidBackgroundView()
            VStack(spacing: 20) {
                Text("Fuoriclasse")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(opacity)

                // Spinner discret — visible seulement après l'animation
                // si la session Supabase est encore en cours de restauration
                if animationDone && auth.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                        .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea()
    }
}
