import SwiftUI
import CoreData

struct DressingItemListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DressingItem.title, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<DressingItem>
    
    @State private var showingAddSheet = false
    
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

            VStack {
                // 🔹 2. Titre
                Text("Mon Dressing")
                    .font(.custom("Futura-Bold", size: 32))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 2, y: 2)
                    .padding(.top, 10)
                
                // 🔹 3. Liste des vêtements
                List {
                    ForEach(items, id: \.self) { item in
                        NavigationLink(destination: DressingItemDetailView(item: item)) {
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(item.category)
                                    .foregroundColor(.gray)
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
                .frame(height: 500)

                // 🔹 4. Bouton "Ajouter" en verre
                Button(action: { showingAddSheet = true }) {
                    GlassButtonLabel(iconName: "plus", text: "Ajouter un vêtement")
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            DressingItemAddView(isPresented: $showingAddSheet)
                .environment(\.managedObjectContext, viewContext)
        }
    }
}
