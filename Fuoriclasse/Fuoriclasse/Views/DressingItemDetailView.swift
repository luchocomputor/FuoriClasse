import SwiftUI

struct DressingItemDetailView: View {
    var dto: DressingItemDTO
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false

    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [
                Color(red: 40/255, green: 10/255, blue: 90/255),
                Color(red: 15/255, green: 5/255, blue: 40/255)
            ]), center: .center, startRadius: 100, endRadius: 500)
            .ignoresSafeArea()

            FluidBackgroundView()

            VStack(spacing: 20) {
                if let data = dto.image, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width * 0.9, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(radius: 8)
                        .padding(.top, 30)
                        .transition(.opacity)
                }

                Text(dto.title)
                    .font(.custom("Futura-Bold", size: 28))
                    .foregroundColor(.white)
                    .shadow(radius: 4)

                VStack(spacing: 12) {
                    DetailGlassRow(label: "Catégorie", value: dto.category)
                    DetailGlassRow(label: "Taille", value: dto.size)
                    DetailGlassRow(label: "Couleur", value: dto.color)
                    DetailGlassRow(label: "Classe", value: dto.dotClass)
                    Text(dto.additionalInfo)
                        .font(.custom("Futura", size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                }
                .padding(.horizontal, 20)

                HStack(spacing: 20) {
                    Button(action: { showingEdit = true }) {
                        GlassButtonLabel(iconName: "pencil", text: "Modifier")
                    }
                    
                    Button(action: deleteItem) {
                        GlassButtonLabel(iconName: "trash", text: "Supprimer")
                            .foregroundColor(.red)
                    }
                }
                .padding(.bottom, 20)
            }
            .sheet(isPresented: $showingEdit) {
                DressingItemEditView(isPresented: $showingEdit, dto: dto)
            }
        }
    }

    private func deleteItem() {
        withAnimation {
            Persistence.shared.deleteItem(dto)
            dismiss()
        }
    }
}
// MARK: - Composants UI
struct CustomTextField2: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(10)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
    }
}

struct DetailTextRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text("\(label) :")
                .font(.custom("Futura-Bold", size: 18))
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.custom("Futura", size: 18))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 20)
    }
}
