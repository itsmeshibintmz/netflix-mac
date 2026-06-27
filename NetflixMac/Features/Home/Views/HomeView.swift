// MARK: - HomeView.swift
// Main home screen: hero banner + lazy content rows.

import SwiftUI

struct HomeView: View {
    @Binding var selectedMedia: MediaItem?
    @Binding var showDetail: Bool

    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject var watchlist: WatchlistManager
    @EnvironmentObject var playback: PlaybackManager

    var body: some View {
        ZStack(alignment: .top) {
            // Dark background
            Color.netflixBlack.ignoresSafeArea()

            if vm.isLoading && vm.trendingItems.isEmpty {
                // MARK: Initial Loading State
                loadingView
            } else if let error = vm.errorMessage, vm.trendingItems.isEmpty {
                // MARK: Error State
                errorView(message: error)
            } else {
                // MARK: Content
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 28) {

                        // Hero Banner (approx 62vh)
                        GeometryReader { geo in
                            let bannerHeight = max(geo.size.height * 0.62, 420)
                            HeroBannerView(
                                items: vm.heroBannerItems,
                                currentIndex: $vm.currentHeroIndex,
                                onPlay: { item in
                                    playback.currentItem = item
                                    selectedMedia = item
                                },
                                onMoreInfo: { item in
                                    selectedMedia = item
                                }
                            )
                            .frame(height: bannerHeight)
                        }
                        .frame(height: 500)

                        // Top 10 Row
                        if !vm.trendingItems.isEmpty {
                            TopTenRowView(items: vm.trendingItems) { item in
                                selectedMedia = item
                            }
                        }

                        // Content Rows
                        ForEach(vm.contentRows, id: \.title) { row in
                            ContentRowView(
                                title: row.title,
                                items: row.items,
                                onSelect: { item in selectedMedia = item }
                            )
                        }

                        // My List (if not empty)
                        if !watchlist.isEmpty {
                            ContentRowView(
                                title: "My List",
                                items: watchlist.items,
                                onSelect: { item in selectedMedia = item }
                            )
                        }

                        Spacer(minLength: 60)
                    }
                }
                .refreshable { await vm.refresh() }
            }
        }
        .task { await vm.loadContent() }
        .onDisappear { vm.stopHeroTimer() }
        .navigationTitle("")
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.netflixRed)
            Text("Loading content…")
                .font(.headline)
                .foregroundStyle(Color.netflixLightGray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.netflixRed)
            Text("Could not load content")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(message)
                .font(.callout)
                .foregroundStyle(Color.netflixLightGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            NetflixPrimaryButton("Try Again") {
                Task { await vm.loadContent() }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
