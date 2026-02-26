import SwiftUI
import UIKit

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct DressingItemEditView: View {
    @Binding var isPresented: Bool
    var item: DressingItem

    @State private var title: String
    @State private var brand: String
    @State private var category: String
    @State private var size: String
    @State private var color: String
    @State private var material: String
    @State private var fit: String
    @State private var season: String
    @State private var style: String
    @State private var price: String
    @State private var dotClass: DotClass
    @State private var additionalInfo: String
    @State private var imageData: Data?
    @State private var isShowingPhotoPicker = false

    let categories = ["T-shirt", "Sweat-shirt", "Chemise", "Pull", "Robe", "Pantalon", "Short",
                      "Veste", "Manteau", "Chaussures", "Accessoire", "Autre"]
    let seasons    = ["Toutes saisons", "Printemps/Été", "Automne/Hiver", "Été", "Hiver"]
    let styles     = ["", "Casual", "Streetwear", "Sport", "Formel", "Chic", "Vintage", "Autre"]
    let fits       = ["", "Regular", "Slim", "Oversize", "Ajusté", "Loose"]
    let clothingSizes = ["XS", "S", "M", "L", "XL", "XXL"]
    let shoeSizes  = Array(35...48).map { "\($0)" }
    let pantsSizes = ["34", "36", "38", "40", "42", "44", "46", "48"]

    var selectedSizes: [String] {
        switch category {
        case "Chaussures":       return shoeSizes
        case "Pantalon", "Short": return pantsSizes
        default:                 return clothingSizes
        }
    }
    var isShoe: Bool { category == "Chaussures" }

    init(isPresented: Binding<Bool>, item: DressingItem) {
        self._isPresented = isPresented
        self.item = item
        // Accès via value(forKey:) pour sécuriser contre le nil ObjC bridge :
        // les @NSManaged String non-optionnels peuvent retourner nil si Core Data
        // n'a pas encore résolu le fault, causant un affichage vide des champs.
        self._title          = State(initialValue: (item.value(forKey: "title") as? String) ?? "")
        self._brand          = State(initialValue: (item.value(forKey: "brand") as? String) ?? "")
        self._category       = State(initialValue: (item.value(forKey: "category") as? String) ?? "T-shirt")
        self._size           = State(initialValue: (item.value(forKey: "size") as? String) ?? "M")
        self._color          = State(initialValue: (item.value(forKey: "color") as? String) ?? "")
        self._material       = State(initialValue: item.material ?? "")
        self._fit            = State(initialValue: item.fit ?? "")
        self._season         = State(initialValue: item.season ?? "Toutes saisons")
        self._style          = State(initialValue: item.style ?? "")
        self._price          = State(initialValue: item.price ?? "")
        self._dotClass       = State(initialValue: item.dotClassEnum)
        self._additionalInfo = State(initialValue: (item.value(forKey: "additionalInfo") as? String) ?? "")
        self._imageData      = State(initialValue: item.image)
    }

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
                .ignoresSafeArea(edges: .all)
                FluidBackgroundView()

                ScrollView {
                    VStack(spacing: 16) {
                        photoSection
                        fieldsSection
                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { isPresented = false }
                        .foregroundColor(.white.opacity(0.6))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { saveChanges() }
                        .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $isShowingPhotoPicker) {
                PhotoPicker(photoData: $imageData)
            }
        }
    }

    // MARK: - Photo

    private var photoSection: some View {
        Button { isShowingPhotoPicker = true } label: {
            ZStack {
                if let data = imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 10) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white.opacity(0.3))
                                Text("Changer la photo")
                                    .font(.system(size: 13, weight: .light))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Champs

    private var fieldsSection: some View {
        VStack(spacing: 12) {
            // ── Identité
            editSectionHeader("IDENTITÉ")
            GlassInputCard {
                AddFieldRow(icon: "tag.fill", placeholder: "Nom du vêtement", text: $title)
                editDivider
                AddFieldRow(icon: "building.2.fill", placeholder: "Marque", text: $brand)
            }

            // ── Catégorie
            editSectionHeader("CATÉGORIE")
            GlassInputCard {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(red: 140/255, green: 80/255, blue: 220/255).opacity(0.2))
                            .frame(width: 34, height: 34)
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
                    }
                    Picker("Catégorie", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .padding(.bottom, 80)
            }

            // ── Taille
            editSectionHeader("TAILLE")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedSizes, id: \.self) { s in
                        Button { size = s } label: {
                            Text(s)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(size == s ? Color(red: 15/255, green: 5/255, blue: 40/255) : .white)
                                .frame(width: 52, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(size == s
                                              ? Color(red: 180/255, green: 120/255, blue: 255/255)
                                              : Color.white.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }

            // ── Aspect
            editSectionHeader("ASPECT")
            GlassInputCard {
                AddFieldRow(icon: "paintpalette.fill", placeholder: "Couleur", text: $color)
                editDivider
                AddFieldRow(icon: "leaf.fill", placeholder: "Matière (ex: 100% Coton)", text: $material)
                if !isShoe {
                    editDivider
                    AddPickerRow(icon: "figure.stand", label: "Coupe", selection: $fit, options: fits)
                }
            }

            // ── Style & Saison
            editSectionHeader("STYLE & SAISON")
            GlassInputCard {
                AddPickerRow(icon: "tag.fill", label: "Style", selection: $style, options: styles)
                editDivider
                AddPickerRow(icon: "calendar", label: "Saison", selection: $season, options: seasons)
            }

            // ── État & Prix
            editSectionHeader("ÉTAT & PRIX")
            GlassInputCard {
                etatPicker
                editDivider
                AddFieldRow(icon: "eurosign.circle.fill", placeholder: "Prix payé (€)", text: $price)
            }

            // ── Notes
            editSectionHeader("NOTES")
            GlassInputCard {
                AddMultilineRow(icon: "note.text", placeholder: "Informations complémentaires", text: $additionalInfo)
            }
        }
    }

    private var etatPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(dotClass.color.opacity(0.25))
                        .frame(width: 34, height: 34)
                    Circle()
                        .fill(dotClass.color)
                        .frame(width: 10, height: 10)
                }
                Text("État")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
            }
            HStack(spacing: 8) {
                ForEach(DotClass.allCases, id: \.self) { dc in
                    Button { dotClass = dc } label: {
                        HStack(spacing: 5) {
                            Circle().fill(dc.color).frame(width: 7, height: 7)
                            Text(etatLabel(dc))
                                .font(.system(size: 12, weight: dotClass == dc ? .semibold : .regular))
                                .foregroundColor(dotClass == dc ? .white : .white.opacity(0.45))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(dotClass == dc ? dc.color.opacity(0.2) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(dotClass == dc ? dc.color.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func editSectionHeader(_ text: String) -> some View {
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

    private var editDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 1)
            .padding(.leading, 52)
    }

    private func etatLabel(_ dc: DotClass) -> String {
        switch dc {
        case .green:  return "Neuf"
        case .orange: return "Bon état"
        case .red:    return "Usé"
        }
    }

    private func saveChanges() {
        item.title         = title
        item.brand         = brand
        item.category      = category
        item.size          = size
        item.color         = color
        item.material      = material.isEmpty ? nil : material
        item.fit           = fit.isEmpty ? nil : fit
        item.season        = season
        item.style         = style.isEmpty ? nil : style
        item.price         = price.isEmpty ? nil : price
        item.image         = imageData
        item.dotClass      = dotClass.rawValue
        item.additionalInfo = additionalInfo
        CoreDataController.shared.save()
        isPresented = false
    }
}

// MARK: - DetailGlassRow (conservé pour compatibilité)
struct DetailGlassRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - CustomGlassField (conservé pour compatibilité)
struct CustomGlassField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(BlurView(style: .systemThinMaterialDark))
            .cornerRadius(12)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
    }
}
