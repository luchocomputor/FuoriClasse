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
        config.userContentController.add(context.coordinator, name: "avaturn")

        // ── Bridge JS ─────────────────────────────────────────────────────
        // Stratégie principale : simuler un parent iframe → Avaturn pense être
        // embarqué et déclenche window.parent.postMessage("v2.avatar.exported")
        // Stratégie fallback  : bouton injecté dans la page + interception API
        let bridge = """
        (function() {

          // ① Fake parent frame : Avaturn vérifie window !== window.top
          //   et n'envoie postMessage QUE si embedded. On le trompe.
          var _fakeParent = {
            postMessage: function(data) {
              try {
                var p = (typeof data === 'string') ? JSON.parse(data) : data;
                window.webkit.messageHandlers.avaturn.postMessage(p);
              } catch(_) {
                window.webkit.messageHandlers.avaturn.postMessage({ raw: String(data) });
              }
            }
          };
          try {
            Object.defineProperty(window, 'parent', { get: function(){ return _fakeParent; }, configurable: true });
            Object.defineProperty(window, 'top',    { get: function(){ return _fakeParent; }, configurable: true });
          } catch(e) {}

          // ② window.addEventListener('message') bridge (postMessage natif)
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

          // ③ Capture URL .glb/.usdz via fetch (réponses réseau Avaturn)
          var _fetch = window.fetch.bind(window);
          window.fetch = function(resource, opts) {
            var url = typeof resource === 'string' ? resource
                    : (resource && resource.url ? resource.url : '');
            var promise = _fetch.apply(window, arguments);
            // Capture URL de requête si c'est un modèle 3D
            if (url && /\\.(glb|usdz)(\\?|$)/i.test(url)) {
              window.webkit.messageHandlers.avaturn.postMessage({ glbUrl: url });
            }
            // Capture URL depuis la réponse JSON d'Avaturn (liste d'avatars)
            if (url && url.includes('avaturn.me')) {
              promise.then(function(res) {
                var clone = res.clone();
                clone.json().then(function(json) {
                  var items = Array.isArray(json) ? json : (json.items || json.avatars || [json]);
                  for (var item of items) {
                    var u = item.modelUrl || item.glbUrl || item.url || item.model_url;
                    if (u && /\\.(glb|usdz)/i.test(u)) {
                      window.webkit.messageHandlers.avaturn.postMessage({ glbUrl: u });
                    }
                  }
                }).catch(function(){});
              }).catch(function(){});
            }
            return promise;
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
            <small>(clé AVATURN_EMBED_URL)</small>
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

        // ── Permission caméra iOS 15+ ──────────────────────────────────────
        func webView(_ webView: WKWebView,
                     requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                     initiatedByFrame frame: WKFrameInfo,
                     type: WKMediaCaptureType,
                     decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }

        // ── Messages JS reçus ─────────────────────────────────────────────
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

            // Helper : capture URL et déclenche onExported
            func fire(_ urlString: String) {
                guard let url = URL(string: urlString) else { return }
                DispatchQueue.main.async {
                    self.capturedGLBURL = url
                    self.onExported(url)        // export automatique immédiat
                }
            }

            // Format officiel : {"eventName": "v2.avatar.exported", "data": {"usdzUrl","glbUrl"}}
            if let event = dict["eventName"] as? String, event == "v2.avatar.exported",
               let data = dict["data"] as? [String: Any] {
                let urlStr = (data["usdzUrl"] as? String) ?? (data["glbUrl"] as? String)
                if let urlStr { fire(urlStr) }
                return
            }

            // URL capturée via fetch/XHR ou bouton injecté
            if let glbStr = dict["glbUrl"] as? String { fire(glbStr); return }
            for key in ["usdzUrl", "url", "avatarUrl"] {
                if let s = dict[key] as? String { fire(s); return }
            }

            // Token Firebase : demande à l'app de fetch l'avatar via API Avaturn
            if let token = dict["firebaseToken"] as? String {
                Task {
                    if let url = try? await AvaturnService.shared.fetchLatestAvatarURL(bearerToken: token) {
                        DispatchQueue.main.async { self.onExported(url) }
                    }
                }
                return
            }
        }

        // ── Évaluation JS manuelle (fallback bouton natif "Importer") ──────
        func evaluateExtractURL(completion: @escaping (URL?) -> Void) {
            guard let wv = webView else { completion(nil); return }
            // Cherche aussi dans l'URL courante de la page (certains SPA mettent l'avatar ID dans l'URL)
            let js = """
            (function() {
              var stores = [localStorage, sessionStorage];
              for (var s of stores) {
                for (var k of Object.keys(s)) {
                  try {
                    var raw = s.getItem(k);
                    var v = JSON.parse(raw);
                    for (var f of ['modelUrl','glbUrl','url','avatarUrl','model_url']) {
                      if (v && v[f] && /\\.(glb|usdz)/i.test(String(v[f]))) return v[f];
                    }
                    var m = raw && raw.match(/"(https?:\\/\\/[^"]*\\.(glb|usdz)[^"]*)"/i);
                    if (m) return m[1];
                  } catch(e) {}
                }
              }
              return window.location.href;
            })()
            """
            wv.evaluateJavaScript(js) { result, _ in
                if let s = result as? String, let url = URL(string: s), url.scheme == "https" {
                    // Si l'URL est une page web (pas un fichier 3D), retourner nil
                    let ext = url.pathExtension.lowercased()
                    completion((ext == "glb" || ext == "usdz") ? url : nil)
                } else {
                    completion(nil)
                }
            }
        }
    }
}
