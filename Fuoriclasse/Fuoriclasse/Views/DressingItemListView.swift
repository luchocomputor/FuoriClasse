import SwiftUI

struct DressingItemListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DressingItem.title, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<DressingItem>

    @State private var showingAddSheet = false

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
                Text("Mon Dressing")
                    .font(.custom("Futura-Bold", size: 28))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 2, y: 2)
                    .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(items, id: \.objectID) { item in
                            NavigationLink(destination: DressingItemDetailView(item: item)) {
                                DressingItemCard(item: item)
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()

                Button(action: { showingAddSheet = true }) {
                    GlassButtonLabel(iconName: "plus", text: "Ajouter un vêtement")
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            DressingItemAddView(isPresented: $showingAddSheet)
                .environment(\.managedObjectContext, CoreDataController.shared.context)
        }
    }
}
