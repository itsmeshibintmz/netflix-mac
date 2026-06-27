// MARK: - NetflixWebView.swift
// Native WKWebView wrapper for macOS featuring Safari User-Agent spoofing, DRM, and native HTML5 MediaSession integration.

import SwiftUI
import WebKit

struct NetflixWebView: NSViewRepresentable {
    let url: URL
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool

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
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        // 1. Inject custom CSS to align elements and add modern styling
        let cssSource = """
        var style = document.createElement('style');
        style.innerHTML = `
            /* Shift only the logo to make room for window controls, others slide over naturally */
            .logo, 
            .brand-logo, 
            #netflix-brand-logo, 
            svg.logo {
                margin-left: 80px !important;
            }

            /* Custom elegant, ultra-thin scrollbars */
            ::-webkit-scrollbar {
                width: 6px !important;
                height: 6px !important;
            }
            ::-webkit-scrollbar-track {
                background: transparent !important;
            }
            ::-webkit-scrollbar-thumb {
                background: rgba(255, 255, 255, 0.2) !important;
                border-radius: 3px !important;
            }
            ::-webkit-scrollbar-thumb:hover {
                background: rgba(255, 255, 255, 0.4) !important;
            }
        `;
        document.head.appendChild(style);
        """
        let cssScript = WKUserScript(source: cssSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(cssScript)

        // 2. Inject JS script to feed video metadata directly to WebKit's native W3C MediaSession API.
        // This integrates with macOS Lock Screen, Control Center, and Media Keys natively,
        // preventing duplicate media player entries in the menu bar.
        let jsSource = """
        (function() {
            let video = null;

            function updateMediaSession() {
                if (!video) return;

                let title = "Netflix";
                let subtitle = "";

                // Try to find the title inside Netflix's video overlay
                let titleEl = document.querySelector('.video-title');
                if (titleEl) {
                    let h4 = titleEl.querySelector('h4');
                    let span = titleEl.querySelector('span');
                    if (h4) title = h4.innerText;
                    if (span) subtitle = span.innerText;
                } else {
                    // Fallback to document title
                    let docTitle = document.title;
                    if (docTitle && docTitle.startsWith("Netflix -")) {
                        title = docTitle.replace("Netflix -", "").trim();
                    }
                }

                if (navigator.mediaSession) {
                    navigator.mediaSession.metadata = new MediaMetadata({
                        title: title,
                        artist: "Netflix",
                        album: subtitle
                    });
                }
            }

            setInterval(() => {
                let el = document.querySelector('video');
                if (el) {
                    if (video !== el) {
                        video = el;
                        // Hook listeners to update metadata when playback changes
                        ['play', 'pause', 'durationchange'].forEach(evt => {
                            video.addEventListener(evt, updateMediaSession);
                        });
                        updateMediaSession();
                    }
                } else {
                    video = null;
                }
            }, 1000);
        })();
        """
        let jsScript = WKUserScript(source: jsSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(jsScript)

        // Enable media playback preferences
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

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

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    // MARK: - WKWebView Coordinator
    class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: NetflixWebView

        init(_ parent: NetflixWebView) {
            self.parent = parent
        }

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
