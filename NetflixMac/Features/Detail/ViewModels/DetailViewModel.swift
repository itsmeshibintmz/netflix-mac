// MARK: - DetailViewModel.swift
// Loads cast, videos, and recommendations for a selected media item.

import Foundation

@MainActor
final class DetailViewModel: ObservableObject {

    @Published var cast: [CastMember] = []
    @Published var crew: [CrewMember] = []
    @Published var videos: [VideoResult] = []
    @Published var recommendations: [MediaItem] = []
    @Published var detailedItem: MediaItem? = nil
    @Published var isLoading: Bool = false

    // MARK: - Computed
    var trailer: VideoResult? {
        videos.first { $0.isYouTubeTrailer }
    }

    var director: String {
        crew.first { $0.job == "Director" }?.name ?? ""
    }

    var writers: [String] {
        crew.filter { $0.job == "Screenplay" || $0.job == "Writer" }.map(\.name)
    }

    private let network = NetworkService.shared

    // MARK: - Load
    func loadDetails(for item: MediaItem) async {
        guard !isLoading else { return }
        isLoading = true
        let id = item.id
        let isMovie = item.isMovie

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadRichDetails(id: id, isMovie: isMovie) }
            group.addTask { await self.loadCredits(id: id, isMovie: isMovie) }
            group.addTask { await self.loadVideos(id: id, isMovie: isMovie) }
            group.addTask { await self.loadRecommendations(id: id, isMovie: isMovie) }
        }

        isLoading = false
    }

    private func loadRichDetails(id: Int, isMovie: Bool) async {
        do {
            detailedItem = isMovie
                ? try await network.fetchMovieDetails(id: id)
                : try await network.fetchTVDetails(id: id)
        } catch {}
    }

    private func loadCredits(id: Int, isMovie: Bool) async {
        do {
            let credits = try await network.fetchCredits(id: id, isMovie: isMovie)
            cast = Array(credits.cast.prefix(12))
            crew = credits.crew ?? []
        } catch {}
    }

    private func loadVideos(id: Int, isMovie: Bool) async {
        do { videos = try await network.fetchVideos(id: id, isMovie: isMovie) } catch {}
    }

    private func loadRecommendations(id: Int, isMovie: Bool) async {
        do {
            recommendations = try await network.fetchRecommendations(id: id, isMovie: isMovie)
        } catch {}
    }

    func reset() {
        cast = []; crew = []; videos = []; recommendations = []
        detailedItem = nil; isLoading = false
    }
}
