// MARK: - NowPlayingManager.swift
// Tracks playback state and controls the web player.
// WebKit publishes the single macOS Now Playing session through Media Session.

import Foundation
import WebKit
import Combine
import OSLog

final class NowPlayingManager: ObservableObject {
    static let shared = NowPlayingManager()

    @Published private(set) var title: String?
    @Published private(set) var isPlaying = false
    @Published private(set) var isMuted = false

    private let logger = Logger(subsystem: "com.personal.Netflix", category: "Playback")

    weak var webView: WKWebView?

    func togglePlayPause() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let webView = self.webView else {
                self.logger.error("Playback command failed: no web view is available")
                return
            }
            webView.callAsyncJavaScript("""
                const video = document.querySelector('video');
                if (!video) throw new Error('No video is available');
                if (video.paused) await video.play();
                else video.pause();
                """, arguments: [:], in: nil, in: .page) { result in
                    if case .failure(let error) = result {
                        self.logger.error("Playback command failed: \(error.localizedDescription, privacy: .private)")
                    }
                }
        }
    }

    func pausePlayback(completion: @escaping (Error?) -> Void) {
        guard let webView else {
            let error = NSError(domain: "NetflixPlayback", code: 1,
                                userInfo: [NSLocalizedDescriptionKey: "No Netflix player is available."])
            logger.error("Playback command failed: no web view is available")
            completion(error)
            return
        }
        webView.evaluateJavaScript("""
            (() => {
                const video = document.querySelector('video');
                if (!video) return false;
                video.pause();
                return true;
            })();
            """) { result, error in
            if let error {
                self.logger.error("Playback command failed: \(error.localizedDescription, privacy: .private)")
                completion(error)
            } else if (result as? Bool) == true {
                completion(nil)
            } else {
                let error = NSError(domain: "NetflixPlayback", code: 2,
                                    userInfo: [NSLocalizedDescriptionKey: "No Netflix video is available."])
                self.logger.error("Playback command failed: no video is available")
                completion(error)
            }
        }
    }

    func toggleMute() {
        executeJS("""
            (() => {
                const video = document.querySelector('video');
                if (!video) throw new Error('No video is available');
                video.muted = !video.muted;
            })();
            """)
    }

    func updateMutedState(_ isMuted: Bool) {
        if self.isMuted != isMuted {
            self.isMuted = isMuted
        }
    }

    private func executeJS(_ code: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let webView = self.webView else {
                self.logger.error("Playback command failed: no web view is available")
                return
            }
            webView.evaluateJavaScript(code) { _, error in
                if let error {
                    self.logger.error("Playback command failed: \(error.localizedDescription, privacy: .private)")
                }
            }
        }
    }

    func updateNowPlaying(title: String, isPlaying: Bool) {
        self.title = title.isEmpty ? "Netflix" : title
        self.isPlaying = isPlaying
    }

    func clearNowPlaying() {
        title = nil
        isPlaying = false
        isMuted = false
    }
}
