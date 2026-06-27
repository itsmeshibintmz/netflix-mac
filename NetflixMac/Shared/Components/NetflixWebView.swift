// MARK: - NetflixWebView.swift
// Native WKWebView wrapper for macOS featuring Safari User-Agent spoofing, DRM, and settings injection.

import SwiftUI
import WebKit

struct NetflixWebView: NSViewRepresentable {
    let url: URL
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    let commandCoordinator: CommandCoordinator

    // Preferences properties passed from container
    let autoSkipIntro: Bool
    let autoPlayNext: Bool
    let pureOledBlack: Bool

    class CommandCoordinator {
        var goBackAction: (() -> Void)?
        var goForwardAction: (() -> Void)?
        var reloadAction: (() -> Void)?
        var loadHomeAction: (() -> Void)?
    }

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        // 1. Initialize settings properties in JS at document start
        let settingsSource = "window.macFlixSettings = { autoSkip: \(autoSkipIntro), autoNext: \(autoPlayNext), pureOled: \(pureOledBlack) };"
        let settingsScript = WKUserScript(source: settingsSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(settingsScript)

        // 2. Inject custom CSS to align elements and add modern styling
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

        // 3. Inject JS script to feed video metadata to MediaSession API and execute background loop (Auto Skip/Play Next)
        let jsSource = """
        (function() {
            let video = null;

            function updateMediaSession() {
                if (!video) return;

                let title = "Netflix";
                let subtitle = "";

                let titleEl = document.querySelector('.video-title');
                if (titleEl) {
                    let h4 = titleEl.querySelector('h4');
                    let span = titleEl.querySelector('span');
                    if (h4) title = h4.innerText;
                    if (span) subtitle = span.innerText;
                } else {
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

            // Global function called by Swift when settings change dynamically
            window.updateAppPreferences = function() {
                let settings = window.macFlixSettings || {};
                
                // Toggle OLED Black stylesheet
                let oledStyle = document.getElementById('macflix-oled-style');
                if (settings.pureOled) {
                    if (!oledStyle) {
                        oledStyle = document.createElement('style');
                        oledStyle.id = 'macflix-oled-style';
                        oledStyle.innerHTML = `
                            body, .netflix-sans-font-loaded, .mainView, .watch-video, .pinning-header, .pinning-header-container {
                                background-color: #000000 !important;
                                background-image: none !important;
                            }
                        `;
                        document.head.appendChild(oledStyle);
                    }
                } else {
                    if (oledStyle) oledStyle.remove();
                }
            };

            // Run initial styles check
            setTimeout(window.updateAppPreferences, 1000);

            // Binge monitoring loop (runs every 1 second)
            setInterval(() => {
                let settings = window.macFlixSettings || {};

                // 1. Auto-Skip Intro & Recaps
                if (settings.autoSkip) {
                    let skipBtn = document.querySelector('.watch-video--skip-content-button, [data-uia="player-skip-intro"], button.skip-credits');
                    if (skipBtn) {
                        skipBtn.click();
                    } else {
                        // Fallback text matching
                        document.querySelectorAll('button, [role="button"]').forEach(btn => {
                            let txt = btn.textContent || "";
                            if (txt.includes("Skip Intro") || txt.includes("Skip Recap") || txt.includes("Skip Credits")) {
                                btn.click();
                            }
                        });
                    }
                }

                // 2. Auto-Play Next Episode
                if (settings.autoNext) {
                    let nextBtn = document.querySelector('button[data-uia="next-episode-seamless-button"], .watch-video--next-episode-button');
                    if (nextBtn) {
                        nextBtn.click();
                    } else {
                        // Fallback text matching
                        document.querySelectorAll('button, [role="button"]').forEach(btn => {
                            let txt = btn.textContent || "";
                            if (txt.includes("Next Episode")) {
                                btn.click();
                            }
                        });
                    }
                }

                // 3. Media session update hooks
                let el = document.querySelector('video');
                if (el) {
                    if (video !== el) {
                        video = el;
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

        // Spoof desktop Safari User-Agent to force full desktop features (such as scroll-based row lazy loading)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"


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
        // Sync Swift settings changes to Javascript dynamically
        let js = """
        window.macFlixSettings = {
            autoSkip: \(autoSkipIntro),
            autoNext: \(autoPlayNext),
            pureOled: \(pureOledBlack)
        };
        if (typeof window.updateAppPreferences === 'function') {
            window.updateAppPreferences();
        }
        """
        nsView.evaluateJavaScript(js, completionHandler: nil)
    }

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
