import SwiftUI
import WebKit

private let sharedProcessPool = WKProcessPool()

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = sharedProcessPool
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = UIColor(Color.Colors.primaryBG)
        webView.scrollView.backgroundColor = UIColor(Color.Colors.primaryBG)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        context.coordinator.load(url: url, in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.load(url: url, in: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    static func normalizedURL(_ url: URL) -> URL {
        if url.scheme == nil || url.scheme?.isEmpty == true {
            let raw = url.absoluteString.trimmingCharacters(in: .whitespaces)
            let withScheme = raw.hasPrefix("http://") || raw.hasPrefix("https://") ? raw : "https://\(raw)"
            return URL(string: withScheme) ?? url
        }
        return url
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private var lastLoadedURL: URL?

        func load(url: URL, in webView: WKWebView) {
            let normalized = WebView.normalizedURL(url)
            guard lastLoadedURL != normalized || webView.url == nil else { return }

            lastLoadedURL = normalized
            let request = URLRequest(
                url: normalized,
                cachePolicy: .useProtocolCachePolicy,
                timeoutInterval: 60
            )
            webView.load(request)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let requestURL = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            guard let scheme = requestURL.scheme?.lowercased() else {
                decisionHandler(.allow)
                return
            }

            if scheme == "http" || scheme == "https" || scheme == "about" {
                decisionHandler(.allow)
                return
            }

            if UIApplication.shared.canOpenURL(requestURL) {
                UIApplication.shared.open(requestURL)
            }
            decisionHandler(.cancel)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            let nsError = error as NSError
            if nsError.code == NSURLErrorNetworkConnectionLost || nsError.code == NSURLErrorTimedOut || nsError.code == NSURLErrorCannotConnectToHost {
                let urlKey = "NSErrorFailingURLStringKey"
                if let urlString = nsError.userInfo[urlKey] as? String,
                   let loadURL = URL(string: urlString) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        webView.load(URLRequest(url: loadURL))
                    }
                }
            }
        }
    }
}

#Preview {
    WebView(url: URL(string: "https://www.apple.com")!)
}
