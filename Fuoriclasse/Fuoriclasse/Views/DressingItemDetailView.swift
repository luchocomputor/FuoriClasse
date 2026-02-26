import SwiftUI

struct DressingItemDetailView: View {
    var item: DressingItem
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit     = false
    @State private var showDeleteAlert = false
    @State private var wearCount: Int32 = 0
    @State private var lastWorn: Date?  = nil

    // 3D mesh
    @State private var meshURL:       URL?    = nil   // URL locale du .glb
    @State private var isGenerating:  Bool   = false
    @State private var meshError:     String? = nil
    @State private var showPhoto:     Bool   = false  // toggle 3D ↔ photo

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                imageHeader
                contentSection
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            wearCount = item.wearCount
            lastWorn  = item.lastWorn
            meshURL = Mesh3DService.shared.localMeshURL(for: item.id)
        }
        .sheet(isPresented: $showingEdit) {
            DressingItemEditView(isPresented: $showingEdit, item: item)
        }
        .alert("Supprimer ?", isPresented: $showDeleteAlert) {
            Button("Supprimer", role: .destructive) { deleteItem() }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Cette pièce sera supprimée définitivement.")
        }
    }

    // MARK: - Journal de port

    private var wearCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                // Stats (si déjà porté)
                if wearCount > 0 {
                    HStack(spacing: 0) {
                        wearStat(value: "\(wearCount)", label: "ports")
                        wearStatSeparator
                        wearStat(value: lastWornText, label: "dernier port")
                        if let cpp = costPerWear {
                            wearStatSeparator
                            wearStat(value: cpp, label: "par port")
                        }
                    }
                    .padding(.vertical, 14)

                    Rectangle()
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 1)
                }

                // Bouton CTA
                Button { logWear() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: wornToday ? "checkmark.circle.fill" : "tshirt.fill")
                            .font(.system(size: 15))
                        Text(wornToday ? "Porté aujourd'hui" : "Porter aujourd'hui")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(wornToday ? .white.opacity(0.35) : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .disabled(wornToday)
            }
        }
    }

    private func wearStat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.custom("Futura-Bold", size: 18))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
    }

    private var wearStatSeparator: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1, height: 28)
    }

    private var wornToday: Bool {
        guard let last = lastWorn else { return false }
        return Calendar.current.isDateInToday(last)
    }

    private var lastWornText: String {
        guard let date = lastWorn else { return "Jamais" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        switch days {
        case 0:  return "Aujourd'hui"
        case 1:  return "Hier"
        default: return "Il y a \(days)j"
        }
    }

    private var costPerWear: String? {
        guard wearCount > 0,
              let priceStr = item.price,
              let p = Double(priceStr.replacingOccurrences(of: ",", with: "."))
        else { return nil }
        return String(format: "%.2f €", p / Double(wearCount))
    }

    private func logWear() {
        item.wearCount += 1
        item.lastWorn   = Date()
        wearCount = item.wearCount
        lastWorn  = item.lastWorn
        CoreDataController.shared.save()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - Image / 3D header

    private var imageHeader: some View {
        ZStack(alignment: .bottom) {
            // ── Contenu principal (3D ou photo)
            Group {
                if let url = meshURL, !showPhoto {
                    // Viewer 3D
                    Model3DView(fileURL: url)
                        .frame(maxWidth: .infinity)
                        .frame(height: 360)
                        .overlay(alignment: .topTrailing) {
                            // Toggle → voir la photo
                            Button { showPhoto = true } label: {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(10)
                                    .background(Circle().fill(Color.black.opacity(0.45)))
                            }
                            .padding(16)
                        }
                        .overlay(alignment: .bottom) {
                            Text("Glisser pour tourner")
                                .font(.system(size: 11, weight: .light))
                                .foregroundColor(.white.opacity(0.35))
                                .padding(.bottom, 48)
                        }
                } else {
                    // Photo ou placeholder
                    photoView
                        .overlay(alignment: .topTrailing) {
                            // Toggle → voir le 3D (si mesh dispo)
                            if meshURL != nil {
                                Button { showPhoto = false } label: {
                                    Image(systemName: "cube.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(10)
                                        .background(Circle().fill(Color.black.opacity(0.45)))
                                }
                                .padding(16)
                            }
                        }
                }
            }

            // ── Gradient bas
            LinearGradient(
                colors: [.clear, Color(red: 15/255, green: 5/255, blue: 40/255).opacity(0.85)],
                startPoint: .center, endPoint: .bottom
            )
            .frame(height: 160)
            .allowsHitTesting(false)

            // ── CTA génération (masqué quand 3D déjà affiché)
            if meshURL == nil || showPhoto {
                meshGenerateOverlay
                    .padding(.bottom, 16)
            }
        }
    }

    // Photo ou placeholder catégorie
    private var photoView: some View {
        Group {
            if let data = item.image, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 360)
                    .clipped()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 60/255, green: 20/255, blue: 120/255),
                                 Color(red: 25/255, green: 8/255, blue: 60/255)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    VStack(spacing: 12) {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 56))
                            .foregroundColor(.white.opacity(0.18))
                        Text(item.category.isEmpty ? "Vêtement" : item.category)
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 360)
            }
        }
    }

    // Overlay bas du header : génération / chargement / erreur
    @ViewBuilder
    private var meshGenerateOverlay: some View {
        if isGenerating {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.85)
                Text("Génération 3D en cours…")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.black.opacity(0.55)))

        } else if let err = meshError {
            VStack(spacing: 6) {
                Text(err)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.orange.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                Button { Task { await generateMesh() } } label: {
                    Text("Réessayer")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.orange.opacity(0.6)))
                }
            }
        } else if item.image != nil {
            Button { Task { await generateMesh() } } label: {
                HStack(spacing: 8) {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 15))
                    Text("Générer en 3D")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(red: 100/255, green: 50/255, blue: 180/255).opacity(0.75))
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Génération 3D

    @MainActor
    private func generateMesh() async {
        guard let imageData = item.image else {
            meshError = "Ajoute d'abord une photo à cette pièce"
            return
        }
        isGenerating = true
        meshError    = nil
        showPhoto    = false
        do {
            let url  = try await Mesh3DService.shared.generate(imageData: imageData, itemID: item.id)
            meshURL  = url
        } catch {
            meshError = error.localizedDescription
        }
        isGenerating = false
    }

    // MARK: - Contenu

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Titre + marque + chips
            titleBlock

            // Journal de port
            wearCard

            // Caractéristiques
            charactCard

            // Style & saison
            if hasStyleOrSeason {
                styleCard
            }

            // Prix
            if let price = item.price, !price.isEmpty {
                priceBlock(price)
            }

            // Notes
            if !item.additionalInfo.isEmpty {
                notesCard
            }

            // Boutons d'action
            actionButtons

            Spacer().frame(height: 20)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    // MARK: - Titre block

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title.isEmpty ? "Sans titre" : item.title)
                .font(.custom("Futura-Bold", size: 26))
                .foregroundColor(.white)
                .lineLimit(2)

            HStack(spacing: 8) {
                if !item.brand.isEmpty {
                    Text(item.brand)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                }

                if !item.brand.isEmpty && !item.category.isEmpty {
                    Text("·")
                        .foregroundColor(.white.opacity(0.3))
                }

                if !item.category.isEmpty {
                    categoryChip
                }

                Spacer()

                etatChip
            }
        }
    }

    // MARK: - Caractéristiques

    private var charactCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                let rows: [(icon: String, label: String, value: String)] = infoRows
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    if index > 0 {
                        Rectangle()
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 1)
                            .padding(.leading, 52)
                    }
                    DetailInfoRow(icon: row.icon, label: row.label, value: row.value)
                }
            }
        }
    }

    // MARK: - Style & Saison

    private var styleCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("STYLE & SAISON")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(1.5)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                HStack(spacing: 8) {
                    if let style = item.style, !style.isEmpty {
                        StyleChip(icon: "tag.fill", label: style, color: Color(red: 140/255, green: 80/255, blue: 220/255))
                    }
                    if let season = item.season, !season.isEmpty {
                        StyleChip(icon: seasonIcon(for: item.season ?? ""), label: season, color: Color(red: 60/255, green: 140/255, blue: 220/255))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }

    // MARK: - Prix

    private func priceBlock(_ price: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(red: 80/255, green: 180/255, blue: 100/255).opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: "eurosign.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 80/255, green: 200/255, blue: 110/255))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("PRIX PAYÉ")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(1.2)
                Text(price.hasSuffix("€") ? price : "\(price) €")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Notes

    private var notesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("NOTES")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(1.5)
                Text(item.additionalInfo)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(4)
            }
            .padding(16)
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button { showingEdit = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Modifier")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 120/255, green: 60/255, blue: 200/255).opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
            }

            Button { showDeleteAlert = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Supprimer")
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
        }
        .padding(.top, 4)
    }

    // MARK: - Chips

    private var categoryChip: some View {
        Text(item.category)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Color(red: 140/255, green: 80/255, blue: 220/255).opacity(0.2))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(red: 140/255, green: 80/255, blue: 220/255).opacity(0.3), lineWidth: 1))
    }

    private var etatChip: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(etatColor)
                .frame(width: 7, height: 7)
            Text(etatLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(etatColor.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Helpers

    private var infoRows: [(icon: String, label: String, value: String)] {
        var rows: [(icon: String, label: String, value: String)] = []
        if !item.size.isEmpty     { rows.append(("ruler", "Taille", item.size)) }
        if !item.color.isEmpty    { rows.append(("paintpalette.fill", "Couleur", item.color)) }
        if let m = item.material, !m.isEmpty { rows.append(("leaf.fill", "Matière", m)) }
        if let f = item.fit, !f.isEmpty      { rows.append(("figure.stand", "Coupe", f)) }
        return rows
    }

    private var hasStyleOrSeason: Bool {
        let s = item.style ?? ""
        let ss = item.season ?? ""
        return !s.isEmpty || !ss.isEmpty
    }

    private var etatLabel: String {
        switch item.dotClassEnum {
        case .green:  return "Neuf"
        case .orange: return "Bon état"
        case .red:    return "Usé"
        }
    }

    private var etatColor: Color {
        switch item.dotClassEnum {
        case .green:  return Color(red: 80/255, green: 210/255, blue: 110/255)
        case .orange: return Color(red: 255/255, green: 165/255, blue: 50/255)
        case .red:    return Color(red: 255/255, green: 80/255, blue: 80/255)
        }
    }

    private var categoryIcon: String {
        switch item.category.lowercased() {
        case "chaussures": return "shoe.fill"
        case "manteau", "veste": return "cloud.rain.fill"
        case "robe": return "sparkles"
        default: return "hanger"
        }
    }

    private func seasonIcon(for season: String) -> String {
        switch season.lowercased() {
        case let s where s.contains("hiver"): return "snowflake"
        case let s where s.contains("été"):   return "sun.max.fill"
        case let s where s.contains("automne"): return "leaf.fill"
        case let s where s.contains("printemps"): return "cloud.sun.fill"
        default: return "calendar"
        }
    }

    private func deleteItem() {
        withAnimation {
            CoreDataController.shared.delete(item)
            dismiss()
        }
    }
}

// MARK: - DetailInfoRow

struct DetailInfoRow: View {
    let icon: String
    let label: String
    let value: String

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
            VStack(alignment: .leading, spacing: 1) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(1)
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}

// MARK: - StyleChip

struct StyleChip: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(label)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - CustomTextField2 (conservé pour compatibilité)
struct CustomTextField2: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(10)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
    }
}
