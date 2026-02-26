import SwiftUI

// MARK: - Mode d'ajout

enum AddMode { case manual, online }

// MARK: - État du fetch URL

private enum FetchState: Equatable {
    case idle, loading, success, error(String)
}

// MARK: - DressingItemAddView

struct DressingItemAddView: View {
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var context

    // Choix du mode (nil = écran picker)
    @State private var mode: AddMode? = nil

    // Champs du formulaire
    @State private var title          = ""
    @State private var brand          = ""
    @State private var category       = "T-shirt"
    @State private var size           = "M"
    @State private var color          = ""
    @State private var material       = ""
    @State private var fit            = ""
    @State private var season         = "Toutes saisons"
    @State private var style          = ""
    @State private var price          = ""
    @State private var dotClass: DotClass = .green
    @State private var additionalInfo = ""
    @State private var photoData: Data?
    @State private var isShowingPhotoPicker = false

    // URL / fetch (mode online)
    @State private var sourceURL  = ""
    @State private var fetchState: FetchState = .idle

    let categories    = ["T-shirt", "Sweat-shirt", "Chemise", "Pull", "Robe", "Pantalon", "Short",
                         "Veste", "Manteau", "Chaussures", "Accessoire", "Autre"]
    let seasons       = ["Toutes saisons", "Printemps/Été", "Automne/Hiver", "Été", "Hiver"]
    let styles        = ["", "Casual", "Streetwear", "Sport", "Formel", "Chic", "Vintage", "Autre"]
    let fits          = ["", "Regular", "Slim", "Oversize", "Ajusté", "Loose"]
    let clothingSizes = ["XS", "S", "M", "L", "XL", "XXL"]
    let shoeSizes     = Array(35...48).map { "\($0)" }
    let pantsSizes    = ["34", "36", "38", "40", "42", "44", "46", "48"]

    var selectedSizes: [String] {
        switch category {
        case "Chaussures":          return shoeSizes
        case "Pantalon", "Short":   return pantsSizes
        default:                    return clothingSizes
        }
    }
    var isShoe: Bool { category == "Chaussures" }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if mode == nil {
                    pickerContent
                } else {
                    formContent
                }
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
            .navigationTitle("Ajouter une pièce")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(mode == nil ? "Annuler" : "Retour") {
                        if mode == nil {
                            isPresented = false
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) { mode = nil }
                        }
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                if mode != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Ajouter") { createItem() }
                            .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
                            .fontWeight(.semibold)
                            .disabled(title.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $isShowingPhotoPicker) {
                PhotoPicker(photoData: $photoData)
            }
        }
    }

    // MARK: - Picker (écran de choix)

    private var pickerContent: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 10) {
                Text("Comment ajouter\ncette pièce ?")
                    .font(.custom("Futura-Bold", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)

                SourcePickerCard(
                    icon: "link",
                    title: "En ligne",
                    subtitle: "Colle un lien produit — on récupère tout automatiquement",
                    accentColor: Color(red: 140/255, green: 80/255, blue: 220/255)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) { mode = .online }
                }

                SourcePickerCard(
                    icon: "camera.fill",
                    title: "Depuis mes affaires",
                    subtitle: "Photo + saisie manuelle — pour le vintage, le fait main, les cadeaux…",
                    accentColor: Color(red: 60/255, green: 130/255, blue: 220/255)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) { mode = .manual }
                }
            }
            .padding(.horizontal, 24)
            Spacer()
            Spacer()
        }
    }

    // MARK: - Formulaire

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if mode == .online {
                    urlSection
                }
                photoSection
                fieldsSection
                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    // MARK: - Section URL

    private var urlSection: some View {
        VStack(spacing: 8) {
            sectionHeader("SOURCE EN LIGNE")
            GlassInputCard {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(red: 140/255, green: 80/255, blue: 220/255).opacity(0.2))
                                .frame(width: 34, height: 34)
                            Image(systemName: "link")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
                        }
                        TextField("https://zara.com/...", text: $sourceURL)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .tint(Color(red: 180/255, green: 120/255, blue: 255/255))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .frame(maxWidth: .infinity)

                        // Bouton importer / état
                        Group {
                            switch fetchState {
                            case .idle:
                                Button { Task { await fetchProduct() } } label: {
                                    Text("Importer")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(sourceURL.isEmpty
                                                         ? .white.opacity(0.25)
                                                         : Color(red: 180/255, green: 120/255, blue: 255/255))
                                }
                                .disabled(sourceURL.isEmpty)
                            case .loading:
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            case .success:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 18))
                            case .error:
                                Button { Task { await fetchProduct() } } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .frame(width: 64, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    // Message d'état
                    if case .error(let msg) = fetchState {
                        Rectangle()
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 1)
                            .padding(.leading, 52)
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            Text(msg)
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.orange.opacity(0.9))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }

                    if case .success = fetchState {
                        Rectangle()
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 1)
                            .padding(.leading, 52)
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                            Text("Informations importées — vérifie et complète si besoin")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.green.opacity(0.9))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }

    // MARK: - Photo

    private var photoSection: some View {
        Button { isShowingPhotoPicker = true } label: {
            ZStack {
                if let data = photoData, let img = UIImage(data: data) {
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
                                Text("Ajouter une photo")
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
            sectionHeader("IDENTITÉ")
            GlassInputCard {
                AddFieldRow(icon: "tag.fill", placeholder: "Nom du vêtement *", text: $title)
                addDivider
                AddFieldRow(icon: "building.2.fill", placeholder: "Marque", text: $brand)
            }

            sectionHeader("CATÉGORIE")
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
                    .font(.system(size: 15))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            sectionHeader("TAILLE")
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(size == s ? Color.clear : Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }

            sectionHeader("ASPECT")
            GlassInputCard {
                AddFieldRow(icon: "paintpalette.fill", placeholder: "Couleur", text: $color)
                addDivider
                AddFieldRow(icon: "leaf.fill", placeholder: "Matière (ex: 100% Coton)", text: $material)
                if !isShoe {
                    addDivider
                    AddPickerRow(icon: "figure.stand", label: "Coupe", selection: $fit, options: fits)
                }
            }

            sectionHeader("STYLE & SAISON")
            GlassInputCard {
                AddPickerRow(icon: "tag.fill", label: "Style", selection: $style, options: styles)
                addDivider
                AddPickerRow(icon: "calendar", label: "Saison", selection: $season, options: seasons)
            }

            sectionHeader("ÉTAT & PRIX")
            GlassInputCard {
                etatPicker
                addDivider
                AddFieldRow(icon: "eurosign.circle.fill", placeholder: "Prix payé (€)", text: $price)
            }

            sectionHeader("NOTES")
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

    // MARK: - Fetch & prefill

    @MainActor
    private func fetchProduct() async {
        guard !sourceURL.isEmpty else { return }
        fetchState = .loading
        do {
            let info = try await ProductFetchService.shared.fetch(urlString: sourceURL)
            prefill(from: info)

            // Télécharger l'image en arrière-plan
            if let imgURL = info.imageURL {
                Task {
                    if let data = await ProductFetchService.shared.downloadImage(from: imgURL) {
                        photoData = data
                    }
                }
            }
            fetchState = .success
        } catch {
            fetchState = .error(error.localizedDescription)
        }
    }

    private func prefill(from info: ProductInfo) {
        if !info.title.isEmpty    { title    = info.title }
        if !info.brand.isEmpty    { brand    = info.brand }
        if !info.color.isEmpty    { color    = info.color }
        if !info.material.isEmpty { material = info.material }
        if !info.price.isEmpty    { price    = info.price }
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

    private var addDivider: some View {
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

    private func createItem() {
        let newItem = DressingItem(context: context)
        newItem.id             = UUID()
        newItem.title          = title
        newItem.category       = category
        newItem.size           = size
        newItem.color          = color
        newItem.brand          = brand
        newItem.material       = material.isEmpty ? nil : material
        newItem.fit            = fit.isEmpty ? nil : fit
        newItem.season         = season
        newItem.style          = style.isEmpty ? nil : style
        newItem.price          = price.isEmpty ? nil : price
        newItem.image          = photoData
        newItem.dotClass       = dotClass.rawValue
        newItem.additionalInfo = additionalInfo
        newItem.sourceURL      = (mode == .online && !sourceURL.isEmpty) ? sourceURL : nil
        CoreDataController.shared.save()
        isPresented = false
    }
}

// MARK: - SourcePickerCard

private struct SourcePickerCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accentColor.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(accentColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - GlassInputCard

struct GlassInputCard<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - AddFieldRow

struct AddFieldRow: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(red: 140/255, green: 80/255, blue: 220/255).opacity(0.2))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
            }
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(Color(red: 180/255, green: 120/255, blue: 255/255))
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - AddPickerRow

struct AddPickerRow: View {
    let icon: String
    let label: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(red: 140/255, green: 80/255, blue: 220/255).opacity(0.2))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
            }
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .layoutPriority(1)
            Spacer()
            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { opt in
                    Text(opt.isEmpty ? "—" : opt).tag(opt)
                }
            }
            .pickerStyle(.menu)
            .tint(Color(red: 180/255, green: 120/255, blue: 255/255))
            .frame(maxWidth: 200)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - AddMultilineRow

struct AddMultilineRow: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(red: 140/255, green: 80/255, blue: 220/255).opacity(0.2))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
            }
            .padding(.top, 2)
            TextField(placeholder, text: $text, axis: .vertical)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(Color(red: 180/255, green: 120/255, blue: 255/255))
                .lineLimit(3...6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Composants legacy

struct SegmentedSizePicker: View {
    @Binding var selectedSize: String
    var sizes: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(sizes, id: \.self) { size in
                    Text(size)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(selectedSize == size ? .black : .white)
                        .frame(width: 52, height: 48)
                        .background(RoundedRectangle(cornerRadius: 12)
                            .fill(selectedSize == size ? Color.white : Color.white.opacity(0.15)))
                        .onTapGesture { selectedSize = size }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 64)
    }
}

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.leading, 14)
            }
            if isMultiline {
                TextEditor(text: $text)
                    .frame(minHeight: 40, maxHeight: 150)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
            } else {
                TextField("", text: $text)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
                    .foregroundColor(.white)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
}
