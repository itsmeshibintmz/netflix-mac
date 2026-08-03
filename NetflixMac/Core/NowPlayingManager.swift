// MARK: - NowPlayingManager.swift
// Manages macOS System Control Center & Lock Screen Now Playing Metadata & Media Remote Commands.

import Foundation
import MediaPlayer
import AppKit
import WebKit

final class NowPlayingManager: NSObject {
    static let shared = NowPlayingManager()

    private var currentTitle: String = ""
    private var currentSubtitle: String = ""
    private var currentArtworkURL: String = ""
    private var currentArtworkImage: NSImage? = nil

    // Weak reference to active WKWebView to trigger remote JS control actions
    weak var webView: WKWebView?

    override init() {
        super.init()
        setupRemoteCommandCenter()
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // 1. Play Command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.executeJS("let v = document.querySelector('video'); if (v) v.play();")
            return .success
        }

        // 2. Pause Command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.executeJS("let v = document.querySelector('video'); if (v) v.pause();")
            return .success
        }

        // 3. Toggle Play/Pause Command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.executeJS("let v = document.querySelector('video'); if (v) { v.paused ? v.play() : v.pause(); }")
            return .success
        }

        // 4. Next Track / Next Episode Command
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.executeJS("""
                let nextBtn = document.querySelector('button[data-uia="next-episode-seamless-button"], .watch-video--next-episode-button');
                if (nextBtn) nextBtn.click();
            """)
            return .success
        }

        // 5. Seek / Change Playback Position
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                let targetTime = positionEvent.positionTime
                self?.executeJS("let v = document.querySelector('video'); if (v) v.currentTime = \(targetTime);")
                return .success
            }
            return .commandFailed
        }
    }

    private func executeJS(_ code: String) {
        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript(code, completionHandler: nil)
        }
    }

    func updateNowPlaying(title: String, subtitle: String, duration: Double, currentTime: Double, isPlaying: Bool, artworkURL: String? = nil) {
        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = title.isEmpty ? "Netflix" : title
        nowPlayingInfo[MPMediaItemPropertyArtist] = subtitle.isEmpty ? "Netflix" : subtitle
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        if let artworkImage = currentArtworkImage {
            let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        // Fetch artwork asynchronously if artworkURL changed
        if let artURLString = artworkURL, !artURLString.isEmpty, artURLString != currentArtworkURL {
            currentArtworkURL = artURLString
            fetchArtwork(from: artURLString) { [weak self] image in
                guard let self = self, let image = image else { return }
                self.currentArtworkImage = image
                var updatedInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                updatedInfo[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
            }
        }
    }

    func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        currentArtworkImage = nil
        currentArtworkURL = ""
    }

    private func fetchArtwork(from urlString: String, completion: @escaping (NSImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = NSImage(data: data) else {
                completion(nil)
                return
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
