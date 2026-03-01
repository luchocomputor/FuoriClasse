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
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            messages = []
                            inputText = ""
                            selectedImageData = nil
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(red: 130/255, green: 70/255, blue: 210/255),
                                             Color(red: 60/255, green: 20/255, blue: 120/255)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 38, height: 38)
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fuoriclasse")
                            .font(.custom("Futura-Bold", size: 22))
                            .foregroundStyle(LinearGradient(
                                colors: [.white, Color(red: 210/255, green: 170/255, blue: 255/255)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                        Text("PERSONAL STYLIST")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.35))
                            .tracking(1.8)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 8)

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
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isInputFocused = false }
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
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if messages.isEmpty {
                            emptyState
                                .frame(minHeight: geo.size.height - 24)
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
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("What can I help you with?")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.white.opacity(0.35))
                .padding(.bottom, 14)

            VStack(spacing: 10) {
                promptRow(
                    left:  (icon: "figure.run",  title: "Sport tomorrow",  subtitle: "What should I wear?",    prompt: "I have a workout tomorrow morning — how should I dress using my wardrobe?"),
                    right: (icon: "heart",        title: "Upcoming date",   subtitle: "Outfit for the occasion", prompt: "I have a date tonight. What outfit would you recommend from my wardrobe?")
                )
                promptRow(
                    left:  (icon: "building.2",  title: "Office look",     subtitle: "Professional style",      prompt: "I need to go to the office tomorrow. Build me a professional look from my wardrobe."),
                    right: (icon: "sun.max",      title: "Weekend",         subtitle: "Casual & comfortable",    prompt: "It's the weekend and I want a relaxed, comfortable look. What do you suggest from my wardrobe?")
                )
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
    }

    // Ligne de deux cards égales en hauteur
    private func promptRow(
        left:  (icon: String, title: String, subtitle: String, prompt: String),
        right: (icon: String, title: String, subtitle: String, prompt: String)
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            promptCard(icon: left.icon,  title: left.title,  subtitle: left.subtitle,  prompt: left.prompt)
                .frame(maxHeight: .infinity)
            promptCard(icon: right.icon, title: right.title, subtitle: right.subtitle, prompt: right.prompt)
                .frame(maxHeight: .infinity)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func promptCard(icon: String, title: String, subtitle: String, prompt: String) -> some View {
        Button {
            inputText = prompt
            sendMessage()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Icône
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(red: 100/255, green: 45/255, blue: 180/255).opacity(0.30))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color(red: 190/255, green: 135/255, blue: 255/255))
                }

                // Texte
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.white.opacity(0.48))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.11), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
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

    // MARK: - Barre de saisie

    private var inputBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            // Aperçu photo jointe
            if let data = selectedImageData, let img = UIImage(data: data) {
                HStack(spacing: 12) {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    Text("Photo attached")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedImageData = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3), value: selectedImageData != nil)
            }

            // Ligne principale
            HStack(alignment: .bottom, spacing: 10) {
                // Bouton photo
                Button { showPhotoPicker = true } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(selectedImageData != nil ? 0.14 : 0.08))
                            .frame(width: 44, height: 44)
                        Image(systemName: selectedImageData != nil ? "photo.fill" : "photo")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(selectedImageData != nil
                                ? Color(red: 180/255, green: 120/255, blue: 255/255)
                                : .white.opacity(0.45))
                    }
                }
                .buttonStyle(.plain)

                // Champ de texte
                TextField("Message...", text: $inputText, axis: .vertical)
                    .focused($isInputFocused)
                    .lineLimit(1...6)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .tint(Color(red: 180/255, green: 120/255, blue: 255/255))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.09))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                    )

                // Bouton envoi
                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(canSend
                                ? Color(red: 120/255, green: 60/255, blue: 200/255)
                                : Color.white.opacity(0.08))
                            .frame(width: 44, height: 44)
                            .shadow(
                                color: Color(red: 120/255, green: 60/255, blue: 200/255).opacity(canSend ? 0.45 : 0),
                                radius: 10, x: 0, y: 4
                            )
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(canSend ? .white : .white.opacity(0.18))
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .animation(.spring(response: 0.25), value: canSend)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(Color(red: 15/255, green: 5/255, blue: 38/255))
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
