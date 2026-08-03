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
            /* Shift logo horizontally to clear window controls */
            .pinning-header .logo, 
            .pinning-header .brand-logo, 
            .pinning-header #netflix-brand-logo, 
            .pinning-header svg.logo,
            .pinning-header a.logo {
                margin-left: 80px !important;
            }

            /* Move video player back arrow safely below traffic light window controls */
            .watch-video--back-container {
                top: 36px !important;
                left: 24px !important;
            }

            /* Make top header draggable */
            .pinning-header-container {
                padding-top: 6px !important;
                -webkit-app-region: drag !important;
            }

            /* Ensure clickable elements remain interactive */
            a, button, input, select, textarea, [role="button"], .nav-element, .navigation-tab {
                -webkit-app-region: no-drag !important;
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

                let titleEl = document.querySelector('[data-uia="video-title"]') || document.querySelector('.video-title') || document.querySelector('.watch-video--player-view');
                if (titleEl) {
                    let h4 = titleEl.querySelector('h4') || titleEl.querySelector('.header-text');
                    let span = titleEl.querySelector('span') || titleEl.querySelector('.subtitle-text');
                    if (h4 && h4.innerText) title = h4.innerText.trim();
                    if (span && span.innerText) subtitle = span.innerText.trim();
                    if (!h4 && titleEl.innerText) {
                        let parts = titleEl.innerText.split('\n');
                        if (parts.length > 0) title = parts[0].trim();
                        if (parts.length > 1) subtitle = parts[1].trim();
                    }
                }

                if (title === "Netflix" || !title) {
                    let docTitle = document.title || "";
                    if (docTitle.includes("Netflix -")) {
                        let clean = docTitle.replace("Netflix -", "").trim();
                        if (clean.includes(":") || clean.includes("-")) {
                            let p = clean.split(new RegExp('[:\\\\-]'));
                            title = p[0].trim();
                            subtitle = p.slice(1).join(" - ").trim();
                        } else {
                            title = clean;
                        }
                    } else if (docTitle && docTitle !== "Netflix") {
                        title = docTitle;
                    }
                }

                let artworkURL = video.poster || "";

                if (navigator.mediaSession) {
                    navigator.mediaSession.metadata = new MediaMetadata({
                        title: title,
                        artist: subtitle.length > 0 ? subtitle : "Netflix",
                        album: "Netflix"
                    });
                }

                // Post message to Swift native NowPlayingManager
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.netflixMac) {
                    window.webkit.messageHandlers.netflixMac.postMessage({
                        action: "updateNowPlaying",
                        title: title,
                        subtitle: subtitle,
                        duration: video.duration || 0,
                        currentTime: video.currentTime || 0,
                        isPlaying: !video.paused,
                        artworkURL: artworkURL
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
                // Only perform auto-actions when actively in the video player
                if (!window.location.pathname.includes('/watch')) {
                    return;
                }

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
                        ['play', 'pause', 'durationchange', 'seeking', 'seeked'].forEach(evt => {
                            video.addEventListener(evt, updateMediaSession);
                        });
                    }
                    updateMediaSession();
                } else {
                    if (video !== null) {
                        video = null;
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.netflixMac) {
                            window.webkit.messageHandlers.netflixMac.postMessage({ action: "clearNowPlaying" });
                        }
                    }
                }
            }, 1000);

            // 4. HTML5 Fullscreen Event Bridge
            document.addEventListener('webkitfullscreenchange', function() {
                if (document.webkitIsFullScreen) {
                    window.webkit.messageHandlers.netflixMac.postMessage({ action: "enterFullscreen" });
                } else {
                    window.webkit.messageHandlers.netflixMac.postMessage({ action: "exitFullscreen" });
                }
            });
            document.addEventListener('fullscreenchange', function() {
                if (document.fullscreenElement) {
                    window.webkit.messageHandlers.netflixMac.postMessage({ action: "enterFullscreen" });
                } else {
                    window.webkit.messageHandlers.netflixMac.postMessage({ action: "exitFullscreen" });
                }
            });

            // 5. Toggle Fullscreen Helper
            window.toggleNetflixFullscreen = function() {
                let fsBtn = document.querySelector('button.button-nfplayerFullscreen, button[data-uia="control-fullscreen-enter"], button[data-uia="control-fullscreen-exit"]');
                if (fsBtn) {
                    fsBtn.click();
                } else {
                    let video = document.querySelector('video');
                    if (video) {
                        if (document.webkitIsFullScreen || document.fullscreenElement) {
                            if (document.webkitExitFullscreen) {
                                document.webkitExitFullscreen();
                            } else if (document.exitFullscreen) {
                                document.exitFullscreen();
                            }
                        } else {
                            if (video.webkitRequestFullScreen) {
                                video.webkitRequestFullScreen();
                            } else if (video.requestFullscreen) {
                                video.requestFullscreen();
                            }
                        }
                    }
                }
            };

            // 6. Keyboard Shortcut for 'F' Key
            document.addEventListener('keydown', function(e) {
                let active = document.activeElement;
                if (active && (active.tagName === 'INPUT' || active.tagName === 'TEXTAREA' || active.isContentEditable)) {
                    return;
                }
                if (e.key.toLowerCase() === 'f') {
                    window.toggleNetflixFullscreen();
                    e.preventDefault();
                    e.stopPropagation();
                }
            }, true);
        })();
        """
        let jsScript = WKUserScript(source: jsSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(jsScript)

        // Register script message handler
        configuration.userContentController.add(context.coordinator, name: "netflixMac")

        // Enable media playback preferences
        #if DEBUG
        let devKeyParts = ["developer", "Extras", "Enabled"]
        configuration.preferences.setValue(true, forKey: devKeyParts.joined())
        #endif
        configuration.preferences.setValue(true, forKey: "fullScreenEnabled")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        // Register active webView with NowPlayingManager for remote media commands
        NowPlayingManager.shared.webView = webView

        // Resolve user agent dynamically based on saved quality settings
        let savedQuality = UserDefaults.standard.string(forKey: "streamingQuality") ?? "Auto"
        let resolvedQuality = QualityLevel(rawValue: savedQuality) ?? .auto
        webView.customUserAgent = resolvedQuality.userAgent


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

        // Read selected quality and update User-Agent dynamically
        let savedQuality = UserDefaults.standard.string(forKey: "streamingQuality") ?? "Auto"
        let resolvedQuality = QualityLevel(rawValue: savedQuality) ?? .auto
        let expectedUA = resolvedQuality.userAgent
        
        if nsView.customUserAgent != expectedUA {
            nsView.customUserAgent = expectedUA
            nsView.reload()
        }
    }

    static func dismantleNSView(_ nsView: WKWebView, coordinator: WebViewCoordinator) {
        nsView.configuration.userContentController.removeScriptMessageHandler(forName: "netflixMac")
    }

    // MARK: - WKWebView Coordinator
    class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: NetflixWebView

        init(_ parent: NetflixWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            
            let host = url.host?.lowercased() ?? ""
            let isAbout = url.scheme == "about"
            
            // Define trusted Netflix and security vendor domains
            let isTrusted = host.hasSuffix("netflix.com") || 
                            host.hasSuffix("netflix.net") || 
                            host.hasSuffix("nflximg.com") || 
                            host.hasSuffix("nflximg.net") || 
                            host.hasSuffix("nflxvideo.net") || 
                            host.hasSuffix("nflxso.net") || 
                            host.hasSuffix("google.com") || 
                            host.hasSuffix("recaptcha.net") || 
                            host.hasSuffix("arkoselabs.com") || 
                            isAbout
                            
            if isTrusted {
                decisionHandler(.allow)
            } else {
                if navigationAction.targetFrame?.isMainFrame == true {
                    // Open external main-frame links in default macOS browser instead of embedding them
                    NSWorkspace.shared.open(url)
                }
                decisionHandler(.cancel)
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "netflixMac" else { return }
            guard let body = message.body as? [String: Any],
                  let action = body["action"] as? String else { return }

            DispatchQueue.main.async {
                if action == "updateNowPlaying" {
                    let title = body["title"] as? String ?? ""
                    let subtitle = body["subtitle"] as? String ?? ""
                    let duration = body["duration"] as? Double ?? 0
                    let currentTime = body["currentTime"] as? Double ?? 0
                    let isPlaying = body["isPlaying"] as? Bool ?? false
                    let artworkURL = body["artworkURL"] as? String

                    NowPlayingManager.shared.updateNowPlaying(
                        title: title,
                        subtitle: subtitle,
                        duration: duration,
                        currentTime: currentTime,
                        isPlaying: isPlaying,
                        artworkURL: artworkURL
                    )
                    return
                } else if action == "clearNowPlaying" {
                    NowPlayingManager.shared.clearNowPlaying()
                    return
                }

                guard let webView = message.webView,
                      let window = webView.window else { return }

                let isFullscreen = window.styleMask.contains(.fullScreen)

                if action == "enterFullscreen" {
                    if !isFullscreen {
                        window.toggleFullScreen(nil)
                    }
                } else if action == "exitFullscreen" {
                    if isFullscreen {
                        window.toggleFullScreen(nil)
                    }
                }
            }
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
