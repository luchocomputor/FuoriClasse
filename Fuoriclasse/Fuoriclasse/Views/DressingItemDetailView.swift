import SwiftUI

struct DressingItemDetailView: View {
    var item: DressingItem
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 0) {
                    imageHeader
                    contentSection
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
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

    // MARK: - Fond

    private var background: some View {
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

    // MARK: - Image header

    private var imageHeader: some View {
        ZStack(alignment: .bottom) {
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

            // Gradient overlay bas de l'image
            LinearGradient(
                colors: [.clear, Color(red: 15/255, green: 5/255, blue: 40/255).opacity(0.85)],
                startPoint: .center, endPoint: .bottom
            )
            .frame(height: 160)
        }
    }

    // MARK: - Contenu

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Titre + marque + chips
            titleBlock

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
