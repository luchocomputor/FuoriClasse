import SwiftUI

struct SocialPostCard: View {
    let feedPost: FeedPost
    let onLikeTap: () -> Void
    let onUsernameTap: () -> Void

    private var dateText: String {
        guard let date = ISO8601DateFormatter().date(from: feedPost.post.createdAt) else {
            return feedPost.post.createdAt
        }
        if Calendar.current.isDateInToday(date) { return "aujourd'hui" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }

    private var initials: String {
        let name = feedPost.authorUsername
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(red: 120/255, green: 60/255, blue: 200/255))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(initials)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    )

                Button(action: onUsernameTap) {
                    Text("@\(feedPost.authorUsername)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Text("·")
                    .foregroundColor(.white.opacity(0.4))

                Text(dateText)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()
            }

            // Thumbnails
            if !feedPost.post.imageUrls.isEmpty {
                HStack(spacing: 8) {
                    ForEach(feedPost.post.imageUrls.prefix(3), id: \.self) { urlString in
                        AsyncImage(url: URL(string: urlString)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 80)
                                    .clipped()
                                    .cornerRadius(10)
                            default:
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(width: 60, height: 80)
                                    .overlay(
                                        Image(systemName: "hanger")
                                            .foregroundColor(.white.opacity(0.3))
                                    )
                            }
                        }
                    }
                    Spacer()
                }
            }

            // Outfit title
            if let title = feedPost.post.outfitTitle, !title.isEmpty {
                Text(title)
                    .font(.custom("Futura-Bold", size: 15))
                    .foregroundColor(.white)
            }

            // Notes
            if let notes = feedPost.post.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(3)
            }

            // Like button
            Button(action: onLikeTap) {
                HStack(spacing: 5) {
                    Image(systemName: feedPost.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(feedPost.isLiked ? .red : .white.opacity(0.4))
                        .font(.system(size: 16))
                    Text("\(feedPost.likesCount)")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.09), lineWidth: 1)
                )
        )
    }
}
