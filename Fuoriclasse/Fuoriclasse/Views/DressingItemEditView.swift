import SwiftUI
import UIKit

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1) // Léger voile blanc
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct DressingItemEditView: View {
    @Binding var isPresented: Bool
    var dto: DressingItemDTO

    @State private var title: String
    @State private var category: String
    @State private var size: String
    @State private var color: String
    @State private var brand: String
    @State private var additionalInfo: String
    @State private var dotClass: String
    @State private var imageData: Data?

    init(isPresented: Binding<Bool>, dto: DressingItemDTO) {
        self._isPresented = isPresented
        self._title = State(initialValue: dto.title)
        self._category = State(initialValue: dto.category)
        self._size = State(initialValue: dto.size)
        self._color = State(initialValue: dto.color)
        self._brand = State(initialValue: dto.brand)
        self._additionalInfo = State(initialValue: dto.additionalInfo)
        self._dotClass = State(initialValue: dto.dotClass)
        self._imageData = State(initialValue: dto.image)
        self.dto = dto
    }

    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [
                Color(red: 40/255, green: 10/255, blue: 90/255),
                Color(red: 15/255, green: 5/255, blue: 40/255)
            ]), center: .center, startRadius: 100, endRadius: 500)
            .ignoresSafeArea()

            FluidBackgroundView()

            VStack {
                Text("Modifier l'article")
                    .font(.custom("Futura-Bold", size: 26))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
                    .padding(.top, 30)

                if let data = imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 6)
                        .padding(.top, 10)
                        .transition(.opacity)
                }

                ScrollView {
                    VStack(spacing: 15) {
                        CustomGlassField(placeholder: "Titre", text: $title)
                        CustomGlassField(placeholder: "Catégorie", text: $category)
                        CustomGlassField(placeholder: "Taille", text: $size)
                        CustomGlassField(placeholder: "Couleur", text: $color)
                        CustomGlassField(placeholder: "Marque", text: $brand)
                        CustomGlassField(placeholder: "Classe", text: $dotClass)
                        CustomGlassField(placeholder: "Infos supplémentaires", text: $additionalInfo)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 10)

                HStack(spacing: 20) {
                    Button(action: saveChanges) {
                        GlassButtonLabel(iconName: "checkmark", text: "Enregistrer")
                    }

                    Button(action: { isPresented = false }) {
                        GlassButtonLabel(iconName: "xmark", text: "Annuler")
                    }
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
    }

    private func saveChanges() {
        let updatedDTO = DressingItemDTO(
            id: dto.id, title: title, category: category,
            size: size, color: color, brand: brand,
            image: imageData, dotClass: dotClass, additionalInfo: additionalInfo
        )

        withAnimation {
            Persistence.shared.updateItem(updatedItem: updatedDTO)
            isPresented = false
        }
    }
}


// MARK: - 🎨 Composants Custom
struct CustomGlassField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(BlurView(style: .systemThinMaterialDark))
            .cornerRadius(12)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
    }
}

struct DetailGlassRow: View {
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
