// MARK: - DetailView.swift
// Full detail sheet: backdrop, info, cast, trailer, recommendations.

import SwiftUI

struct DetailView: View {
    let item: MediaItem
    @Binding var showDetail: Bool
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = DetailViewModel()
    @EnvironmentObject var watchlist: WatchlistManager
    @EnvironmentObject var playback: PlaybackManager

    @State private var showPlayer = false
    @State private var playerURL: URL? = nil

    var displayItem: MediaItem { vm.detailedItem ?? item }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.netflixBlack.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Backdrop Hero
                    backdropSection

                    // MARK: Body Content
                    VStack(alignment: .leading, spacing: 28) {
                        metaSection
                        if !vm.cast.isEmpty { CastScrollView(cast: vm.cast) }
                        if !vm.recommendations.isEmpty { recommendationsSection }
                    }
                    .padding(32)
                }
            }

            // MARK: Close Button
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .liquidGlass(cornerRadius: 18)
            }
            .buttonStyle(.plain)
            .padding(20)
        }
        .frame(minWidth: 760, minHeight: 640)
        .sheet(isPresented: $showPlayer) {
            if let url = playerURL {
                VideoPlayerView(item: item, streamURL: url)
                    .frame(minWidth: 900, minHeight: 550)
            }
        }
        .task { await vm.loadDetails(for: item) }
        .onDisappear { vm.reset() }
    }

    // MARK: - Backdrop Section
    private var backdropSection: some View {
        ZStack(alignment: .bottom) {
            // Backdrop image
            AsyncPosterImage(url: displayItem.backdropURL ?? displayItem.posterURL,
                             cornerRadius: 0, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .clipped()

            // Gradient
            LinearGradient(
                colors: [.clear, Color.netflixBlack.opacity(0.5), Color.netflixBlack],
                startPoint: UnitPoint(x: 0.5, y: 0.2),
                endPoint: .bottom
            )
            .frame(height: 380)

            // Play + Info buttons
            HStack(spacing: 14) {
                // Trailer button (YouTube)
                if let trailer = vm.trailer {
                    NetflixPrimaryButton("▶  Play Trailer", icon: nil) {
                        playerURL = trailer.youtubeURL
                        showPlayer = true
                    }
                } else if vm.isLoading {
                    ProgressView().tint(Color.netflixRed)
                } else {
                    NetflixPrimaryButton("▶  Watch", icon: nil) {
                        // Demo: open YouTube search
                        if let url = URL(string: "https://www.youtube.com/results?search_query=\(item.displayTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }

                WatchlistButton(item: displayItem)

                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Meta Section
    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title
            Text(displayItem.displayTitle)
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(.white)

            // Badges
            HStack(spacing: 10) {
                if let r = displayItem.voteAverage { RatingBadge(rating: r) }
                MaturityBadge(label: displayItem.maturityRating)
                if !displayItem.year.isEmpty {
                    Text(displayItem.year).foregroundStyle(Color.netflixLightGray)
                }
                if displayItem.isMovie && !displayItem.runtimeString.isEmpty {
                    Text(displayItem.runtimeString).foregroundStyle(Color.netflixLightGray)
                } else if let s = displayItem.numberOfSeasons {
                    Text("\(s) Season\(s == 1 ? "" : "s")").foregroundStyle(Color.netflixLightGray)
                }
            }
            .font(.system(size: 13))

            // Tagline
            if let tagline = displayItem.tagline, !tagline.isEmpty {
                Text("\"\(tagline)\"")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.netflixLightGray)
                    .italic()
            }

            // Overview
            if let overview = displayItem.overview, !overview.isEmpty {
                Text(overview)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Director / Creator
            if !vm.director.isEmpty {
                HStack(spacing: 6) {
                    Text("Director:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.netflixLightGray)
                    Text(vm.director)
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - Recommendations
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More Like This")
                .font(.title3.bold())
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(vm.recommendations.prefix(12)) { rec in
                        PosterCardView(item: rec, width: 140, height: 210) {
                            // Navigate to new detail
                        }
                    }
                }
            }
        }
    }
}
