// MARK: - NetflixWebView.swift
// Native WKWebView wrapper for macOS featuring Safari User-Agent spoofing for DRM support.

import SwiftUI
import WebKit

struct NetflixWebView: NSViewRepresentable {
    let url: URL
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool

    // Action coordinator to trigger commands from SwiftUI
    class CommandCoordinator {
        var goBackAction: (() -> Void)?
        var goForwardAction: (() -> Void)?
        var reloadAction: (() -> Void)?
        var loadHomeAction: (() -> Void)?
    }
    let commandCoordinator: CommandCoordinator

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = "Version/17.4 Safari/605.1.15"

        // Allow picture-in-picture and video fullscreen
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        // Spoof modern Safari user agent to ensure FairPlay/Widevine DRM works out of the box
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"

        // Wire up control bar actions
        commandCoordinator.goBackAction = { [weak webView] in
            if webView?.canGoBack == true { webView?.goBack() }
        }
        commandCoordinator.goForwardAction = { [weak webView] in
            if webView?.canGoForward == true { webView?.goForward() }
        }
        commandCoordinator.reloadAction = { [weak webView] in
            webView?.reload()
        }
        commandCoordinator.loadHomeAction = { [weak webView] in
            let request = URLRequest(url: URL(string: "https://www.netflix.com")!)
            webView?.load(request)
        }

        // Load primary URL
        let request = URLRequest(url: url)
        webView.load(request)

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No-op - navigation handled via CommandCoordinator
    }

    // MARK: - WKWebView Coordinator
    class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: NetflixWebView

        init(_ parent: NetflixWebView) {
            self.parent = parent
        }

        // Navigation state changes
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
    }
}
