import AppKit
import Combine
import MediaPlayer
import SwiftUI
import WebKit
import XCTest

private final class PlaybackProbe: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var loaded: XCTestExpectation?
    var played: XCTestExpectation?
    var paused: XCTestExpectation?

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loaded?.fulfill()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.body as? String {
        case "played": played?.fulfill()
        case "paused": paused?.fulfill()
        default: break
        }
    }
}

@MainActor
final class MenuBarTests: XCTestCase {
    func testClosingLastWindowQuitsUnlessMenuBarIsEnabled() {
        let defaults = UserDefaults.standard
        let key = "keepRunningInMenuBar"
        let original = defaults.object(forKey: key)
        defer {
            if let original {
                defaults.set(original, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        let delegate = AppDelegate()
        defaults.removeObject(forKey: key)
        XCTAssertTrue(delegate.applicationShouldTerminateAfterLastWindowClosed(NSApplication.shared))
        defaults.set(true, forKey: key)
        XCTAssertFalse(delegate.applicationShouldTerminateAfterLastWindowClosed(NSApplication.shared))
        defaults.set(false, forKey: key)
        XCTAssertTrue(delegate.applicationShouldTerminateAfterLastWindowClosed(NSApplication.shared))
    }

    func testNowPlayingStateTracksPlaybackAndClears() {
        _ = NSApplication.shared
        let manager = NowPlayingManager.shared
        defer { manager.clearNowPlaying() }

        manager.updateNowPlaying(title: "", subtitle: "", duration: 0, currentTime: 0, isPlaying: true, artworkURL: nil)
        XCTAssertEqual(manager.title, "Netflix")
        XCTAssertTrue(manager.isPlaying)

        manager.updateNowPlaying(title: "Example", subtitle: "", duration: 100, currentTime: 10, isPlaying: false, artworkURL: nil, hasNext: true)
        XCTAssertEqual(manager.title, "Example")
        XCTAssertFalse(manager.isPlaying)
        XCTAssertTrue(MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled)

        manager.clearNowPlaying()
        XCTAssertNil(manager.title)
        XCTAssertFalse(manager.isPlaying)
        XCTAssertFalse(MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled)
    }

    func testPlayPauseControlsWebViewPlayer() {
        _ = NSApplication.shared
        let probe = PlaybackProbe()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(probe, name: "playbackTest")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = probe
        let manager = NowPlayingManager.shared
        manager.webView = webView
        defer {
            manager.webView = nil
            configuration.userContentController.removeScriptMessageHandler(forName: "playbackTest")
        }

        probe.loaded = expectation(description: "player fixture loaded")
        webView.loadHTMLString("""
            <script>
            const player = {
                paused: true,
                play() { this.paused = false; window.webkit.messageHandlers.playbackTest.postMessage('played'); return Promise.resolve(); },
                pause() { this.paused = true; window.webkit.messageHandlers.playbackTest.postMessage('paused'); }
            };
            const querySelector = document.querySelector.bind(document);
            document.querySelector = selector => selector === 'video' ? player : querySelector(selector);
            </script>
            """, baseURL: nil)
        wait(for: [probe.loaded!], timeout: 10)

        probe.played = expectation(description: "player plays")
        manager.togglePlayPause()
        wait(for: [probe.played!], timeout: 10)

        probe.paused = expectation(description: "player pauses")
        manager.togglePlayPause()
        wait(for: [probe.paused!], timeout: 10)
    }

    func testDismantlingOnlyClearsTheActiveWebView() {
        _ = NSApplication.shared
        let view = NetflixWebView(
            url: URL(string: "about:blank")!,
            canGoBack: .constant(false), canGoForward: .constant(false), isLoading: .constant(false),
            commandCoordinator: NetflixWebView.CommandCoordinator(),
            autoSkipIntro: false, autoPlayNext: false, pureOledBlack: false
        )
        let coordinator = view.makeCoordinator()
        let active = WKWebView()
        let other = WKWebView()
        let manager = NowPlayingManager.shared
        manager.webView = active
        manager.updateNowPlaying(title: "Example", subtitle: "", duration: 0, currentTime: 0, isPlaying: true, artworkURL: nil)
        defer {
            manager.webView = nil
            manager.clearNowPlaying()
        }

        NetflixWebView.dismantleNSView(other, coordinator: coordinator)
        XCTAssertTrue(manager.webView === active)
        XCTAssertEqual(manager.title, "Example")

        NetflixWebView.dismantleNSView(active, coordinator: coordinator)
        XCTAssertNil(manager.webView)
        XCTAssertNil(manager.title)
        XCTAssertFalse(manager.isPlaying)
    }

    func testNavigationClearsActivePlayback() {
        _ = NSApplication.shared
        let view = NetflixWebView(
            url: URL(string: "about:blank")!,
            canGoBack: .constant(false), canGoForward: .constant(false), isLoading: .constant(false),
            commandCoordinator: NetflixWebView.CommandCoordinator(),
            autoSkipIntro: false, autoPlayNext: false, pureOledBlack: false
        )
        let coordinator = view.makeCoordinator()
        let webView = WKWebView()
        let manager = NowPlayingManager.shared
        manager.webView = webView
        manager.updateNowPlaying(title: "Example", subtitle: "", duration: 0, currentTime: 0, isPlaying: true, artworkURL: nil)
        defer {
            manager.webView = nil
            manager.clearNowPlaying()
        }

        let cleared = expectation(description: "navigation clears playback")
        let subscription = manager.$title.dropFirst().filter { $0 == nil }.sink { _ in cleared.fulfill() }
        coordinator.webView(webView, didStartProvisionalNavigation: nil)
        wait(for: [cleared], timeout: 5)
        XCTAssertFalse(manager.isPlaying)
        withExtendedLifetime(subscription) {}
    }
}
