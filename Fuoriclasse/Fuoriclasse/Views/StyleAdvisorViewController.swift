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

    private var wardrobeContext: String {
        wardrobe.map { item in
            "- \(item.title) (\(item.category), \(item.color), taille \(item.size), \(item.brand))"
        }.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
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

                FluidBackgroundView()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    messagesScrollView
                    inputBar
                }
            }
            .navigationTitle("Conseiller Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(photoData: $selectedImageData)
            }
        }
    }

    // MARK: - Messages

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if messages.isEmpty {
                        emptyStateView
                    }
                    ForEach(messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                    if isLoading {
                        loadingBubble
                    }
                    if let err = errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: isLoading) { _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))
            Text("Bonjour ! Je suis Fuoriclasse,\nvotre styliste personnel.\nPosez-moi une question sur votre dressing.")
                .font(.custom("Futura", size: 15))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    private var loadingBubble: some View {
        HStack {
            TypingIndicator()
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(red: 40/255, green: 10/255, blue: 90/255).opacity(0.6))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                HStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    Button(action: { selectedImageData = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            HStack(spacing: 10) {
                Button(action: { showPhotoPicker = true }) {
                    Image(systemName: selectedImageData != nil ? "photo.fill" : "photo")
                        .font(.title3)
                        .foregroundColor(selectedImageData != nil ? .purple : .white.opacity(0.7))
                        .frame(width: 36, height: 36)
                }

                TextField("Votre question…", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.custom("Futura", size: 15))
                    .foregroundColor(.white)
                    .tint(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(canSend ? .white : .white.opacity(0.3))
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Color(red: 15/255, green: 5/255, blue: 40/255).opacity(0.85)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    private var canSend: Bool {
        (!inputText.trimmingCharacters(in: .whitespaces).isEmpty || selectedImageData != nil) && !isLoading
    }

    // MARK: - Send

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty || selectedImageData != nil else { return }

        let userMsg = ChatMessage(role: .user, text: text, imageData: selectedImageData)
        messages.append(userMsg)

        let capturedImageData = selectedImageData
        inputText = ""
        selectedImageData = nil
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let reply = try await GeminiService.shared.send(
                    messages: messages,
                    wardrobeContext: wardrobeContext,
                    imageData: capturedImageData
                )
                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, text: reply, imageData: nil))
                    isLoading = false
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
        HStack {
            if isUser { Spacer(minLength: 50) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                if let data = message.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.custom("Futura", size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(bubbleBackground)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }
            }

            if !isUser { Spacer(minLength: 50) }
        }
        .padding(.horizontal, 16)
    }

    private var bubbleBackground: Color {
        isUser
            ? Color.white.opacity(0.2)
            : Color(red: 40/255, green: 10/255, blue: 90/255).opacity(0.6)
    }
}

// MARK: - TypingIndicator

struct TypingIndicator: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.white.opacity(phase == i ? 0.9 : 0.3))
                    .frame(width: 7, height: 7)
                    .animation(.easeInOut(duration: 0.4).delay(Double(i) * 0.15).repeatForever(autoreverses: true),
                               value: phase)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}
