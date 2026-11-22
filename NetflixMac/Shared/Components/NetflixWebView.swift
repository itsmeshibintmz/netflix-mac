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
            let cachedTitle = "";
            let cachedSubtitle = "";
            let cachedArtworkFromNetflix = [];  // captured from Netflix's own mediaSession.metadata

            // --- Intercept navigator.mediaSession.metadata setter ---
            // Netflix sets this with the real show artwork. We capture it before they override title.
            try {
                let origDescriptor = Object.getOwnPropertyDescriptor(MediaSession.prototype, 'metadata');
                if (origDescriptor && origDescriptor.set) {
                    Object.defineProperty(MediaSession.prototype, 'metadata', {
                        get: origDescriptor.get,
                        set: function(val) {
                            if (val && val.artwork && val.artwork.length > 0) {
                                // Capture Netflix's artwork URLs — they contain the real show poster
                                cachedArtworkFromNetflix = Array.from(val.artwork).map(function(a) {
                                    return { src: a.src || "", sizes: a.sizes || "512x512", type: a.type || "image/jpeg" };
                                }).filter(function(a) { return a.src.length > 0; });
                            }
                            return origDescriptor.set.call(this, val);
                        },
                        configurable: true
                    });
                }
            } catch(e) {}

            // --- Title interception via MutationObserver on <title> element ---
            // This is more reliable than Object.defineProperty because React/Netflix
            // may call the native HTMLDocument.prototype title setter directly.
            function cacheTitleFromString(val) {
                if (!val || val === "Netflix") return;
                let clean = val.replace(/^Watch /i, "").replace(/ \\| Netflix$/i, "").replace(/ - Netflix$/i, "").replace(/^Netflix - /i, "").trim();
                if (clean && clean !== "Netflix" && clean.length > 2) {
                    let parts = clean.split(' : ');
                    if (parts.length < 2) parts = clean.split(': ');
                    if (parts.length > 1) {
                        cachedTitle = parts[0].trim();
                        cachedSubtitle = parts.slice(1).join(" - ").trim();
                    } else {
                        cachedTitle = clean;
                        cachedSubtitle = "";
                    }
                }
            }

            // Observe the <title> element directly
            function observeTitle() {
                let titleEl = document.querySelector('title');
                if (!titleEl) return;
                cacheTitleFromString(titleEl.textContent);
                let obs = new MutationObserver(function() {
                    cacheTitleFromString(titleEl.textContent || document.title);
                });
                obs.observe(titleEl, { subtree: true, characterData: true, childList: true });
            }

            // Also intercept via defineProperty as a backup
            try {
                let _title = document.title;
                Object.defineProperty(document, 'title', {
                    get: function() { return _title; },
                    set: function(val) { _title = val; cacheTitleFromString(val); },
                    configurable: true
                });
            } catch(e) {}

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', observeTitle);
            } else {
                observeTitle();
            }

            // Register MediaSession action handlers
            if (navigator.mediaSession) {
                try {
                    navigator.mediaSession.setActionHandler('play', function() {
                        let v = document.querySelector('video');
                        if (v) v.play();
                    });
                    navigator.mediaSession.setActionHandler('pause', function() {
                        let v = document.querySelector('video');
                        if (v) v.pause();
                    });
                    navigator.mediaSession.setActionHandler('seekbackward', function(details) {
                        let v = document.querySelector('video');
                        if (v) v.currentTime = Math.max(0, v.currentTime - (details.seekOffset || 10));
                    });
                    navigator.mediaSession.setActionHandler('seekforward', function(details) {
                        let v = document.querySelector('video');
                        if (v) v.currentTime = Math.min(v.duration, v.currentTime + (details.seekOffset || 10));
                    });
                    navigator.mediaSession.setActionHandler('nexttrack', function() {
                        let nextBtn = document.querySelector('button[data-uia="next-episode-seamless-button"], .watch-video--next-episode-button');
                        if (nextBtn) nextBtn.click();
                    });
                } catch (e) {}
            }

            function extractTitle() {
                let navWords = ["Home","Search","New & Popular","My List","Browse","Rated","Continue Watching","Because","Trending","Top","Categories","Languages","Genres"];
                function isNavText(t) {
                    return !t || t.length < 2 || navWords.some(w => t === w || t.startsWith(w + " "));
                }

                // 1. data-uia="video-title" container — Netflix's own test attribute, most stable
                let titleContainer = document.querySelector('[data-uia="video-title"]');
                if (titleContainer) {
                    let h4 = titleContainer.querySelector('h4');
                    let span = titleContainer.querySelector('span');
                    let titleText = (h4 && h4.textContent.trim()) || (span && span.textContent.trim()) || titleContainer.innerText.split('\\n')[0].trim();
                    let subtitleText = (span && h4 && span !== h4) ? span.textContent.trim() : "";
                    if (titleText && !isNavText(titleText)) {
                        return { title: titleText, subtitle: subtitleText };
                    }
                }

                // 2. Cached title captured from <title> element / document.title
                if (cachedTitle && !isNavText(cachedTitle)) {
                    return { title: cachedTitle, subtitle: cachedSubtitle };
                }

                return null;
            }

            function getBestArtwork() {
                // 1. Best source: artwork captured from Netflix's own mediaSession.metadata setter
                //    Netflix sets this with the real show poster/thumbnail - we intercepted it above
                if (cachedArtworkFromNetflix.length > 0) {
                    // Pick the largest by sizes attribute (e.g. "512x512")
                    let sorted = cachedArtworkFromNetflix.slice().sort(function(a, b) {
                        let aw = parseInt((a.sizes || "0x0").split('x')[0]) || 0;
                        let bw = parseInt((b.sizes || "0x0").split('x')[0]) || 0;
                        return bw - aw;
                    });
                    if (sorted[0] && sorted[0].src) return sorted[0].src;
                }

                // 2. Scan Netflix CDN img elements (no naturalWidth restriction since many are lazy-loaded)
                let best = "";
                let bestArea = 0;
                document.querySelectorAll('img').forEach(function(img) {
                    let src = img.src || img.currentSrc || img.getAttribute('src') || "";
                    if (src.includes('nflxso') || src.includes('nflximg')) {
                        let area = (img.naturalWidth || img.width || 1) * (img.naturalHeight || img.height || 1);
                        if (area > bestArea) { bestArea = area; best = src; }
                    }
                });
                if (best) return best;

                // 3. video.poster
                if (video && video.poster) return video.poster;
                return "";
            }

            function getSubtitle(container) {
                if (!container) return "";
                let spans = container.querySelectorAll('span');
                for (let s of spans) {
                    let t = s.textContent.trim();
                    if (t && t.length > 1 && (t.match(/^S\\d+/) || t.includes('"') || t.includes("'"))) {
                        return t;
                    }
                }
                return "";
            }

            function updateMediaSession() {
                if (!video) return;

                let extracted = extractTitle();
                let title = extracted ? extracted.title : "Netflix";

                let titleContainer = document.querySelector('[data-uia="video-title"]');
                let subtitle = extracted ? extracted.subtitle : "";
                if (!subtitle && titleContainer) {
                    subtitle = getSubtitle(titleContainer);
                }

                // --- Artwork ---
                // Use the artwork we intercepted from Netflix's own mediaSession.metadata setter
                // This is the highest quality source Netflix provides
                let artwork = cachedArtworkFromNetflix.length > 0 ? cachedArtworkFromNetflix.slice() : [];

                // Fallback: scan Netflix CDN <img> elements
                if (artwork.length === 0) {
                    let bestSrc = "";
                    let bestArea = 0;
                    document.querySelectorAll('img').forEach(function(img) {
                        let src = img.src || img.currentSrc || img.getAttribute('src') || "";
                        if (src.includes('nflxso') || src.includes('nflximg')) {
                            let area = (img.naturalWidth || img.width || 1) * (img.naturalHeight || img.height || 1);
                            if (area > bestArea) { bestArea = area; bestSrc = src; }
                        }
                    });
                    if (bestSrc) artwork = [{ src: bestSrc, sizes: '512x512', type: 'image/jpeg' }];
                }

                // Fallback: video.poster
                if (artwork.length === 0 && video.poster) {
                    artwork = [{ src: video.poster, sizes: '512x512', type: 'image/jpeg' }];
                }

                // --- Dynamic next/previous track handlers ---
                // Show ⏭ only when the Netflix next episode button is present
                let hasNext = !!(document.querySelector('button[data-uia="next-episode-seamless-button"], .watch-video--next-episode-button, [data-uia="next-episode-button"]'));
                try {
                    if (hasNext) {
                        navigator.mediaSession.setActionHandler('nexttrack', function() {
                            let nb = document.querySelector('button[data-uia="next-episode-seamless-button"], .watch-video--next-episode-button, [data-uia="next-episode-button"]');
                            if (nb) nb.click();
                        });
                    } else {
                        navigator.mediaSession.setActionHandler('nexttrack', null);
                    }
                } catch(e) {}

                // Keep WebKit and the native Now Playing center in sync.
                if (navigator.mediaSession) {
                    navigator.mediaSession.playbackState = video.paused ? "paused" : "playing";
                    navigator.mediaSession.metadata = new MediaMetadata({
                        title: title,
                        artist: subtitle.length > 0 ? subtitle : "Netflix",
                        album: "Netflix",
                        artwork: artwork
                    });
                }

                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.netflixMac) {
                    window.webkit.messageHandlers.netflixMac.postMessage({
                        action: "updateNowPlaying",
                        title: title,
                        subtitle: subtitle,
                        duration: video.duration || 0,
                        currentTime: video.currentTime || 0,
                        isPlaying: !video.paused,
                        artworkURL: artwork.length > 0 ? artwork[0].src : "",
                        hasNext: hasNext
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
                    if (video !== null && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.netflixMac) {
                        window.webkit.messageHandlers.netflixMac.postMessage({ action: "clearNowPlaying" });
                    }
                    video = null;
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
                    if (video !== null && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.netflixMac) {
                        window.webkit.messageHandlers.netflixMac.postMessage({ action: "clearNowPlaying" });
                    }
                    video = null;
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

        // Register webView with NowPlayingManager for remote media command JS execution
        NowPlayingManager.shared.webView = webView

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

            let trustedDomains = [
                "netflix.com",
                "netflix.net",
                "nflximg.com",
                "nflximg.net",
                "nflxvideo.net",
                "nflxso.net",
                "google.com",
                "recaptcha.net",
                "arkoselabs.com"
            ]
            let isTrustedDomain = trustedDomains.contains {
                host == $0 || host.hasSuffix(".\($0)")
            }
            let isTrusted = isAbout || (url.scheme == "https" && isTrustedDomain)
                            
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
                    let hasNext = body["hasNext"] as? Bool ?? false
                    NowPlayingManager.shared.updateNowPlaying(
                        title: title, subtitle: subtitle,
                        duration: duration, currentTime: currentTime,
                        isPlaying: isPlaying, artworkURL: artworkURL,
                        hasNext: hasNext
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
