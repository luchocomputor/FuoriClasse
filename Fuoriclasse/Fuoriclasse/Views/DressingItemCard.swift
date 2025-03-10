import SwiftUI

struct DressingItemCard: View {
    var dto: DressingItemDTO

    var body: some View {
        HStack {
            VStack(alignment: .center, spacing: 5) {
                Text(dto.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(dto.category)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: 300)
        .background(GlassBackgroundView())
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
    }
}
