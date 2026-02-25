import SwiftUI
import CoreData

struct OutfitCreateView: View {
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DressingItem.title, ascending: true)]
    ) private var allItems: FetchedResults<DressingItem>

    @State private var title = ""
    @State private var style = ""
    @State private var season = ""
    @State private var notes = ""
    @State private var selectedIDs: Set<NSManagedObjectID> = []

    private let styles  = ["", "Casual", "Streetwear", "Sport", "Formel", "Chic", "Vintage", "Autre"]
    private let seasons = ["", "Toutes saisons", "Printemps/Été", "Automne/Hiver", "Été", "Hiver"]

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 40/255, green: 10/255, blue: 90/255),
                        Color(red: 15/255, green: 5/255, blue: 40/255)
                    ]),
                    center: .center, startRadius: 100, endRadius: 500
                )
                .ignoresSafeArea()
                FluidBackgroundView()

                ScrollView {
                    VStack(spacing: 16) {
                        sectionHeader("NOM DE LA TENUE")
                        GlassInputCard {
                            AddFieldRow(icon: "tshirt.fill", placeholder: "Nom de la tenue *", text: $title)
                        }

                        sectionHeader("STYLE & SAISON")
                        GlassInputCard {
                            AddPickerRow(icon: "tag.fill", label: "Style", selection: $style, options: styles)
                            formDivider
                            AddPickerRow(icon: "calendar", label: "Saison", selection: $season, options: seasons)
                        }

                        sectionHeader("NOTES")
                        GlassInputCard {
                            AddMultilineRow(icon: "note.text", placeholder: "Notes...", text: $notes)
                        }

                        let selCount = selectedIDs.count
                        sectionHeader("PIÈCES\(selCount > 0 ? " (\(selCount) sélectionnée\(selCount > 1 ? "s" : ""))" : "")")

                        if allItems.isEmpty {
                            GlassCard {
                                VStack(spacing: 10) {
                                    Image(systemName: "hanger")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white.opacity(0.2))
                                    Text("Ton dressing est vide")
                                        .font(.system(size: 13, weight: .light))
                                        .foregroundColor(.white.opacity(0.35))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                            }
                        } else {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(allItems, id: \.objectID) { item in
                                    ItemSelectionCell(
                                        item: item,
                                        isSelected: selectedIDs.contains(item.objectID)
                                    ) {
                                        if selectedIDs.contains(item.objectID) {
                                            selectedIDs.remove(item.objectID)
                                        } else {
                                            selectedIDs.insert(item.objectID)
                                        }
                                    }
                                }
                            }
                        }

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Créer une tenue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { isPresented = false }
                        .foregroundColor(.white.opacity(0.6))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") { createOutfit() }
                        .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
                        .fontWeight(.semibold)
                        .disabled(title.isEmpty)
                }
            }
        }
    }

    // MARK: - Create

    private func createOutfit() {
        let outfit = Outfit(context: context)
        outfit.id        = UUID()
        outfit.title     = title
        outfit.style     = style.isEmpty   ? nil : style
        outfit.season    = season.isEmpty  ? nil : season
        outfit.notes     = notes.isEmpty   ? nil : notes
        outfit.createdAt = Date()

        let selected = allItems.filter { selectedIDs.contains($0.objectID) }
        outfit.items = NSSet(array: selected)

        CoreDataController.shared.save()
        isPresented = false
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1.5)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    private var formDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 1)
            .padding(.leading, 52)
    }
}

// MARK: - ItemSelectionCell

struct ItemSelectionCell: View {
    let item: DressingItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        if let data = item.image, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            LinearGradient(
                                colors: [Color(red: 70/255, green: 30/255, blue: 140/255),
                                         Color(red: 35/255, green: 10/255, blue: 70/255)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                            Image(systemName: "hanger")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.22))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isSelected
                                    ? Color(red: 180/255, green: 120/255, blue: 255/255)
                                    : Color.white.opacity(0.09),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(red: 120/255, green: 60/255, blue: 200/255)
                                .opacity(isSelected ? 0.28 : 0))
                    )

                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color(red: 140/255, green: 80/255, blue: 220/255))
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(5)
                    }
                }

                Text(item.title.isEmpty ? "—" : item.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}
