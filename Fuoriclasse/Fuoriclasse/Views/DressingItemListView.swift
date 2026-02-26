import SwiftUI

struct DressingItemListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DressingItem.title, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<DressingItem>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Outfit.createdAt, ascending: false)],
        animation: .default
    )
    private var outfits: FetchedResults<Outfit>

    @State private var selectedTab = 0
    @State private var showingAddSheet = false

    var body: some View {
        ZStack {
            // Fond
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 40/255, green: 10/255, blue: 90/255),
                    Color(red: 15/255, green: 5/255, blue: 40/255)
                ]),
                center: .center, startRadius: 100, endRadius: 500
            )
            .ignoresSafeArea()
            FluidBackgroundView()

            // Contenu
            VStack(spacing: 0) {
                // Segmented control SwiftUI natif (évite les problèmes de largeur UIKit dans ZStack)
                dressingSegmentedControl
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                if selectedTab == 0 {
                    piecesContent
                } else {
                    tenuesContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bouton flottant
            VStack {
                Spacer()
                Button { showingAddSheet = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text(selectedTab == 0 ? "Ajouter une pièce" : "Créer une tenue")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 28)
                    .background(
                        Capsule()
                            .fill(Color(red: 120/255, green: 60/255, blue: 200/255))
                            .shadow(color: Color(red: 120/255, green: 60/255, blue: 200/255).opacity(0.5),
                                    radius: 12, x: 0, y: 4)
                    )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Mon Dressing")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showingAddSheet) {
            if selectedTab == 0 {
                DressingItemAddView(isPresented: $showingAddSheet)
                    .environment(\.managedObjectContext, CoreDataController.shared.context)
            } else {
                OutfitCreateView(isPresented: $showingAddSheet)
                    .environment(\.managedObjectContext, CoreDataController.shared.context)
            }
        }
    }

    // MARK: - Pièces

    private var piecesContent: some View {
        Group {
            if items.isEmpty {
                emptyStatePieces
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(items, id: \.objectID) { item in
                            NavigationLink(destination: DressingItemDetailView(item: item)) {
                                DressingItemCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    // MARK: - Tenues

    private var tenuesContent: some View {
        Group {
            if outfits.isEmpty {
                emptyStateTenues
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(outfits, id: \.objectID) { outfit in
                            NavigationLink(destination: OutfitDetailView(outfit: outfit)) {
                                OutfitCard(outfit: outfit)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    // MARK: - Empty states

    private var emptyStatePieces: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "hanger")
                .font(.system(size: 52))
                .foregroundColor(.white.opacity(0.2))
            Text("Ton dressing est vide")
                .font(.custom("Futura-Bold", size: 20))
                .foregroundColor(.white.opacity(0.4))
            Text("Ajoute ta première pièce !")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.white.opacity(0.3))
            Spacer()
        }
    }

    private var emptyStateTenues: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "rectangle.3.group.fill")
                .font(.system(size: 52))
                .foregroundColor(.white.opacity(0.2))
            Text("Aucune tenue créée")
                .font(.custom("Futura-Bold", size: 20))
                .foregroundColor(.white.opacity(0.4))
            Text("Combine tes pièces en tenues !")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.white.opacity(0.3))
            Spacer()
        }
    }

    // MARK: - Segmented control SwiftUI

    private var dressingSegmentedControl: some View {
        HStack(spacing: 0) {
            ForEach([("Pièces", 0), ("Tenues", 1)], id: \.1) { label, tag in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tag }
                } label: {
                    Text(label)
                        .font(.system(size: 14, weight: selectedTab == tag ? .semibold : .regular))
                        .foregroundColor(selectedTab == tag ? .white : .white.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if selectedTab == tag {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(Color.white.opacity(0.15))
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
