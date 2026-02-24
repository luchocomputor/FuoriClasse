import SwiftUI
import CoreData

// MARK: - StyleAdvisorView

struct StyleAdvisorView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DressingItem.title, ascending: true)],
        animation: .none
    )
    private var wardrobe: FetchedResults<DressingItem>

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var selectedImageData: Data? = nil
    @State private var isLoading: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var errorMessage: String? = nil
    @FocusState private var isInputFocused: Bool

    private var wardrobeContext: String {
        wardrobe.map { "- \($0.title) (\($0.category), \($0.color), taille \($0.size), \($0.brand))" }
            .joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // — Background —
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 40/255, green: 10/255, blue: 90/255),
                        Color(red: 15/255, green: 5/255, blue: 40/255)
                    ]),
                    center: .center,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()
                FluidBackgroundView().ignoresSafeArea()

                // — Messages —
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            if messages.isEmpty {
                                emptyStateView
                            }
                            ForEach(messages) { msg in
                                MessageBubble(message: msg)
                                    .id(msg.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: msg.role == .user ? .trailing : .leading)
                                            .combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            if isLoading {
                                loadingBubble
                                    .id("loading")
                                    .transition(.move(edge: .leading).combined(with: .opacity))
                            }
                            if let err = errorMessage {
                                Text(err)
                                    .font(.caption)
                                    .foregroundColor(.red.opacity(0.9))
                                    .padding(.horizontal, 20).padding(.vertical, 8)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(10)
                                    .padding(.horizontal, 20)
                            }
                            Color.clear.frame(height: 8).id("bottom")
                        }
                        .padding(.top, 16)
                        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: messages.count)
                        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isLoading)
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .onTapGesture { isInputFocused = false }
                    .onChange(of: messages.count) { _ in
                        withAnimation(.spring(response: 0.3)) { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                    .onChange(of: isLoading) { _ in
                        withAnimation(.spring(response: 0.3)) { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                }
            }
            // ← clé : l'input bar reste collée au-dessus du clavier
            .safeAreaInset(edge: .bottom, spacing: 0) {
                inputBar
            }
            .navigationTitle("Conseiller Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(photoData: $selectedImageData)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 22) {
            Spacer().frame(height: 50)

            // Icône avec halo
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.purple.opacity(0.5), .clear],
                        center: .center, startRadius: 10, endRadius: 60
                    ))
                    .frame(width: 110, height: 110)
                    .blur(radius: 14)

                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(LinearGradient(
                        colors: [.white, Color(red: 200/255, green: 150/255, blue: 255/255)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
            }

            // Titre + sous-titre
            VStack(spacing: 6) {
                Text("Fuoriclasse")
                    .font(.custom("Futura-Bold", size: 24))
                    .foregroundStyle(LinearGradient(
                        colors: [.white, Color(red: 210/255, green: 170/255, blue: 255/255)],
                        startPoint: .leading, endPoint: .trailing
                    ))

                Text("STYLISTE PERSONNEL")
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(2.5)
            }

            // Séparateur
            HStack {
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                Image(systemName: "sparkle")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.25))
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
            }
            .padding(.horizontal, 50)

            // Description
            Text("Posez une question sur votre dressing,\ndemandez une tenue complète\nou envoyez une photo.")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 36)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
    }

    // MARK: - Loading Bubble

    private var loadingBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            assistantAvatar
            TypingIndicator()
                .padding(.horizontal, 18).padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 16)
    }

    private var assistantAvatar: some View {
        Circle()
            .fill(LinearGradient(
                colors: [Color(red: 130/255, green: 70/255, blue: 210/255),
                         Color(red: 60/255, green: 20/255, blue: 120/255)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .frame(width: 28, height: 28)
            .overlay(Image(systemName: "sparkles").font(.system(size: 11)).foregroundColor(.white))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 8) {
            // Aperçu photo
            if let data = selectedImageData, let img = UIImage(data: data) {
                HStack(spacing: 10) {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1))
                    Text("Photo jointe")
                        .font(.caption).foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Button { withAnimation(.spring()) { selectedImageData = nil } } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3).foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Capsule de saisie flottante
            HStack(spacing: 10) {
                Button { showPhotoPicker = true } label: {
                    Image(systemName: selectedImageData != nil ? "photo.fill" : "photo")
                        .font(.system(size: 18))
                        .foregroundStyle(selectedImageData != nil
                            ? LinearGradient(colors: [Color(red: 190/255, green: 130/255, blue: 255/255), .purple],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.4)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 34, height: 34)
                }

                TextField("Message…", text: $inputText, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(.white)
                    .tint(Color(red: 180/255, green: 120/255, blue: 255/255))
                    .focused($isInputFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Fermer") { isInputFocused = false }
                                .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
                                .fontWeight(.medium)
                        }
                    }

                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(canSend
                                ? LinearGradient(
                                    colors: [Color(red: 150/255, green: 90/255, blue: 230/255),
                                             Color(red: 80/255, green: 30/255, blue: 160/255)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [.white.opacity(0.07), .white.opacity(0.07)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 34, height: 34)
                            .shadow(color: canSend ? Color.purple.opacity(0.4) : .clear, radius: 6, x: 0, y: 2)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(canSend ? .white : .white.opacity(0.2))
                    }
                    .animation(.spring(response: 0.3), value: canSend)
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 4)
            )
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 10)
    }

    private var canSend: Bool {
        (!inputText.trimmingCharacters(in: .whitespaces).isEmpty || selectedImageData != nil) && !isLoading
    }

    // MARK: - Send

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty || selectedImageData != nil else { return }

        let userMsg = ChatMessage(role: .user, text: text, imageData: selectedImageData)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            messages.append(userMsg)
        }

        let capturedImage = selectedImageData
        inputText = ""
        selectedImageData = nil
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let reply = try await GeminiService.shared.send(
                    messages: messages,
                    wardrobeContext: wardrobeContext,
                    imageData: capturedImage
                )
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        messages.append(ChatMessage(role: .assistant, text: reply, imageData: nil))
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur : \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
    let message: ChatMessage
    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser {
                Spacer(minLength: 55)
            } else {
                assistantBadge
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                if let data = message.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable().scaledToFit()
                        .frame(maxWidth: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1))
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .padding(.horizontal, 14).padding(.vertical, 11)
                        .background(bubbleFill)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(isUser ? 0.18 : 0.08), lineWidth: 1)
                        )
                }
            }

            if !isUser {
                Spacer(minLength: 55)
            } else {
                userBadge
            }
        }
        .padding(.horizontal, 14)
    }

    @ViewBuilder
    private var bubbleFill: some View {
        if isUser {
            LinearGradient(
                colors: [Color(red: 110/255, green: 55/255, blue: 195/255).opacity(0.85),
                         Color(red: 65/255, green: 22/255, blue: 130/255).opacity(0.75)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        } else {
            Color.white.opacity(0.07)
        }
    }

    private var assistantBadge: some View {
        Circle()
            .fill(LinearGradient(
                colors: [Color(red: 130/255, green: 70/255, blue: 210/255),
                         Color(red: 60/255, green: 20/255, blue: 120/255)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .frame(width: 28, height: 28)
            .overlay(Image(systemName: "sparkles").font(.system(size: 11)).foregroundColor(.white))
    }

    private var userBadge: some View {
        Circle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 28, height: 28)
            .overlay(Image(systemName: "person.fill").font(.system(size: 13)).foregroundColor(.white.opacity(0.65)))
    }
}

// MARK: - TypingIndicator

struct TypingIndicator: View {
    @State private var active = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.white.opacity(0.75))
                    .frame(width: 6, height: 6)
                    .scaleEffect(active ? 1.0 : 0.45)
                    .opacity(active ? 1.0 : 0.25)
                    .animation(
                        .easeInOut(duration: 0.55)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.18),
                        value: active
                    )
            }
        }
        .onAppear { active = true }
    }
}
