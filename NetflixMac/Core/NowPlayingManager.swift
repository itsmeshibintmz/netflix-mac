// MARK: - NowPlayingManager.swift
// Drives macOS Control Center & Lock Screen Now Playing metadata via MPNowPlayingInfoCenter.
// navigator.mediaSession in WKWebView does NOT bridge to the system - this native class does.

import Foundation
import MediaPlayer
import AppKit
import WebKit

final class NowPlayingManager: NSObject {
    static let shared = NowPlayingManager()

    private var currentArtworkURL: String = ""
    private var currentArtworkImage: NSImage? = nil

    weak var webView: WKWebView?

    override init() {
        super.init()
        setupRemoteCommandCenter()
    }

    private func setupRemoteCommandCenter() {
        let cc = MPRemoteCommandCenter.shared()

        cc.playCommand.isEnabled = true
        cc.playCommand.addTarget { [weak self] _ in
            self?.executeJS("let v=document.querySelector('video');if(v)v.play();")
            return .success
        }

        cc.pauseCommand.isEnabled = true
        cc.pauseCommand.addTarget { [weak self] _ in
            self?.executeJS("let v=document.querySelector('video');if(v)v.pause();")
            return .success
        }

        cc.togglePlayPauseCommand.isEnabled = true
        cc.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.executeJS("let v=document.querySelector('video');if(v){v.paused?v.play():v.pause();}")
            return .success
        }

        // Next episode — enabled dynamically when Netflix shows the next episode button
        cc.nextTrackCommand.isEnabled = false
        cc.nextTrackCommand.addTarget { [weak self] _ in
            self?.executeJS("let nb=document.querySelector('button[data-uia=\"next-episode-seamless-button\"],.watch-video--next-episode-button,[data-uia=\"next-episode-button\"]');if(nb)nb.click();")
            return .success
        }

        // Previous track — not applicable on Netflix (no previous episode button in player)
        cc.previousTrackCommand.isEnabled = false

        // Seek backward/forward (10s scrub) — always enabled during playback
        cc.seekBackwardCommand.isEnabled = true
        cc.seekBackwardCommand.addTarget { [weak self] _ in
            self?.executeJS("let v=document.querySelector('video');if(v)v.currentTime=Math.max(0,v.currentTime-10);")
            return .success
        }
        cc.seekForwardCommand.isEnabled = true
        cc.seekForwardCommand.addTarget { [weak self] _ in
            self?.executeJS("let v=document.querySelector('video');if(v)v.currentTime=Math.min(v.duration,v.currentTime+10);")
            return .success
        }

        cc.changePlaybackPositionCommand.isEnabled = true
        cc.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let e = event as? MPChangePlaybackPositionCommandEvent {
                let t = e.positionTime
                self?.executeJS("let v=document.querySelector('video');if(v)v.currentTime=\(t);")
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

    func updateNowPlaying(title: String, subtitle: String, duration: Double, currentTime: Double, isPlaying: Bool, artworkURL: String?, hasNext: Bool = false) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = title.isEmpty ? "Netflix" : title
        info[MPMediaItemPropertyArtist] = subtitle.isEmpty ? "Netflix" : subtitle
        info[MPMediaItemPropertyAlbumTitle] = "Netflix"
        info[MPMediaItemPropertyMediaType] = MPNowPlayingInfoMediaType.video.rawValue
        if duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        }
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        if let img = currentArtworkImage ?? NSApp.applicationIconImage {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        // Claim active player status so our process wins over WKWebView's WebContent process
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused

        // Dynamically show/hide the ⏭ Next Episode button in Control Center
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = hasNext

        if let urlStr = artworkURL, !urlStr.isEmpty, urlStr != currentArtworkURL {
            currentArtworkURL = urlStr
            fetchArtwork(from: urlStr) { [weak self] image in
                guard let self = self, let image = image else { return }
                self.currentArtworkImage = image
                var updated = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                updated[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                MPNowPlayingInfoCenter.default().nowPlayingInfo = updated
            }
        }
    }

    func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        currentArtworkImage = nil
        currentArtworkURL = ""
    }

    private func fetchArtwork(from urlString: String, completion: @escaping (NSImage?) -> Void) {
        guard let url = URL(string: urlString) else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            let image = data.flatMap { NSImage(data: $0) }
            DispatchQueue.main.async { completion(image) }
        }.resume()
    }
}
