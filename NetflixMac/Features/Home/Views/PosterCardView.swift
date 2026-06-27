// MARK: - PosterCardView.swift
// Individual poster card with hover lift, glow, and progress bar.

import SwiftUI

struct PosterCardView: View {
    let item: MediaItem
    var width: CGFloat = 160
    var height: CGFloat = 240
    let onTap: () -> Void

    @State private var isHovered = false
    @EnvironmentObject var watchlist: WatchlistManager
    @EnvironmentObject var playback: PlaybackManager

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                // MARK: Poster Image
                AsyncPosterImage(url: item.posterURL)
                    .frame(width: width, height: height)

                // MARK: Gradient Overlay
                LinearGradient.netflixCard
                    .frame(height: height * 0.5)
                    .frame(maxHeight: .infinity, alignment: .bottom)

                // MARK: Info Overlay
                VStack(alignment: .leading, spacing: 4) {
                    // Progress bar (resume watching)
                    if playback.hasResumePoint(for: item) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.white.opacity(0.25))
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.netflixRed)
                                    .frame(width: geo.size.width * playback.progressFraction(for: item, duration: 7200))
                            }
                        }
                        .frame(height: 3)
                    }

                    Text(item.displayTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        if let r = item.voteAverage { RatingBadge(rating: r) }
                        Text(item.year)
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)

                // MARK: Hover Quick-Actions
                if isHovered {
                    HStack(spacing: 8) {
                        WatchlistButton(item: item)
                            .scaleEffect(0.8)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .frame(width: width, height: height)
            .smoothCorners(10)
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isHovered ? Color.white.opacity(0.4) : .clear,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.06 : 1.0)
        .shadow(
            color: .black.opacity(isHovered ? 0.6 : 0.25),
            radius: isHovered ? 20 : 8,
            y: isHovered ? 10 : 4
        )
        .onHover { h in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) { isHovered = h }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isHovered)
    }
}
