import SwiftUI
import CoreData

struct DressingItemAddView: View {
    @Binding var isPresented: Bool
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // Champs d’édition
    @State private var title: String = ""
    @State private var category: String = "T-shirt"
    @State private var size: String = "M"
    @State private var color: String = ""
    @State private var photoData: Data?
    @State private var dotClass: DotClass = .green
    @State private var additionalInfo: String = ""
    
    // Contrôle de la présentation du PhotoPicker
    @State private var isShowingPhotoPicker = false
    
    // Options pour les pickers
    let categories = ["T-shirt", "Sweat-shirt", "Robe", "Pantalon", "Short"]
    let sizes = ["XS", "S", "M", "L", "XL"]
    
    var body: some View {
        VStack {
            Text("Nouvel Item")
                .font(.headline)
                .padding(.top)
            
            Form {
                TextField("Titre", text: $title)
                
                Picker("Catégorie", selection: $category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat)
                    }
                }
                
                Picker("Taille", selection: $size) {
                    ForEach(sizes, id: \.self) { s in
                        Text(s)
                    }
                }
                
                TextField("Couleur", text: $color)
                
                Section(header: Text("Photo")) {
                    #if os(macOS)
                    if let data = photoData,
                       !data.isEmpty,
                       let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    } else {
                        Text("Aucune photo sélectionnée")
                            .foregroundColor(.secondary)
                    }
                    #else
                    if let data = photoData,
                       !data.isEmpty,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    } else {
                        Text("Aucune photo sélectionnée")
                            .foregroundColor(.secondary)
                    }
                    #endif
                    
                    Button("Sélectionner une photo") {
                        isShowingPhotoPicker = true
                    }
                }
                
                Picker("Classe", selection: $dotClass) {
                    ForEach(DotClass.allCases, id: \.self) { dot in
                        HStack {
                            Circle()
                                .fill(dot.color)
                                .frame(width: 16, height: 16)
                            Text(dot.rawValue)
                        }
                    }
                }
                
                TextField("Infos complémentaires", text: $additionalInfo)
            }
            .padding()
            
            HStack {
                Button("Annuler") {
                    print("=== [DressingItemAddView] Bouton Annuler tapé ===")
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Créer") {
                    print("=== [DressingItemAddView] Bouton Créer tapé ===")
                    createItem()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.bottom)
        }
        .frame(minWidth: 400, minHeight: 300)
        .sheet(isPresented: $isShowingPhotoPicker) {
            PhotoPicker(photoData: $photoData)
        }
    }
    
    // MARK: - Création de l'Item
    private func createItem() {
        print("=== [DressingItemAddView] createItem() appelé ===")
        print("Titre = \(title), Catégorie = \(category), Taille = \(size), Couleur = \(color)")
        
        let newItem = DressingItem(context: viewContext)
        newItem.id = UUID()
        newItem.title = title
        newItem.category = category
        newItem.size = size
        newItem.color = color
        newItem.image = photoData
        newItem.dotClass = dotClass.rawValue
        newItem.additionalInfo = additionalInfo
        
        do {
            print("=== [DressingItemAddView] Avant viewContext.save() ===")
            try viewContext.save()
            print("=== [DressingItemAddView] Après viewContext.save() => OK ===")
            isPresented = false
        } catch {
            print("=== [DressingItemAddView] ERREUR lors de la création : \(error) ===")
        }
    }
}
