import SwiftUI

struct DressingItemDetailView: View {
    var dto: DressingItemDTO
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEdit = false
    
    var body: some View {
        ZStack {
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
                if let data = dto.image, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFit().frame(width: 250, height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 5)
                }
                
                Text(dto.title).font(.custom("Futura-Bold", size: 28)).foregroundColor(.white)
                
                VStack {
                    Text("Catégorie : \(dto.category)").foregroundColor(.white)
                    Text("Taille : \(dto.size)").foregroundColor(.white)
                    Text("Couleur : \(dto.color)").foregroundColor(.white)
                    Text("Classe : \(dto.dotClass)").foregroundColor(.white)
                    Text(dto.additionalInfo).foregroundColor(.gray)
                }
                .padding()
                
                HStack {
                    Button("Modifier") { showingEdit = true }
                    Button("Supprimer") {
                        Persistence.shared.deleteItem(dto)
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showingEdit) {
                DressingItemEditView(isPresented: $showingEdit, dto: dto)
            }
        }
    }
}
