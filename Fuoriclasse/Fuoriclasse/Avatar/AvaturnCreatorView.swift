import SwiftUI
import UIKit
import WebKit

/// WKWebView embarquant le créateur d'avatar Avaturn.
/// Stratégie d'export multi-couches :
///   1. postMessage "v2.avatar.exported"   → onExported() automatique
///   2. Interception fetch/XHR pour .glb  → capturedGLBURL mis à jour
///   3. Bouton natif "Importer"            → evaluateJavaScript sur localStorage
struct AvaturnCreatorView: UIViewRepresentable {
    let embedURL: String
    /// URL GLB capturée automatiquement — permet d'activer le bouton "Importer"
    @Binding var capturedGLBURL: URL?
    /// Référence au Coordinator exposée pour l'évaluation JS manuelle
    @Binding var coordinator: Coordinator?
    let onExported: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(capturedGLBURL: $capturedGLBURL, onExported: onExported)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "avaturn")

        // ── Bridge JS complet ──────────────────────────────────────────────
        let bridge = """
        (function() {
            // 1. Relay postMessage → natif
            function relay(data) {
                try {
                    var p = (typeof data === 'string') ? JSON.parse(data) : data;
                    window.webkit.messageHandlers.avaturn.postMessage(p);
                } catch(_) {
                    window.webkit.messageHandlers.avaturn.postMessage({ raw: String(data) });
                }
            }
            window.addEventListener('message', function(e) { relay(e.data); }, false);
            var _pm = window.postMessage.bind(window);
            window.postMessage = function(msg, t) { relay(msg); _pm(msg, t || '*'); };

            // 2. Capture URL .glb via fetch
            var _fetch = window.fetch.bind(window);
            window.fetch = function(resource, opts) {
                var url = typeof resource === 'string' ? resource
                        : (resource && resource.url ? resource.url : '');
                if (url && /\\.glb(\\?|$)/i.test(url)) {
                    window.webkit.messageHandlers.avaturn.postMessage({ glbUrl: url });
                }
                return _fetch.apply(window, arguments);
            };

            // 3. Capture URL .glb via XHR
            var _open = XMLHttpRequest.prototype.open;
            XMLHttpRequest.prototype.open = function(method, url) {
                if (url && /\\.glb(\\?|$)/i.test(url)) {
                    window.webkit.messageHandlers.avaturn.postMessage({ glbUrl: url });
                }
                return _open.apply(this, arguments);
            };
        })();
        """
        let script = WKUserScript(source: bridge, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(script)

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

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
        @Binding var capturedGLBURL: URL?
        let onExported: (URL) -> Void
        weak var webView: WKWebView?

        init(capturedGLBURL: Binding<URL?>, onExported: @escaping (URL) -> Void) {
            _capturedGLBURL = capturedGLBURL
            self.onExported = onExported
        }

        // ── Permission caméra (iOS 15+) ────────────────────────────────────
        func webView(_ webView: WKWebView,
                     requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                     initiatedByFrame frame: WKFrameInfo,
                     type: WKMediaCaptureType,
                     decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }

        // ── Réception messages JS ──────────────────────────────────────────
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

            func fire(_ urlString: String) {
                guard let url = URL(string: urlString) else { return }
                DispatchQueue.main.async {
                    // Met à jour capturedGLBURL pour activer le bouton "Importer"
                    self.capturedGLBURL = url
                }
            }

            // Format officiel : {"eventName": "v2.avatar.exported", "data": {"usdzUrl": "...", "glbUrl": "..."}}
            // On préfère usdzUrl (format natif iOS, pas de Draco) puis glbUrl en fallback
            if let event = dict["eventName"] as? String,
               event == "v2.avatar.exported",
               let data = dict["data"] as? [String: Any] {
                let urlStr = (data["usdzUrl"] as? String) ?? (data["glbUrl"] as? String)
                if let urlStr {
                    fire(urlStr)
                    if let url = URL(string: urlStr) {
                        DispatchQueue.main.async { self.onExported(url) }
                    }
                }
                return
            }

            // Capture via interception fetch/XHR
            if let glbStr = dict["glbUrl"] as? String {
                fire(glbStr)
                return
            }

            // Formats de repli
            for key in ["url", "avatarUrl"] {
                if let s = dict[key] as? String { fire(s); return }
            }
        }

        // ── Évaluation JS manuelle (bouton "Importer") ─────────────────────
        /// Cherche l'URL du GLB dans localStorage/sessionStorage de la page
        func evaluateExtractURL(completion: @escaping (URL?) -> Void) {
            guard let wv = webView else { completion(nil); return }
            let js = """
            (function() {
                var stores = [localStorage, sessionStorage];
                for (var s of stores) {
                    for (var k of Object.keys(s)) {
                        try {
                            var raw = s.getItem(k);
                            var v = JSON.parse(raw);
                            for (var field of ['modelUrl','glbUrl','url','avatarUrl','exportUrl']) {
                                if (v && v[field] && String(v[field]).match(/\\.glb/i)) return v[field];
                            }
                            if (typeof raw === 'string' && raw.match(/https?:\\/\\/.*\\.glb/i)) {
                                var m = raw.match(/(https?:\\/\\/[^"'\\s]*\\.glb[^"'\\s]*)/i);
                                if (m) return m[1];
                            }
                        } catch(e) {}
                    }
                }
                return null;
            })()
            """
            wv.evaluateJavaScript(js) { result, _ in
                if let s = result as? String, let url = URL(string: s) {
                    completion(url)
                } else {
                    completion(nil)
                }
            }
        }
    }
}
