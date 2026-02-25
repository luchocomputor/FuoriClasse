import SwiftUI

struct OutfitCard: View {
    let outfit: Outfit

    var body: some View {
        HStack(spacing: 14) {
            thumbnailRow

            VStack(alignment: .leading, spacing: 5) {
                Text(outfit.title ?? "Sans titre")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let style = outfit.style, !style.isEmpty {
                        outfitChip(style, color: Color(red: 140/255, green: 80/255, blue: 220/255))
                    }
                    if let season = outfit.season, !season.isEmpty {
                        outfitChip(season, color: Color(red: 60/255, green: 140/255, blue: 220/255))
                    }
                }

                let count = outfit.itemsArray.count
                Text("\(count) pièce\(count > 1 ? "s" : "")")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.white.opacity(0.35))
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.25))
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

    private var thumbnailRow: some View {
        HStack(spacing: 4) {
            let first3 = Array(outfit.itemsArray.prefix(3))
            if first3.isEmpty {
                itemThumb(data: nil)
            } else {
                ForEach(Array(first3.enumerated()), id: \.offset) { _, item in
                    itemThumb(data: item.image)
                }
            }
        }
    }

    private func itemThumb(data: Data?) -> some View {
        ZStack {
            if let data, let img = UIImage(data: data) {
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
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.25))
            }
        }
        .frame(width: 42, height: 52)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func outfitChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.18))
            .clipShape(Capsule())
    }
}
