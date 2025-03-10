//
//  GlassButtonLabel.swift
//  Fuoriclasse
//
//  Created by Louis Almairac on 06/03/2025.
//
import SwiftUI

struct GlassButtonLabel: View {
    let iconName: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.white)

            Text(text)
                .font(.custom("Futura", size: 20))
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 4)
    }
}

