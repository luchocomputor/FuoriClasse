import SwiftUI
import UIKit
import WebKit

/// Visionneuse 3D basée sur model-viewer (WebGL + THREE.js + Draco).
/// SceneKit ne supporte pas la compression Draco mesh utilisée par Avaturn,
/// donc on passe par model-viewer qui la gère nativement.
struct Avatar3DView: UIViewRepresentable {
    @ObservedObject var avatarManager: AvatarManager

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = UIColor(red: 15/255, green: 5/255, blue: 40/255, alpha: 1)
        webView.isOpaque = true
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        if let url = avatarManager.avatarURL {
            context.coordinator.load(url, in: webView)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = avatarManager.avatarURL,
              url != context.coordinator.currentURL else { return }
        context.coordinator.load(url, in: uiView)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject {
        var currentURL: URL?

        func load(_ fileURL: URL, in webView: WKWebView) {
            guard let data = try? Data(contentsOf: fileURL) else {
                print("❌ [Avatar3D] Fichier introuvable:", fileURL.lastPathComponent)
                return
            }

            currentURL = fileURL
            let base64 = data.base64EncodedString()
            let ext = fileURL.pathExtension.lowercased()
            let mime = ext == "usdz" ? "model/vnd.usdz+zip" : "model/gltf-binary"

            print("🟡 [Avatar3D] Chargement model-viewer:", fileURL.lastPathComponent, data.count, "bytes")

            let html = """
            <!DOCTYPE html>
            <html>
            <head>
              <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
              <script type="module"
                src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.5.0/model-viewer.min.js">
              </script>
              <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body {
                  width: 100%; height: 100%;
                  background: #0f0528;
                  overflow: hidden;
                }
                model-viewer {
                  width: 100%; height: 100%;
                  --poster-color: #0f0528;
                  background-color: transparent;
                }
              </style>
            </head>
            <body>
              <model-viewer
                src="data:\(mime);base64,\(base64)"
                camera-controls
                auto-rotate
                auto-rotate-delay="2000"
                rotation-per-second="20deg"
                shadow-intensity="0.8"
                shadow-softness="1"
                environment-image="neutral"
                exposure="1.1"
                camera-orbit="0deg 70deg auto"
                field-of-view="40deg"
                touch-action="pan-y"
              ></model-viewer>
            </body>
            </html>
            """

            // baseURL HTTPS pour autoriser le chargement du CDN model-viewer
            webView.loadHTMLString(html, baseURL: URL(string: "https://fuoriclasse.avaturn.dev"))
        }
    }
}
