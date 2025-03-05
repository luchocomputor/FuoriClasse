import SwiftUI
import CoreData

struct DressingItemEditView: View {
    @ObservedObject var item: DressingItem
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // États locaux pour les champs éditables
    @State private var localTitle: String = ""
    @State private var localCategory: String = ""
    @State private var localSize: String = ""
    @State private var localColor: String = ""
    @State private var localDotClass: DotClass
    @State private var localAdditionalInfo: String = ""
    @State private var localImage: UIImage?
    
    // États pour le picker d'image
    @State private var showImagePicker = false
    
    // Exemple de données pour les Picker
    let categories = ["Sweat-shirt", "T-shirt", "Jean"]
    let sizes = ["XS", "S", "M", "L", "XL"]
    
    // ⚠️ Ajout d'un initialiseur explicite pour que localDotClass
    // soit initialisé correctement (et qu'il ne soit pas "private").
    init(item: DressingItem, localDotClass: DotClass) {
        self.item = item
        self._localDotClass = State(initialValue: localDotClass)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Section pour la photo
                Section {
                    HStack {
                        if let image = localImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text("Aucune photo")
                                        .foregroundColor(.white)
                                )
                        }
                        Spacer()
                        Button("Modifier la photo") {
                            showImagePicker = true
                        }
                    }
                }
                
                // Champs texte avec labels fixes à gauche
                Section {
                    HStack {
                        Text("Titre")
                        Spacer()
                        TextField("", text: $localTitle)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Catégorie", selection: $localCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat)
                        }
                    }
                    
                    Picker("Taille", selection: $localSize) {
                        ForEach(sizes, id: \.self) { s in
                            Text(s)
                        }
                    }
                    
                    HStack {
                        Text("Couleur")
                        Spacer()
                        TextField("", text: $localColor)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Classe", selection: $localDotClass) {
                        ForEach(DotClass.allCases, id: \.self) { dot in
                            HStack {
                                Circle()
                                    .fill(dot.color)
                                    .frame(width: 16, height: 16)
                                Text(dot.rawValue)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Infos complémentaires")
                        Spacer()
                        TextField("", text: $localAdditionalInfo)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Modifier l'annonce")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        saveChanges()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $localImage)
            }
            .onAppear {
                // Initialisation des valeurs locales à partir de l'item
                localTitle = item.title
                localCategory = item.category
                localSize = item.size
                localColor = item.color
                localAdditionalInfo = item.additionalInfo
                // localDotClass est déjà initialisé dans l'init
                // mais on peut le forcer à se caler sur item.dotClassEnum si besoin :
                // localDotClass = item.dotClassEnum
                if let data = item.image, let uiImage = UIImage(data: data) {
                    localImage = uiImage
                }
            }
        }
    }
    
    private func saveChanges() {
        item.title = localTitle
        item.category = localCategory
        item.size = localSize
        item.color = localColor
        item.additionalInfo = localAdditionalInfo
        item.dotClassEnum = localDotClass
        if let image = localImage {
            item.image = image.pngData()
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Erreur lors de la sauvegarde : \(error)")
        }
    }
}

// MARK: - ImagePicker (inchangé)
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

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
