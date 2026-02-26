import SwiftUI
import UIKit
import WebKit

/// WKWebView embarquant le créateur d'avatar Avaturn (free tier — embed URL).
/// Avaturn envoie un postMessage JS quand l'avatar est exporté → bridge natif → onExported(url).
struct AvaturnCreatorView: UIViewRepresentable {
    /// URL embed du projet Avaturn (depuis Editor Settings sur developer.avaturn.me)
    let embedURL: String
    let onExported: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onExported: onExported)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Handler natif "avaturn" — reçoit les messages JS
        config.userContentController.add(context.coordinator, name: "avaturn")

        // Bridge JS : intercepte window.postMessage et les events 'message'
        // et les forward vers le handler natif.
        let bridge = """
        (function() {
            function relay(data) {
                try {
                    var payload = (typeof data === 'string') ? JSON.parse(data) : data;
                    window.webkit.messageHandlers.avaturn.postMessage(payload);
                } catch(_) {
                    window.webkit.messageHandlers.avaturn.postMessage({ raw: String(data) });
                }
            }
            window.addEventListener('message', function(e) { relay(e.data); }, false);
            var orig = window.postMessage.bind(window);
            window.postMessage = function(msg, target) { relay(msg); orig(msg, target || '*'); };
        })();
        """
        let script = WKUserScript(source: bridge, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(script)

        // Autoriser la caméra dans la WebView (selfies)
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = UIColor(red: 15/255, green: 5/255, blue: 40/255, alpha: 1)
        webView.isOpaque = false

        loadEditor(in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // MARK: - Chargement

    private func loadEditor(in webView: WKWebView) {
        guard !embedURL.isEmpty, let url = URL(string: embedURL) else {
            let html = """
            <html><body style="background:#0f0528;display:flex;align-items:center;
            justify-content:center;height:100vh;margin:0;">
            <p style="color:rgba(255,255,255,0.5);font-family:sans-serif;
            text-align:center;padding:32px;line-height:1.6;">
            Ajoute l'URL embed Avaturn dans Secrets.plist<br>
            <small>(clé AVATURN_EMBED_URL — depuis Editor Settings)</small>
            </p></body></html>
            """
            webView.loadHTMLString(html, baseURL: nil)
            return
        }
        webView.load(URLRequest(url: url))
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        let onExported: (URL) -> Void

        init(onExported: @escaping (URL) -> Void) {
            self.onExported = onExported
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
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

            // Extrait une string GLB depuis un dict et déclenche le callback
            func fire(_ urlString: String) {
                // Supporte HttpURL (http/https) et DataURL (data:...)
                guard let url = URL(string: urlString) else { return }
                DispatchQueue.main.async { self.onExported(url) }
            }

            // Format officiel Avaturn : {"eventName": "v2.avatar.exported", "data": {"glbUrl": "..."}}
            if let event = dict["eventName"] as? String,
               event == "v2.avatar.exported",
               let data = dict["data"] as? [String: Any],
               let glbStr = data["glbUrl"] as? String {
                fire(glbStr)
                return
            }

            // Formats de repli
            for key in ["glbUrl", "url", "avatarUrl"] {
                if let s = dict[key] as? String {
                    fire(s)
                    return
                }
            }
        }
    }
}
