// MARK: - MiniPlayerView.swift
// Status bar / menu bar mini player.

import SwiftUI
import AVKit

struct MiniPlayerView: View {
    @EnvironmentObject var playback: PlaybackManager

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.netflixRed)
                Text("Netflix")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Spacer()
            }

            if let item = playback.currentItem {
                // Now Playing
                HStack(spacing: 12) {
                    AsyncPosterImage(url: item.posterURL)
                        .frame(width: 52, height: 78)
                        .smoothCorners(6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.displayTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text(item.year)
                            .font(.caption)
                            .foregroundStyle(.netflixLightGray)

                        // Play/Pause
                        HStack(spacing: 16) {
                            Button {
                                playback.isPlaying.toggle()
                            } label: {
                                Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.netflixRed)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "tv.slash")
                        .font(.system(size: 28))
                        .foregroundStyle(.netflixMidGray)
                    Text("Nothing playing")
                        .font(.subheadline)
                        .foregroundStyle(.netflixLightGray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .padding(16)
        .background(Color.netflixDarkBG)
        .preferredColorScheme(.dark)
    }
}
