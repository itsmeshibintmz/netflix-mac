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
final class PlaybackTests: XCTestCase {
    func testSleepTimerReplacesCancelsAndPausesOnceAfterWake() {
        var current = Date(timeIntervalSinceReferenceDate: 1000)
        var pauseCount = 0
        let controller = SleepTimerController(pause: { completion in
            pauseCount += 1
            completion(nil)
        }, now: { current })
        let wake = { NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil) }

        controller.start(minutes: 15)
        XCTAssertEqual(controller.deadline, current.addingTimeInterval(900))
        controller.start(minutes: 30)
        XCTAssertEqual(controller.deadline, current.addingTimeInterval(1800))
        current.addTimeInterval(900)
        wake()
        XCTAssertEqual(pauseCount, 0)
        controller.cancel()
        current.addTimeInterval(901)
        wake()
        XCTAssertEqual(pauseCount, 0)
        XCTAssertNil(controller.deadline)

        controller.start(minutes: 15)
        current.addTimeInterval(900)
        wake()
        wake()
        XCTAssertEqual(pauseCount, 1)
        XCTAssertNil(controller.deadline)
    }

    func testSleepTimerFiresOnRunLoopAndReportsPauseFailure() {
        var current = Date(timeIntervalSinceReferenceDate: 1000)
        var reads = 0
        let expired = expectation(description: "timer fires")
        let controller = SleepTimerController(pause: { completion in
            completion(NSError(domain: "test", code: 1,
                               userInfo: [NSLocalizedDescriptionKey: "Player unavailable"]))
            expired.fulfill()
        }, now: {
            reads += 1
            if reads == 2 { current.addTimeInterval(59.9) }
            if reads >= 3 { current.addTimeInterval(1) }
            return current
        })
        controller.start(minutes: 1)
        wait(for: [expired], timeout: 2)
        XCTAssertNil(controller.deadline)
        XCTAssertTrue(controller.errorMessage?.contains("Player unavailable") == true)
    }

    func testSleepTimerPausesPlayerWithoutResumingIt() {
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
                paused: false,
                play() { window.webkit.messageHandlers.playbackTest.postMessage('played'); },
                pause() { this.paused = true; window.webkit.messageHandlers.playbackTest.postMessage('paused'); }
            };
            const querySelector = document.querySelector.bind(document);
            document.querySelector = selector => selector === 'video' ? player : querySelector(selector);
            </script>
            """, baseURL: nil)
        wait(for: [probe.loaded!], timeout: 10)

        var current = Date(timeIntervalSinceReferenceDate: 1000)
        var completed: XCTestExpectation?
        let controller = SleepTimerController(pause: { completion in
            manager.pausePlayback { error in
                XCTAssertNil(error)
                completion(error)
                completed?.fulfill()
            }
        }, now: { current })
        for _ in 0..<2 {
            probe.paused = expectation(description: "player paused")
            completed = expectation(description: "pause completed")
            controller.start(minutes: 15)
            current.addTimeInterval(900)
            NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
            wait(for: [probe.paused!, completed!], timeout: 10)
        }
    }

    func testSleepTimerPauseReportsMissingPlayer() {
        let manager = NowPlayingManager.shared
        manager.webView = nil
        var receivedError: Error?
        manager.pausePlayback { receivedError = $0 }
        XCTAssertNotNil(receivedError)

        let probe = PlaybackProbe()
        let webView = WKWebView()
        webView.navigationDelegate = probe
        manager.webView = webView
        defer { manager.webView = nil }
        probe.loaded = expectation(description: "page loaded without video")
        webView.loadHTMLString("<p>No video</p>", baseURL: nil)
        wait(for: [probe.loaded!], timeout: 10)
        let completed = expectation(description: "missing video reported")
        manager.pausePlayback { error in
            XCTAssertEqual(error?.localizedDescription, "No Netflix video is available.")
            completed.fulfill()
        }
        wait(for: [completed], timeout: 10)
    }

    func testClosingLastWindowQuitsEvenWithLegacyMenuBarSetting() {
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
        XCTAssertTrue(delegate.applicationShouldTerminateAfterLastWindowClosed(NSApplication.shared))
        defaults.set(false, forKey: key)
        XCTAssertTrue(delegate.applicationShouldTerminateAfterLastWindowClosed(NSApplication.shared))
    }

    func testNowPlayingStateUsesWebKitInsteadOfNativeCenter() {
        _ = NSApplication.shared
        let manager = NowPlayingManager.shared
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPNowPlayingInfoCenter.default().playbackState = .stopped
        defer { manager.clearNowPlaying() }

        manager.updateNowPlaying(title: "", isPlaying: true)
        XCTAssertEqual(manager.title, "Netflix")
        XCTAssertTrue(manager.isPlaying)
        XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
        XCTAssertEqual(MPNowPlayingInfoCenter.default().playbackState, .stopped)

        manager.updateNowPlaying(title: "Example", isPlaying: false)
        XCTAssertEqual(manager.title, "Example")
        XCTAssertFalse(manager.isPlaying)
        XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
        XCTAssertEqual(MPNowPlayingInfoCenter.default().playbackState, .stopped)

        manager.clearNowPlaying()
        XCTAssertNil(manager.title)
        XCTAssertFalse(manager.isPlaying)
        XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
        XCTAssertEqual(MPNowPlayingInfoCenter.default().playbackState, .stopped)
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

    func testMuteControlsAndExternalVolumeChangesStayInSync() throws {
        _ = NSApplication.shared
        let manager = NowPlayingManager.shared
        manager.clearNowPlaying()
        let player = NetflixWebView(
            url: URL(string: "about:blank")!,
            canGoBack: .constant(false), canGoForward: .constant(false), isLoading: .constant(false),
            commandCoordinator: NetflixWebView.CommandCoordinator(),
            autoSkipIntro: false, autoPlayNext: false, pureOledBlack: false
        )
        let window = NSWindow(contentRect: NSRect(x: 200, y: 200, width: 800, height: 600),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = NSHostingView(rootView: player)
        window.contentView?.layoutSubtreeIfNeeded()
        let webView = try XCTUnwrap(manager.webView)
        defer {
            window.contentView = nil
            manager.webView = nil
            manager.clearNowPlaying()
        }

        let ready = expectation(description: "player state available")
        let readySubscription = manager.$title.dropFirst().first(where: { $0 != nil }).sink { _ in ready.fulfill() }
        webView.loadHTMLString("<title>Watch Example | Netflix</title><video></video>",
                               baseURL: URL(string: "https://www.netflix.com/watch/test")!)
        wait(for: [ready], timeout: 10)
        XCTAssertFalse(manager.isMuted)

        let mediaSessionReady = expectation(description: "WebKit media session is populated")
        webView.evaluateJavaScript("""
            ({
                title: navigator.mediaSession.metadata && navigator.mediaSession.metadata.title,
                playbackState: navigator.mediaSession.playbackState
            })
            """) { result, error in
                XCTAssertNil(error)
                let state = result as? [String: Any]
                XCTAssertEqual(state?["title"] as? String, "Example")
                XCTAssertEqual(state?["playbackState"] as? String, "paused")
                mediaSessionReady.fulfill()
            }
        wait(for: [mediaSessionReady], timeout: 10)

        let muted = expectation(description: "mute reflected in app state")
        let mutedSubscription = manager.$isMuted.dropFirst().first(where: { $0 }).sink { _ in muted.fulfill() }
        manager.toggleMute()
        wait(for: [muted], timeout: 10)
        withExtendedLifetime(mutedSubscription) {}

        let unmuted = expectation(description: "unmute reflected in app state")
        let unmutedSubscription = manager.$isMuted.dropFirst().first(where: { !$0 }).sink { _ in unmuted.fulfill() }
        manager.toggleMute()
        wait(for: [unmuted], timeout: 10)
        withExtendedLifetime(unmutedSubscription) {}

        let externallyMuted = expectation(description: "external mute reflected in app state")
        let externalSubscription = manager.$isMuted.dropFirst().first(where: { $0 }).sink { _ in externallyMuted.fulfill() }
        webView.evaluateJavaScript("document.querySelector('video').muted = true")
        wait(for: [externallyMuted], timeout: 10)
        withExtendedLifetime((readySubscription, externalSubscription)) {}
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
        manager.updateNowPlaying(title: "Example", isPlaying: true)
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
        manager.updateNowPlaying(title: "Example", isPlaying: true)
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
