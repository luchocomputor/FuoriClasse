import SwiftUI

struct AuthView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Fond identique au reste de l'app
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 40/255, green: 10/255, blue: 90/255),
                        Color(red: 15/255, green: 5/255, blue: 40/255)
                    ]),
                    center: .center, startRadius: 100, endRadius: 500
                )
                FluidBackgroundView()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // En-tête
                VStack(spacing: 8) {
                    Text("Fuoriclasse")
                        .font(.custom("Futura-Bold", size: 34))
                        .foregroundColor(.white)

                    Text("VOTRE STYLISTE PERSONNEL")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2.5)
                }
                .padding(.top, 60)
                .padding(.bottom, 36)

                // Sélecteur Connexion / Inscription
                segmentedPicker
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                // Contenu de l'onglet
                TabView(selection: $selectedTab) {
                    LoginView()
                        .tag(0)
                    SignUpView()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: selectedTab)

                Spacer()
            }
        }
    }

    private var segmentedPicker: some View {
        HStack(spacing: 0) {
            ForEach(["Connexion", "Inscription"].indices, id: \.self) { i in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = i }
                } label: {
                    Text(["Connexion", "Inscription"][i])
                        .font(.system(size: 15, weight: selectedTab == i ? .semibold : .regular))
                        .foregroundColor(selectedTab == i ? .white : .white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedTab == i {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.white.opacity(0.15))
                                }
                            }
                        )
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
