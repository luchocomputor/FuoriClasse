import SwiftUI

struct DressingItemCard: View {
    var item: DressingItem

    private var etatColor: Color {
        switch item.dotClassEnum {
        case .green:  return Color(red: 80/255, green: 210/255, blue: 110/255)
        case .orange: return Color(red: 255/255, green: 165/255, blue: 50/255)
        case .red:    return Color(red: 255/255, green: 80/255, blue: 80/255)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Miniature
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
                        .foregroundColor(.white.opacity(0.25))
                }
            }
            .frame(width: 62, height: 74)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Détails
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title.isEmpty ? "Sans titre" : item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if !item.brand.isEmpty {
                        Text(item.brand)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                    if !item.category.isEmpty {
                        Text(item.category)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 140/255, green: 80/255, blue: 220/255).opacity(0.18))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 6) {
                    if !item.size.isEmpty {
                        Text("Taille \(item.size)")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    if item.wearCount > 0 {
                        Text("· \(item.wearCount) port\(item.wearCount > 1 ? "s" : "")")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255).opacity(0.6))
                    }
                }
            }

            Spacer(minLength: 0)

            // État
            Circle()
                .fill(etatColor)
                .frame(width: 9, height: 9)
                .shadow(color: etatColor.opacity(0.6), radius: 3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}
