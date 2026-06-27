// MARK: - HomeViewModel.swift
// Loads and manages all content rows for the home screen.

import Foundation
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
    @Published var heroBannerItems: [MediaItem] = []
    @Published var currentHeroIndex: Int = 0

    // MARK: - State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let network = NetworkService.shared
    private var heroTimer: Timer?

    // MARK: - Computed: all rows for home scroll
    var contentRows: [(title: String, items: [MediaItem])] {
        [
            ("Trending Now",      trendingItems),
            ("Now In Cinemas",    nowPlaying),
            ("Popular Movies",    popularMovies),
            ("Popular TV Shows",  popularTV),
            ("Top Rated",         topRatedMovies),
            ("Coming Soon",       upcoming),
            ("Airing Today",      airingToday),
        ].filter { !$0.items.isEmpty }
    }

    var currentHeroItem: MediaItem? {
        guard !heroBannerItems.isEmpty else { return nil }
        return heroBannerItems[currentHeroIndex % heroBannerItems.count]
    }

    // MARK: - Load
    func loadContent() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.safeFetch { self.trendingItems  = try await self.network.fetchTrending() } }
            group.addTask { await self.safeFetch { self.popularMovies  = try await self.network.fetchPopularMovies() } }
            group.addTask { await self.safeFetch { self.popularTV      = try await self.network.fetchPopularTV() } }
            group.addTask { await self.safeFetch { self.topRatedMovies = try await self.network.fetchTopRated(mediaType: "movie") } }
            group.addTask { await self.safeFetch { self.nowPlaying     = try await self.network.fetchNowPlaying() } }
            group.addTask { await self.safeFetch { self.upcoming       = try await self.network.fetchUpcoming() } }
            group.addTask { await self.safeFetch { self.airingToday    = try await self.network.fetchAiringToday() } }
        }

        isLoading = false
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
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.9)) {
                    self.currentHeroIndex = (self.currentHeroIndex + 1) % self.heroBannerItems.count
                }
            }
        }
    }

    func stopHeroTimer() { heroTimer?.invalidate() }

    // MARK: - Helper
    private func safeFetch(_ block: @escaping () async throws -> Void) async {
        do { try await block() } catch {
            if errorMessage == nil { errorMessage = error.localizedDescription }
        }
    }

    deinit { heroTimer?.invalidate() }
}
