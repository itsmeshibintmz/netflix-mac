// MARK: - VideoPlayerView.swift
// AVKit-based player with custom Liquid Glass controls, PiP, and keyboard shortcuts.

import SwiftUI
import AVKit
import Combine

struct VideoPlayerView: View {
    let item: MediaItem
    let streamURL: URL

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var playback: PlaybackManager

    @State private var player: AVPlayer? = nil
    @State private var isPlaying = false
    @State private var showControls = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var volume: Double = 1.0
    @State private var isMuted = false
    @State private var isFullscreen = false
    @State private var controlsTimer: Timer? = nil
    @State private var pipController: AVPictureInPictureController? = nil
    @State private var timeObserver: Any? = nil
    @State private var keyMonitor: Any? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // MARK: AVPlayer View
            if let player {
                VideoPlayerWrapper(player: player)
                    .ignoresSafeArea()
                    .onTapGesture { toggleControls() }
            }

            // MARK: Controls Overlay
            if showControls {
                controlsOverlay
                    .transition(.opacity)
            }
        }
        .onAppear {
            setupPlayer()
            // NSEvent key monitor — works on macOS 13+
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                switch event.keyCode {
                case 49:  self.togglePlayPause();       return nil  // Space
                case 124: self.seekForward();            return nil  // →
                case 123: self.seekBackward();           return nil  // ←
                case 126: self.adjustVolume(by: 0.1);   return nil  // ↑
                case 125: self.adjustVolume(by: -0.1);  return nil  // ↓
                default:  return event
                }
            }
        }
        .onDisappear {
            teardownPlayer()
            if let monitor = keyMonitor { NSEvent.removeMonitor(monitor); keyMonitor = nil }
        }
        .frame(minWidth: 640, minHeight: 400)
    }

    // MARK: - Controls Overlay
    private var controlsOverlay: some View {
        ZStack {
            // Gradient at top and bottom
            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.7), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 100)
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 160)
            }

            VStack {
                // MARK: Top Bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .liquidGlass(cornerRadius: 22)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(item.displayTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    // PiP Button
                    Button {
                        pipController?.startPictureInPicture()
                    } label: {
                        Image(systemName: "pip.enter")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .liquidGlass(cornerRadius: 22)
                    }
                    .buttonStyle(.plain)
                    .help("Picture in Picture (⌘⇧P)")
                }
                .padding(20)

                Spacer()

                // MARK: Bottom Controls
                VStack(spacing: 14) {
                    // Scrubber
                    HStack(spacing: 12) {
                        Text(timeString(currentTime))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 48)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                // Track
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(.white.opacity(0.2))
                                    .frame(height: 4)

                                // Progress
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.netflixRed)
                                    .frame(width: duration > 0 ? geo.size.width * (currentTime / duration) : 0, height: 4)

                                // Thumb
                                Circle()
                                    .fill(.white)
                                    .frame(width: 14, height: 14)
                                    .shadow(radius: 4)
                                    .offset(x: duration > 0 ? geo.size.width * (currentTime / duration) - 7 : -7)
                            }
                            .frame(height: 4)
                            .frame(maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let fraction = max(0, min(1, value.location.x / geo.size.width))
                                        let target = fraction * duration
                                        player?.seek(to: CMTime(seconds: target, preferredTimescale: 600),
                                                     toleranceBefore: .zero, toleranceAfter: .zero)
                                    }
                            )
                        }
                        .frame(height: 20)

                        Text(timeString(duration))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 48)
                    }

                    // Buttons row
                    HStack(spacing: 20) {
                        // Skip Back
                        NetflixIconButton(icon: "gobackward.10", tooltip: "Rewind 10s (←)") {
                            seekBackward()
                        }

                        // Play/Pause
                        NetflixIconButton(
                            icon: isPlaying ? "pause.fill" : "play.fill",
                            tooltip: isPlaying ? "Pause (Space)" : "Play (Space)",
                            size: 56
                        ) {
                            togglePlayPause()
                        }

                        // Skip Forward
                        NetflixIconButton(icon: "goforward.10", tooltip: "Forward 10s (→)") {
                            seekForward()
                        }

                        Spacer()

                        // Volume
                        HStack(spacing: 8) {
                            Button {
                                isMuted.toggle()
                                player?.isMuted = isMuted
                            } label: {
                                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(.plain)

                            Slider(value: $volume, in: 0...1) { _ in
                                player?.volume = Float(volume)
                            }
                            .frame(width: 100)
                            .tint(Color.netflixRed)
                        }

                        // Fullscreen
                        NetflixIconButton(
                            icon: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                            tooltip: "Fullscreen (⌘F)"
                        ) {
                            toggleFullscreen()
                        }
                    }
                }
                .padding(20)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showControls)
    }

    // MARK: - Setup
    private func setupPlayer() {
        let avPlayer = AVPlayer(url: streamURL)
        self.player = avPlayer

        // Resume position
        let resumeTime = playback.resumePosition(for: item)
        if resumeTime > 5 {
            avPlayer.seek(to: CMTime(seconds: resumeTime, preferredTimescale: 600))
        }

        avPlayer.play()
        isPlaying = true

        // Time observer
        timeObserver = avPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [self] time in
            currentTime = time.seconds
            if let d = avPlayer.currentItem?.duration.seconds, d.isFinite {
                duration = d
            }
            // Save position
            if currentTime.truncatingRemainder(dividingBy: 5) < 0.6 {
                playback.savePosition(for: item, position: currentTime)
            }
        }

        // PiP
        if let layer = (NSApplication.shared.windows.first?.contentView as? NSView) as? AVPlayerLayer {
            if AVPictureInPictureController.isPictureInPictureSupported() {
                pipController = AVPictureInPictureController(playerLayer: layer)
            }
        }

        startControlsTimer()
    }

    private func teardownPlayer() {
        controlsTimer?.invalidate()
        if let observer = timeObserver { player?.removeTimeObserver(observer) }
        playback.savePosition(for: item, position: currentTime)
        player?.pause()
        player = nil
    }

    // MARK: - Controls
    private func togglePlayPause() {
        guard let player else { return }
        if isPlaying { player.pause() } else { player.play() }
        isPlaying.toggle()
        resetControlsTimer()
    }

    private func seekForward()  { seek(by: 10) }
    private func seekBackward() { seek(by: -10) }

    private func seek(by seconds: Double) {
        guard let player else { return }
        let target = CMTime(seconds: max(0, currentTime + seconds), preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        resetControlsTimer()
    }

    private func adjustVolume(by delta: Double) {
        volume = max(0, min(1, volume + delta))
        player?.volume = Float(volume)
    }

    private func toggleControls() {
        withAnimation { showControls.toggle() }
        if showControls { resetControlsTimer() }
    }

    private func toggleFullscreen() {
        NSApp.mainWindow?.toggleFullScreen(nil)
        isFullscreen.toggle()
    }

    private func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            withAnimation { self.showControls = false }
        }
    }

    private func resetControlsTimer() {
        withAnimation { showControls = true }
        startControlsTimer()
    }

    private func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let h = Int(seconds) / 3600
        let m = Int(seconds) % 3600 / 60
        let s = Int(seconds) % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}

// MARK: - AVPlayer NSViewRepresentable
struct VideoPlayerWrapper: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none   // we use custom controls
        view.showsTimecodes = false
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}
