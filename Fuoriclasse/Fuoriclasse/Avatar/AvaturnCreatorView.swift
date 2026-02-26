import SwiftUI
import UIKit
import WebKit

struct AvaturnCreatorView: UIViewRepresentable {
    let embedURL: String
    @Binding var capturedGLBURL: URL?
    @Binding var coordinator: Coordinator?
    let onExported: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(capturedGLBURL: $capturedGLBURL, onExported: onExported)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Message handler : reçoit les postMessages relayés par le wrapper HTML
        config.userContentController.add(context.coordinator, name: "avaturn")

        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate         = context.coordinator
        webView.backgroundColor    = UIColor(red: 15/255, green: 5/255, blue: 40/255, alpha: 1)
        webView.isOpaque = false

        context.coordinator.webView = webView
        DispatchQueue.main.async { self.coordinator = context.coordinator }
        loadEditor(in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // MARK: - Chargement

    private func loadEditor(in webView: WKWebView) {
        guard !embedURL.isEmpty, URL(string: embedURL) != nil else {
            let html = """
            <html><body style="background:#0f0528;display:flex;align-items:center;
            justify-content:center;height:100vh;margin:0;">
            <p style="color:rgba(255,255,255,0.5);font-family:sans-serif;
            text-align:center;padding:32px;line-height:1.6;">
            Ajoute l'URL embed Avaturn dans Secrets.plist<br>
            <small>(clé AVATURN_EMBED_URL)</small>
            </p></body></html>
            """
            webView.loadHTMLString(html, baseURL: nil)
            return
        }

        // ── Stratégie iframe ──────────────────────────────────────────────
        // Avaturn est conçu pour fonctionner embarqué dans un <iframe>.
        // Dans ce contexte, window.parent !== window → Avaturn envoie
        // automatiquement window.parent.postMessage("v2.avatar.exported", ...)
        // sans aucun trick JS. Le parent HTML intercepte et transfère à natif.
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
          <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            html, body { width: 100%; height: 100%; overflow: hidden; background: #0f0528; }
            iframe { width: 100%; height: 100%; border: none; display: block; }
          </style>
        </head>
        <body>
          <iframe
            id="av"
            src="\(embedURL)"
            allow="camera *; microphone *; autoplay; clipboard-write; xr-spatial-tracking"
          ></iframe>
          <script>
            // Test : vérifie que le canal webkit est disponible dès le chargement
            try {
              window.webkit.messageHandlers.avaturn.postMessage({ type: 'wrapper_ready' });
            } catch(e) {}

            // Relais postMessage iframe → natif
            window.addEventListener('message', function(e) {
              try {
                var d = (typeof e.data === 'string') ? JSON.parse(e.data) : e.data;
                window.webkit.messageHandlers.avaturn.postMessage(d);
              } catch(_) {
                window.webkit.messageHandlers.avaturn.postMessage({ raw: String(e.data) });
              }
            }, false);
          </script>
        </body>
        </html>
        """
        // baseURL = domaine Avaturn → la page wrapper est traitée comme venant de ce domaine
        webView.loadHTMLString(html, baseURL: URL(string: "https://fuoriclasse.avaturn.dev"))
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
        @Binding var capturedGLBURL: URL?
        let onExported: (URL) -> Void
        weak var webView: WKWebView?

        init(capturedGLBURL: Binding<URL?>, onExported: @escaping (URL) -> Void) {
            _capturedGLBURL = capturedGLBURL
            self.onExported = onExported
        }

        // ── Permission caméra (frame principal + sous-frames) ─────────────
        func webView(_ webView: WKWebView,
                     requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                     initiatedByFrame frame: WKFrameInfo,
                     type: WKMediaCaptureType,
                     decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }

        // ── Messages JS reçus ─────────────────────────────────────────────
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            print("🟣 [Avaturn] message reçu — name=\(message.name) body=\(message.body)")
            guard message.name == "avaturn" else { return }

            var dict: [String: Any]?
            if let d = message.body as? [String: Any] {
                dict = d
            } else if let s = message.body as? String,
                      let data = s.data(using: .utf8),
                      let d = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                dict = d
            }
            guard let dict else { return }

            func fire(_ urlString: String) {
                guard let url = URL(string: urlString) else { return }
                DispatchQueue.main.async {
                    self.capturedGLBURL = url
                    self.onExported(url)
                }
            }

            // ── v2 export (format officiel) ───────────────────────────────
            if let event = dict["eventName"] as? String,
               event == "v2.avatar.exported" || event == "v1.avatar.exported",
               let data = dict["data"] as? [String: Any] {
                print("✅ [Avaturn] Export event reçu:", event)
                let urlStr = (data["usdzUrl"] as? String) ?? (data["glbUrl"] as? String)
                    ?? (data["modelUrl"] as? String) ?? (data["url"] as? String)
                if let urlStr { fire(urlStr) }
                return
            }

            // ── RESPONSE à un REQUEST d'export (pattern v1 SDK) ───────────
            if let type_ = dict["type"] as? String, type_ == "RESPONSE",
               let key = dict["key"] as? String,
               (key.contains("export") || key.contains("avatar")),
               let data = dict["data"] as? [String: Any] {
                print("✅ [Avaturn] RESPONSE export reçu, key:", key)
                let urlStr = (data["usdzUrl"] as? String) ?? (data["glbUrl"] as? String)
                    ?? (data["modelUrl"] as? String) ?? (data["url"] as? String)
                if let urlStr { fire(urlStr) }
                return
            }

            // ── URL directe dans le message ───────────────────────────────
            if let glbStr = dict["glbUrl"] as? String { fire(glbStr); return }
            for key in ["usdzUrl", "url", "avatarUrl", "modelUrl"] {
                if let s = dict[key] as? String, s.hasPrefix("http") { fire(s); return }
            }
        }

        // ── Demande d'export à l'iframe + fallback localStorage ───────────
        func evaluateExtractURL(completion: @escaping (URL?) -> Void) {
            guard let wv = webView else { completion(nil); return }
            print("🔵 [Avaturn] Envoi REQUEST export à l'iframe...")
            // Envoie des messages REQUEST à l'iframe pour différentes versions du SDK
            let js = """
            (function() {
              var iframe = document.getElementById('av');
              if (!iframe || !iframe.contentWindow) return 'no-iframe';
              var reqs = [
                {type:'REQUEST', key:'v2.avatar.export', source:'v2.host', date:Date.now()},
                {type:'REQUEST', key:'v1.avatar.export', source:'v1.host', date:Date.now()},
                {eventName:'request.avatar.export'}
              ];
              reqs.forEach(function(r){ iframe.contentWindow.postMessage(JSON.stringify(r),'*'); });
              return 'sent';
            })()
            """
            wv.evaluateJavaScript(js) { result, _ in
                print("🔵 [Avaturn] REQUEST résultat:", result ?? "nil")
            }
            // La vraie réponse arrivera via userContentController → onExported
            // Ce timeout est juste pour fermer la boucle si rien ne revient
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { completion(nil) }
        }
    }
}
