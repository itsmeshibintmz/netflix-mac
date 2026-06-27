// MARK: - HeroBannerView.swift
// Full-bleed hero banner with backdrop, gradient overlay, and action buttons.

import SwiftUI

struct HeroBannerView: View {
    let items: [MediaItem]
    @Binding var currentIndex: Int
    let onPlay: (MediaItem) -> Void
    let onMoreInfo: (MediaItem) -> Void

    @EnvironmentObject var watchlist: WatchlistManager

    private var currentItem: MediaItem? {
        guard !items.isEmpty else { return nil }
        return items[currentIndex % items.count]
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {

                // MARK: Backdrop Image
                if let item = currentItem {
                    AsyncPosterImage(url: item.backdropURL, cornerRadius: 0, contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .id(item.id)   // force refresh on item change
                        .transition(.opacity)
                }

                // MARK: Gradient Overlays
                LinearGradient(
                    colors: [.clear, Color.netflixBlack.opacity(0.4), Color.netflixBlack],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Left-side vignette
                LinearGradient(
                    colors: [Color.netflixBlack.opacity(0.5), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                // MARK: Content
                if let item = currentItem {
                    VStack(alignment: .leading, spacing: 16) {
                        Spacer()

                        // Title
                        Text(item.displayTitle)
                            .font(.system(size: 46, weight: .black, design: .default))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.6), radius: 8, y: 4)
                            .lineLimit(2)
                            .frame(maxWidth: geo.size.width * 0.55, alignment: .leading)
                            .id("title-\(item.id)")
                            .transition(.opacity.combined(with: .move(edge: .bottom)))

                        // Badges row
                        HStack(spacing: 10) {
                            if let r = item.voteAverage { RatingBadge(rating: r) }
                            MaturityBadge(label: item.maturityRating)
                            if !item.year.isEmpty {
                                Text(item.year)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            if !item.runtimeString.isEmpty {
                                Text(item.runtimeString)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }

                        // Overview
                        if let overview = item.overview, !overview.isEmpty {
                            Text(overview)
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(3)
                                .frame(maxWidth: geo.size.width * 0.45, alignment: .leading)
                        }

                        // Action Buttons
                        HStack(spacing: 12) {
                            NetflixPrimaryButton("▶  Play", action: { onPlay(item) })
                            NetflixSecondaryButton("More Info", icon: "info.circle", action: { onMoreInfo(item) })
                            WatchlistButton(item: item)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 50)
                    .animation(.easeInOut(duration: 0.5), value: item.id)
                }

                // MARK: Dot Indicators
                if items.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<min(items.count, 6), id: \.self) { i in
                            Capsule()
                                .fill(i == currentIndex % items.count ? Color.white : Color.white.opacity(0.35))
                                .frame(width: i == currentIndex % items.count ? 20 : 6, height: 6)
                                .animation(.spring(response: 0.3), value: currentIndex)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.5)) { currentIndex = i }
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(20)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }
}
