import SwiftUI
import CoreData

struct CreatePostView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let onPosted: () async -> Void

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Outfit.createdAt, ascending: false)],
        animation: .default
    )
    private var outfits: FetchedResults<Outfit>

    @State private var selectedOutfit: Outfit? = nil
    @State private var noteText = ""
    @State private var isPosting = false
    @State private var errorMessage: String? = nil

    private var selectedImages: [Data] {
        guard let outfit = selectedOutfit else { return [] }
        return outfit.itemsArray.prefix(3).compactMap { item -> Data? in
            guard let imageData = item.image else { return nil }
            return compressedJPEG(from: imageData)
        }
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
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Sélecteur de tenue
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tenue portée")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 4)

                            Menu {
                                Button("Sans tenue") { selectedOutfit = nil }
                                ForEach(outfits, id: \.objectID) { outfit in
                                    Button(outfit.title ?? "Sans titre") { selectedOutfit = outfit }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.3.group.fill")
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(selectedOutfit?.title ?? "Sélectionner une tenue")
                                        .font(.system(size: 15))
                                        .foregroundColor(selectedOutfit == nil ? .white.opacity(0.4) : .white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.white.opacity(0.4))
                                        .font(.system(size: 12))
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.07))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.09), lineWidth: 1)
                                        )
                                )
                            }
                        }

                        // Preview thumbnails
                        if let outfit = selectedOutfit, !outfit.itemsArray.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pièces de la tenue")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 4)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(outfit.itemsArray.prefix(3), id: \.objectID) { item in
                                            itemThumbnail(item: item)
                                        }
                                    }
                                }
                            }
                        }

                        // Note
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note (optionnel)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 4)

                            ZStack(alignment: .topLeading) {
                                if noteText.isEmpty {
                                    Text("Ajoute une note...")
                                        .font(.system(size: 15, weight: .light))
                                        .foregroundColor(.white.opacity(0.3))
                                        .padding(14)
                                }
                                TextEditor(text: $noteText)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 100)
                                    .padding(10)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.09), lineWidth: 1)
                                    )
                            )
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red.opacity(0.8))
                                .padding(.horizontal, 4)
                        }

                        // Bouton Publier
                        Button {
                            Task { await publish() }
                        } label: {
                            HStack(spacing: 10) {
                                if isPosting {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Publier")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color(red: 120/255, green: 60/255, blue: 200/255))
                                    .shadow(color: Color(red: 120/255, green: 60/255, blue: 200/255).opacity(0.5),
                                            radius: 12, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isPosting)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Nouveau post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    @ViewBuilder
    private func itemThumbnail(item: DressingItem) -> some View {
        if let data = item.image, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 90)
                .clipped()
                .cornerRadius(10)
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
                .frame(width: 70, height: 90)
                .overlay(
                    Image(systemName: "hanger")
                        .foregroundColor(.white.opacity(0.3))
                )
        }
    }

    private func compressedJPEG(from data: Data) -> Data? {
        guard let uiImage = UIImage(data: data) else { return nil }
        let maxSize: CGFloat = 800
        let scale = min(maxSize / uiImage.size.width, maxSize / uiImage.size.height, 1.0)
        let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in uiImage.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.7)
    }

    private func publish() async {
        guard let userId = auth.session?.user.id else { return }
        isPosting = true
        errorMessage = nil
        defer { isPosting = false }

        do {
            let imageUrls: [String]
            if selectedImages.isEmpty {
                imageUrls = []
            } else {
                imageUrls = try await SocialService.shared.uploadImages(selectedImages)
            }

            try await SocialService.shared.createPost(
                userId: userId,
                outfitTitle: selectedOutfit?.title,
                notes: noteText.isEmpty ? nil : noteText,
                imageUrls: imageUrls
            )

            await onPosted()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
