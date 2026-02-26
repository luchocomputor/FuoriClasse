import SwiftUI

struct OutfitDetailView: View {
    let outfit: Outfit
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                itemsGrid
                if let notes = outfit.notes, !notes.isEmpty {
                    notesCard(notes)
                }
                actionButtons
                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
        .background {
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 40/255, green: 10/255, blue: 90/255),
                        Color(red: 15/255, green: 5/255, blue: 40/255)
                    ]),
                    center: .center, startRadius: 100, endRadius: 500
                )
                FluidBackgroundView()
            }
            .ignoresSafeArea()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Supprimer cette tenue ?", isPresented: $showDeleteAlert) {
            Button("Supprimer", role: .destructive) { deleteOutfit() }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("La tenue sera supprimée. Les pièces sont conservées.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(outfit.title ?? "Sans titre")
                .font(.custom("Futura-Bold", size: 26))
                .foregroundColor(.white)
                .lineLimit(2)

            HStack(spacing: 8) {
                if let style = outfit.style, !style.isEmpty {
                    StyleChip(icon: "tag.fill", label: style,
                              color: Color(red: 140/255, green: 80/255, blue: 220/255))
                }
                if let season = outfit.season, !season.isEmpty {
                    StyleChip(icon: seasonIcon(outfit.season ?? ""), label: season,
                              color: Color(red: 60/255, green: 140/255, blue: 220/255))
                }

                Spacer()

                let count = outfit.itemsArray.count
                Text("\(count) pièce\(count > 1 ? "s" : "")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Grille pièces

    private var itemsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PIÈCES")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1.5)
                .padding(.horizontal, 4)

            if outfit.itemsArray.isEmpty {
                GlassCard {
                    VStack(spacing: 10) {
                        Image(systemName: "hanger")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.2))
                        Text("Aucune pièce dans cette tenue")
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(outfit.itemsArray, id: \.objectID) { item in
                        NavigationLink(destination: DressingItemDetailView(item: item)) {
                            OutfitItemTile(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Notes

    private func notesCard(_ text: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("NOTES")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(1.5)
                Text(text)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(4)
            }
            .padding(16)
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        Button { showDeleteAlert = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                Text("Supprimer la tenue")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.red.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.red.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func deleteOutfit() {
        withAnimation {
            CoreDataController.shared.delete(outfit)
            dismiss()
        }
    }

    private func seasonIcon(_ season: String) -> String {
        let s = season.lowercased()
        if s.contains("hiver")    { return "snowflake" }
        if s.contains("été")      { return "sun.max.fill" }
        if s.contains("automne")  { return "leaf.fill" }
        if s.contains("printemps") { return "cloud.sun.fill" }
        return "calendar"
    }
}

// MARK: - OutfitItemTile

struct OutfitItemTile: View {
    let item: DressingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let data = item.image, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [Color(red: 70/255, green: 30/255, blue: 140/255),
                                 Color(red: 40/255, green: 10/255, blue: 80/255)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    Image(systemName: "hanger")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.22))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title.isEmpty ? "—" : item.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                if !item.category.isEmpty {
                    Text(item.category)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 140/255, green: 80/255, blue: 220/255).opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
