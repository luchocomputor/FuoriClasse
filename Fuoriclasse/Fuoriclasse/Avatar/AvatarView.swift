import SwiftUI
import WebKit

struct AvatarView: View {
    @StateObject private var manager = AvatarManager()

    @State private var showCreator    = false
    @State private var isDownloading  = false
    @State private var downloadError: String?
    /// URL GLB capturée par le bridge JS — active le bouton "Importer"
    @State private var capturedGLBURL: URL?
    /// Référence au Coordinator injectée par AvaturnCreatorView pour l'évaluation JS
    @State private var avaturnCoordinator: AvaturnCreatorView.Coordinator?

    var body: some View {
        ZStack {
            background
            if isDownloading {
                downloadingOverlay
            } else if manager.hasAvatar {
                readyView
            } else {
                emptyView
            }
        }
        .navigationTitle("Mon Avatar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showCreator, onDismiss: { capturedGLBURL = nil }) {
            creatorSheet
        }
    }

    // MARK: - Background

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

    // MARK: - Empty state

    private var emptyView: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 160/255, green: 100/255, blue: 240/255),
                            Color(red: 100/255, green: 60/255, blue: 180/255)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            VStack(spacing: 10) {
                Text("Crée ton avatar")
                    .font(Font.custom("Futura-Bold", size: 26))
                    .foregroundColor(.white)
                Text("Prends quelques selfies.\nAvaturn génère un avatar 3D fidèle à ton style.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Button {
                capturedGLBURL = nil
                showCreator = true
            } label: {
                Label("Créer mon avatar", systemImage: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                colors: [
                                    Color(red: 140/255, green: 80/255, blue: 220/255),
                                    Color(red: 100/255, green: 50/255, blue: 180/255)
                                ],
                                startPoint: .leading, endPoint: .trailing
                            ))
                    )
                    .shadow(color: Color(red: 120/255, green: 60/255, blue: 200/255).opacity(0.5),
                            radius: 12, x: 0, y: 6)
            }
            if let err = downloadError {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundColor(.red.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Downloading overlay

    private var downloadingOverlay: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.4)
                .tint(Color(red: 160/255, green: 100/255, blue: 240/255))
            Text("Téléchargement de l'avatar…")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Ready state

    private var readyView: some View {
        VStack(spacing: 0) {
            Avatar3DView(avatarManager: manager)
                .frame(maxWidth: .infinity)
                .frame(height: 500)
                .ignoresSafeArea(edges: .top)
            Spacer()
            Button {
                capturedGLBURL = nil
                showCreator = true
            } label: {
                Label("Recréer mon avatar", systemImage: "arrow.clockwise")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
            .padding(.bottom, 36)
        }
    }

    // MARK: - Creator sheet

    private var creatorSheet: some View {
        NavigationStack {
            AvaturnCreatorView(
                embedURL: AvaturnService.shared.embedURL,
                capturedGLBURL: $capturedGLBURL,
                coordinator: $avaturnCoordinator
            ) { remoteURL in
                // Export automatique (v2.avatar.exported ou fetch intercept)
                handleExport(url: remoteURL)
            }
            .ignoresSafeArea()
            .navigationTitle("Créer mon avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        capturedGLBURL = nil
                        showCreator = false
                    }
                    .foregroundColor(.white.opacity(0.65))
                }
                ToolbarItem(placement: .confirmationAction) {
                    importButton
                }
            }
        }
    }

    /// Bouton "Importer" : actif si une URL a été capturée, sinon tente un JS fallback
    private var importButton: some View {
        Button {
            if let url = capturedGLBURL {
                showCreator = false
                handleExport(url: url)
            } else {
                // Fallback : cherche dans localStorage via JS
                avaturnCoordinator?.evaluateExtractURL { url in
                    if let url {
                        showCreator = false
                        handleExport(url: url)
                    } else {
                        downloadError = "Finalise la création de l'avatar dans Avaturn, puis retente."
                        showCreator = false
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                if capturedGLBURL != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 140/255, green: 220/255, blue: 130/255))
                }
                Text("Importer")
                    .fontWeight(.semibold)
            }
        }
        .foregroundColor(.white)
    }

    // MARK: - Download helper

    private func handleExport(url: URL) {
        isDownloading = true
        downloadError = nil
        Task {
            do {
                let local = try await AvaturnService.shared.downloadAvatar(from: url)
                await MainActor.run {
                    manager.avatarURL = local
                    isDownloading = false
                }
            } catch {
                await MainActor.run {
                    downloadError = error.localizedDescription
                    isDownloading = false
                }
            }
        }
    }
}
