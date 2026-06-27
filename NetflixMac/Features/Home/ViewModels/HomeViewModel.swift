// MARK: - HomeViewModel.swift
// Loads and manages all content rows for the home screen.

import Foundation
import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Content Rows
    @Published var trendingItems:   [MediaItem] = []
    @Published var popularMovies:   [MediaItem] = []
    @Published var popularTV:       [MediaItem] = []
    @Published var topRatedMovies:  [MediaItem] = []
    @Published var nowPlaying:      [MediaItem] = []
    @Published var upcoming:        [MediaItem] = []
    @Published var airingToday:     [MediaItem] = []

    // MARK: - Hero Banner
    @Published var heroBannerItems:  [MediaItem] = []
    @Published var currentHeroIndex: Int = 0

    // MARK: - State
    @Published var isLoading:    Bool = false
    @Published var errorMessage: String? = nil

    private let network = NetworkService.shared
    private var heroTimer: Timer?

    // MARK: - Computed rows
    var contentRows: [(title: String, items: [MediaItem])] {
        [
            ("Trending Now",     trendingItems),
            ("Now In Cinemas",   nowPlaying),
            ("Popular Movies",   popularMovies),
            ("Popular TV Shows", popularTV),
            ("Top Rated",        topRatedMovies),
            ("Coming Soon",      upcoming),
            ("Airing Today",     airingToday),
        ].filter { !$0.items.isEmpty }
    }

    var currentHeroItem: MediaItem? {
        guard !heroBannerItems.isEmpty else { return nil }
        return heroBannerItems[currentHeroIndex % heroBannerItems.count]
    }

    // MARK: - Load (async let = true parallelism, stays on @MainActor)
    func loadContent() async {
        guard !isLoading else { return }
        isLoading    = true
        errorMessage = nil

        async let t  = network.fetchTrending()
        async let pm = network.fetchPopularMovies()
        async let pt = network.fetchPopularTV()
        async let tr = network.fetchTopRated(mediaType: "movie")
        async let np = network.fetchNowPlaying()
        async let up = network.fetchUpcoming()
        async let at = network.fetchAiringToday()

        trendingItems  = (try? await t)  ?? []
        popularMovies  = (try? await pm) ?? []
        popularTV      = (try? await pt) ?? []
        topRatedMovies = (try? await tr) ?? []
        nowPlaying     = (try? await np) ?? []
        upcoming       = (try? await up) ?? []
        airingToday    = (try? await at) ?? []

        isLoading       = false
        heroBannerItems = Array(trendingItems.prefix(6))
        startHeroTimer()
    }

    func refresh() async { await loadContent() }

    // MARK: - Hero Timer
    func startHeroTimer() {
        heroTimer?.invalidate()
        guard heroBannerItems.count > 1 else { return }
        heroTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                withAnimation(.easeInOut(duration: 0.9)) {
                    self.currentHeroIndex = (self.currentHeroIndex + 1) % self.heroBannerItems.count
                }
            }
        }
    }

    func stopHeroTimer() { heroTimer?.invalidate() }

    deinit { heroTimer?.invalidate() }
}
