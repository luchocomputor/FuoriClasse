import SwiftUI
import CoreData

struct DressingItemDetailView: View {
    @ObservedObject var item: DressingItem
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEdit = false
    
    var body: some View {
        ZStack {
            // 🔹 Arrière-plan en dégradé fluide
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // 🏷 TITRE
                    Text(item.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        .padding(.top, 30)
                    
                    // 🖼 IMAGE (responsive)
                    if let data = item.image, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.8, maxHeight: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.8), lineWidth: 2))
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 250, height: 250)
                            .overlay(Text("Aucune photo").foregroundColor(.white).bold())
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    // 📋 Informations (carte en verre)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Informations")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            infoRow(label: "Catégorie", value: item.category)
                            infoRow(label: "Taille", value: item.size)
                            infoRow(label: "Couleur", value: item.color)
                            
                            HStack {
                                Text("Classe :")
                                    .fontWeight(.semibold)
                                Circle()
                                    .fill(item.dotClassEnum.color)
                                    .frame(width: 20, height: 20)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Infos :")
                                    .fontWeight(.semibold)
                                Text(item.additionalInfo)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
                        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    
                    // 🛠 Boutons (placés en bas)
                    HStack(spacing: 20) {
                        Button(action: {
                            withAnimation { showingEdit = true }
                        }) {
                            Label("Modifier", systemImage: "pencil")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: {
                            deleteItem()
                        }) {
                            Label("Supprimer", systemImage: "trash")
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                }
                .padding(.bottom, 50) // Permet de mieux scroller sans cacher le contenu en bas
            }
        }
        .sheet(isPresented: $showingEdit) {
            DressingItemEditView(item: item, localDotClass: item.dotClassEnum)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    // MARK: - 📌 Fonction de création d'une ligne d'info
    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text("\(label) :")
                .fontWeight(.semibold)
            Text(value)
        }
        .foregroundColor(.primary)
    }
    
    // MARK: - 🗑 Suppression de l'item
    private func deleteItem() {
        viewContext.delete(item)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Erreur lors de la suppression : \(error)")
        }
    }
}
