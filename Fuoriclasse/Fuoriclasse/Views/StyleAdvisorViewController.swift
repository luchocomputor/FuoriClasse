import SwiftUI
import CoreData

struct StyleAdvisorView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DressingItem.title, ascending: true)],
        animation: .none
    )
    private var wardrobe: FetchedResults<DressingItem>

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var selectedImageData: Data? = nil
    @State private var isLoading = false
    @State private var showPhotoPicker = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @FocusState private var isInputFocused: Bool

    private var wardrobeContext: String {
        wardrobe.map { "- \($0.title) (\($0.category), \($0.color), taille \($0.size), \($0.brand))" }
            .joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            // Le ZStack met le background en couche basse.
            // Le VStack (messages + inputBar) occupe tout l'espace disponible
            // et remonte naturellement quand le clavier apparaît.
            VStack(spacing: 0) {
                messagesList
                inputBar
            }
            .overlay(alignment: .top) {
                if showError, let msg = errorMessage {
                    ErrorToast(message: msg)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
            // Le fond est en .background pour NE PAS affecter
            // le layout du VStack — celui-ci reste dans la safe area
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
            .navigationTitle("Conseiller Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            // Bouton "Fermer" au-dessus du clavier — doit être ici,
            // pas sur le TextField, pour fonctionner dans un NavigationStack
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fermer") { isInputFocused = false }
                        .foregroundColor(Color(red: 180/255, green: 120/255, blue: 255/255))
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(photoData: $selectedImageData)
            }
        }
    }

    // MARK: - Liste des messages

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if messages.isEmpty {
                        emptyState
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
                        loadingBubble.id("loading")
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, 12)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: messages.count)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isLoading)
            }
            // Swipe vers le bas ferme le clavier
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: isLoading) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    // MARK: - État vide

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)

            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.purple.opacity(0.5), .clear],
                        center: .center, startRadius: 10, endRadius: 55
                    ))
                    .frame(width: 100, height: 100)
                    .blur(radius: 12)
                Image(systemName: "sparkles")
                    .font(.system(size: 46, weight: .thin))
                    .foregroundStyle(LinearGradient(
                        colors: [.white, Color(red: 200/255, green: 150/255, blue: 255/255)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
            }

            VStack(spacing: 5) {
                Text("Fuoriclasse")
                    .font(.custom("Futura-Bold", size: 24))
                    .foregroundStyle(LinearGradient(
                        colors: [.white, Color(red: 210/255, green: 170/255, blue: 255/255)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                Text("STYLISTE PERSONNEL")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(2.5)
            }

            HStack {
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                Image(systemName: "sparkle").font(.system(size: 9)).foregroundColor(.white.opacity(0.2))
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
            }
            .padding(.horizontal, 50)

            Text("Posez une question sur votre dressing,\ndemandez une tenue ou envoyez une photo.")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 36)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
    }

    // MARK: - Indicateur de frappe

    private var loadingBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            avatarAssistant
            TypingIndicator()
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var avatarAssistant: some View {
        Circle()
            .fill(LinearGradient(
                colors: [Color(red: 130/255, green: 70/255, blue: 210/255),
                         Color(red: 60/255, green: 20/255, blue: 120/255)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .frame(width: 26, height: 26)
            .overlay(Image(systemName: "sparkles").font(.system(size: 10)).foregroundColor(.white))
    }

    // MARK: - Barre de saisie (style Claude / Gemini)

    private var inputBar: some View {
        VStack(spacing: 0) {
            // Ligne de séparation nette
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            VStack(spacing: 8) {
                // Aperçu photo si sélectionnée
                if let data = selectedImageData, let img = UIImage(data: data) {
                    HStack(spacing: 10) {
                        Image(uiImage: img)
                            .resizable().scaledToFill()
                            .frame(width: 42, height: 42)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text("Photo jointe")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.3)) { selectedImageData = nil }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Ligne principale : bouton photo + champ + bouton envoi
                HStack(alignment: .bottom, spacing: 10) {
                    // Bouton photo
                    Button { showPhotoPicker = true } label: {
                        Image(systemName: selectedImageData != nil ? "photo.fill" : "photo")
                            .font(.system(size: 20))
                            .foregroundColor(selectedImageData != nil
                                ? Color(red: 180/255, green: 120/255, blue: 255/255)
                                : .white.opacity(0.5))
                            .frame(width: 36, height: 36)
                    }

                    // Champ de texte avec fond gris — même pattern que Claude/Gemini
                    HStack(alignment: .bottom, spacing: 6) {
                        TextField("Message…", text: $inputText, axis: .vertical)
                            .focused($isInputFocused)
                            .lineLimit(1...6)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .tint(Color(red: 180/255, green: 120/255, blue: 255/255))

                        // Bouton envoi à l'intérieur du champ (iMessage / Claude style)
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(canSend
                                    ? Color(red: 160/255, green: 100/255, blue: 240/255)
                                    : .white.opacity(0.2))
                        }
                        .disabled(!canSend)
                        .animation(.spring(response: 0.25), value: canSend)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .padding(.top, 8)
            }
        }
        // Fond solide et opaque — toujours visible
        .background(Color(red: 18/255, green: 6/255, blue: 40/255))
    }

    private var canSend: Bool {
        (!inputText.trimmingCharacters(in: .whitespaces).isEmpty || selectedImageData != nil) && !isLoading
    }

    // MARK: - Envoi

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
                    errorMessage = error.localizedDescription
                    isLoading = false
                    withAnimation(.spring(response: 0.4)) { showError = true }
                    Task {
                        try? await Task.sleep(nanoseconds: 4_000_000_000)
                        withAnimation(.spring(response: 0.4)) { showError = false }
                    }
                }
            }
        }
    }
}

// MARK: - Bulle de message

struct MessageBubble: View {
    let message: ChatMessage
    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser {
                Spacer(minLength: 60)
            } else {
                avatarView
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                if let data = message.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable().scaledToFit()
                        .frame(maxWidth: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .lineSpacing(3)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(isUser
                            ? AnyView(LinearGradient(
                                colors: [Color(red: 110/255, green: 55/255, blue: 195/255),
                                         Color(red: 70/255, green: 25/255, blue: 140/255)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            : AnyView(Color.white.opacity(0.08))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }

            if !isUser {
                Spacer(minLength: 60)
            } else {
                avatarView
            }
        }
        .padding(.horizontal, 14)
    }

    private var avatarView: some View {
        Group {
            if isUser {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 26, height: 26)
                    .overlay(Image(systemName: "person.fill")
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.6)))
            } else {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(red: 130/255, green: 70/255, blue: 210/255),
                                 Color(red: 60/255, green: 20/255, blue: 120/255)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 26, height: 26)
                    .overlay(Image(systemName: "sparkles")
                        .font(.system(size: 10)).foregroundColor(.white))
            }
        }
    }
}

// MARK: - Toast d'erreur

struct ErrorToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red.opacity(0.9))
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(red: 40/255, green: 8/255, blue: 8/255).opacity(0.95))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}

// MARK: - Indicateur de frappe

struct TypingIndicator: View {
    @State private var active = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 6, height: 6)
                    .scaleEffect(active ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                        value: active
                    )
            }
        }
        .onAppear { active = true }
    }
}
