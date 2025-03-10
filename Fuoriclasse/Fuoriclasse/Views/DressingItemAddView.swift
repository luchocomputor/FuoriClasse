import SwiftUI

struct DressingItemAddView: View {
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var brand = ""
    @State private var category: String = "T-shirt"
    @State private var size = "M"
    @State private var selectedShoeSize: Int = 42
    @State private var color = ""
    @State private var photoData: Data?
    @State private var dotClass: DotClass = .green
    @State private var additionalInfo = ""
    
    @State private var isShowingPhotoPicker = false
    
    let categories = ["T-shirt", "Sweat-shirt", "Robe", "Pantalon", "Short", "Chaussures", "Veste", "Manteau", "Chemise", "Pull"]
    let clothingSizes = ["XS", "S", "M", "L", "XL","XXL"]
    let shoeSizes = Array(35...48).map { "\($0)" }
    let pantsSizes = ["34", "36", "38", "40", "42", "44", "46", "48"]
    
    var selectedSizes: [String] {
        switch category {
        case "Chaussures": return shoeSizes
        case "Pantalon", "Short": return pantsSizes
        default: return clothingSizes
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.black]),
                    center: .top,
                    startRadius: 100,
                    endRadius: 600
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        photoPickerSection
                        inputFields
                        actionButtons
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Ajouter un vêtement")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingPhotoPicker) {
                PhotoPicker(photoData: $photoData)
            }
        }
    }
    
    // 📸 Sélection de la photo
    private var photoPickerSection: some View {
        ZStack {
            if let data = photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 5)
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.largeTitle)
                    )
            }
        }
        .onTapGesture {
            isShowingPhotoPicker = true
        }
    }
    
    // ✏️ Champs de saisie
    private var inputFields: some View {
        VStack(spacing: 15) {
            CustomTextField(placeholder: "Titre du vêtement", text: $title)
            CustomTextField(placeholder: "Marque", text: $brand)
            
            categoryPicker // ✅ Correction ici
            
            if category == "Chaussures" {
                SegmentedSizePicker(selectedSize: $size, sizes: shoeSizes) // 🥾 Pour chaussures
            } else {
                SegmentedSizePicker(selectedSize: $size, sizes: selectedSizes) // 👕 Pour vêtements
            }
            
            CustomTextField(placeholder: "Couleur", text: $color)
            CustomTextField(placeholder: "Infos complémentaires", text: $additionalInfo, isMultiline: true)
        }
    }
    
    // ✅ Boutons d'action
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button(action: { isPresented = false }) {
                GlassButtonLabel(iconName: "xmark", text: "Annuler")
            }
            
            Button(action: createItem) {
                GlassButtonLabel(iconName: "checkmark", text: "Créer")
            }
        }
        .padding(.top, 20)
    }
    
    // 🎯 Création de l’item
    private func createItem() {
        let newDTO = DressingItemDTO(
            id: UUID(),
            title: title,
            category: category,
            size: category == "Chaussures" ? "\(selectedShoeSize)" : size,
            color: color,
            brand: brand,
            image: photoData,
            dotClass: dotClass.rawValue,
            additionalInfo: additionalInfo
        )
        Persistence.shared.addItem(newDTO)
        isPresented = false
    }
    
    // 📌 Picker de Catégorie **avec largeur dynamique**
    private var categoryPicker: some View {
        HStack {
            Picker(selection: $category, label:
                Text(category)
                    .foregroundColor(Color.blue.opacity(0.8)) // 📌 Bleu translucide
                    .font(.system(size: 18, weight: .medium))
                    .frame(minWidth: 80, maxWidth: CGFloat(category.count) * 10 + 40, alignment: .leading) // 🔥 Largeur dynamique alignée à gauche
            ) {
                ForEach(categories, id: \.self) { cat in
                    Text(cat).foregroundColor(.white)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
        .frame(height: 50) // ✅ Hauteur uniforme
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .padding(.top, 10)
        .padding(.bottom, -4) // 🔥 Réduit l'espace sous la catégorie
    }

}

// 🏆 Sélecteur de taille **parfaitement aligné**
struct SegmentedSizePicker: View {
    @Binding var selectedSize: String
    var sizes: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) { // 🔄 Espacement plus fluide
                ForEach(sizes, id: \.self) { size in
                    Text(size)
                        .font(.system(size: 16, weight: .semibold, design: .rounded)) // ✅ Police améliorée
                        .foregroundColor(selectedSize == size ? .black : .white)
                        .frame(width: 50, height: 50) // ✅ Réduction proportionnelle
                        .background(RoundedRectangle(cornerRadius: 12).fill(selectedSize == size ? Color.white : Color.white.opacity(0.2)))
                        .onTapGesture { selectedSize = size }
                }
            }
            .padding(.leading, 4) // ✅ Alignement parfait
        }
        .frame(height: 70)
    }
}


struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false
    
    @State private var textHeight: CGFloat = 40 // 📏 Hauteur initiale
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.leading, 14)
            }
            
            if isMultiline {
                TextEditor(text: $text)
                    .frame(minHeight: textHeight, maxHeight: 150) // 📏 Ajuste la hauteur automatiquement
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
                    .foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .scrollContentBackground(.hidden) // 🔄 Supprime le fond gris par défaut
                    .onChange(of: text) { _ in adjustTextHeight() } // 🔥 Ajustement dynamique de la hauteur
            } else {
                TextField("", text: $text)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
                    .foregroundColor(.white)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
    private func adjustTextHeight() {
        let lineCount = text.split(separator: "\n").count
        textHeight = min(40 + CGFloat(lineCount - 1) * 20, 150)
    }
}
