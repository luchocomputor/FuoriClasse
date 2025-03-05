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
        NavigationStack {
            List {
                ForEach(items, id: \.self) { item in
                    NavigationLink(destination: DressingItemDetailView(item: item)) {
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.category)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Mon Dressing")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Ajouter", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                DressingItemAddView(isPresented: $showingAddSheet)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}
