import SwiftUI
import CoreData

struct DressingItemDetailView: View {
    @ObservedObject var item: DressingItem
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEdit = false
    
    var body: some View {
        ZStack {
            // 🔹 1. Fond Radial + Blobs
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
            
            FluidBackgroundView()

            VStack(spacing: 20) {
                // 🔹 2. Image du vêtement
                if let data = item.image, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                }
                
                // 🔹 3. Titre du vêtement
                Text(item.title)
                    .font(.custom("Futura-Bold", size: 28))
                    .foregroundColor(.white)

                // 🔹 4. Infos détaillées (boutons en verre)
                VStack(alignment: .leading, spacing: 15) {
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
                        Text("Infos complémentaires :")
                            .fontWeight(.semibold)
                        Text(item.additionalInfo)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(20)
                .background(GlassBackgroundView())
                .cornerRadius(15)
                .shadow(radius: 5)

                // 🔹 5. Boutons "Modifier" et "Supprimer"
                HStack(spacing: 20) {
                    Button(action: { showingEdit = true }) {
                        GlassButtonLabel(iconName: "pencil", text: "Modifier")
                    }
                    
                    Button(action: { deleteItem() }) {
                        GlassButtonLabel(iconName: "trash", text: "Supprimer")
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 20)
            }
        }
        .sheet(isPresented: $showingEdit) {
            DressingItemEditView(item: item, localDotClass: item.dotClassEnum)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text("\(label) :")
                .fontWeight(.semibold)
            Text(value)
        }
        .foregroundColor(.white)
    }
    
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
