import SwiftUI

struct AvatarView: View {
    @StateObject var avatarManager = AvatarManager()
    @State private var selectedAvatar: String = "lucho3"

    var body: some View {
        ZStack {
            // 🔹 1. Fond Radial (violet)
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

            // 🔹 2. Effets fluides
            FluidBackgroundView()

            // 🔹 3. Affichage de l’avatar 3D avec l’avatar sélectionné
            Avatar3DView(avatarManager: avatarManager)
                .frame(maxWidth: .infinity, maxHeight: 500)
                .offset(y: -50)
                .ignoresSafeArea()

            // 🔹 4. Sélection de l’avatar
            VStack {
                Spacer()
                
                Text("Choisir un Avatar")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(.bottom, 10)

                HStack(spacing: 20) {
                    Button("Avatar 1") {
                        selectedAvatar = "lucho3"
                        avatarManager.fetchAvatar(fileName: selectedAvatar) // ✅ Change l’avatar localement
                    }
                    .padding()
                    .background(selectedAvatar == "lucho3" ? Color.blue.opacity(0.3) : Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button("Avatar 2") {
                        selectedAvatar = "lucho3"
                        avatarManager.fetchAvatar(fileName: selectedAvatar)
                    }
                    .padding()
                    .background(selectedAvatar == "lucho3" ? Color.blue.opacity(0.3) : Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Button("Changer d'Avatar") {
                    avatarManager.fetchAvatar(fileName: selectedAvatar) // ✅ Recharge l’avatar sélectionné
                }
                .padding()
                .background(Color.white.opacity(0.15))
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
            avatarManager.fetchAvatar(fileName: selectedAvatar) // ✅ Charge l’avatar par défaut au démarrage
        }
        .navigationTitle("Mon Avatar")
    }
}
