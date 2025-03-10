//
//  SplashView.swift
//  Fuoriclasse
//
//  Created by Louis Almairac on 05/03/2025.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    
    var body: some View {
        if isActive {
            HomeView() // Your main HomeView with the dynamic background
        } else {
            ZStack {
                FluidBackgroundView() // Your animated purple blob background
                
                VStack {
                    Text("Fuoriclasse")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(opacity)
                }
            }
            .onAppear {
                withAnimation(.easeIn(duration: 1.0)) {
                    opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isActive = true
                }
            }
        }
    }
}
