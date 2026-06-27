// MARK: - NetworkService.swift
// Async/await URLSession wrapper for TMDB API.

import Foundation

// MARK: - Network Error
enum NetworkError: LocalizedError {
    case invalidURL
    case decodingFailed(Error)
    case networkError(Error)
    case invalidResponse(Int)
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "⚠️ Please set your TMDB API key in APIConfig.swift\nGet a free key at: https://www.themoviedb.org/settings/api"
        case .invalidURL:
            return "Invalid request URL."
        case .decodingFailed(let e):
            return "Data decoding failed: \(e.localizedDescription)"
        case .networkError(let e):
            return "Network error: \(e.localizedDescription)"
        case .invalidResponse(let code):
            return "Server error \(code)."
        }
    }
}

// MARK: - Network Service
@MainActor
final class NetworkService: ObservableObject {

    static let shared = NetworkService()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.urlCache = URLCache(
            memoryCapacity:  50 * 1_024 * 1_024,   // 50 MB memory
            diskCapacity:   200 * 1_024 * 1_024,    // 200 MB disk
            directory: nil
        )
        cfg.requestCachePolicy = .returnCacheDataElseLoad
        cfg.timeoutIntervalForRequest = 15
        session = URLSession(configuration: cfg)
        decoder = JSONDecoder()
    }

    // MARK: - Generic Fetch
    func fetch<T: Decodable>(_ type: T.Type, from endpoint: APIEndpoint) async throws -> T {
        guard APIConfig.apiKey != "YOUR_TMDB_API_KEY_HERE", !APIConfig.apiKey.isEmpty else {
            throw NetworkError.noAPIKey
        }
        guard let url = endpoint.url else { throw NetworkError.invalidURL }

        do {
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw NetworkError.invalidResponse(http.statusCode)
            }
            return try decoder.decode(T.self, from: data)
        } catch let e as NetworkError { throw e }
          catch let e as DecodingError  { throw NetworkError.decodingFailed(e) }
          catch                         { throw NetworkError.networkError(error) }
    }

    // MARK: - Trending
    func fetchTrending() async throws -> [MediaItem] {
        try await fetch(MediaResponse.self, from: .trending()).results
    }

    // MARK: - Popular
    func fetchPopularMovies() async throws -> [MediaItem] {
        try await fetch(MediaResponse.self, from: .popular(mediaType: "movie")).results
    }
    func fetchPopularTV() async throws -> [MediaItem] {
        try await fetch(MediaResponse.self, from: .popular(mediaType: "tv")).results
    }

    // MARK: - Top Rated
    func fetchTopRated(mediaType: String) async throws -> [MediaItem] {
        try await fetch(MediaResponse.self, from: .topRated(mediaType: mediaType)).results
    }

    // MARK: - Now Playing / Upcoming / Airing
    func fetchNowPlaying()  async throws -> [MediaItem] {
        try await fetch(MediaResponse.self, from: .nowPlaying).results
    }
    func fetchUpcoming()    async throws -> [MediaItem] {
        try await fetch(MediaResponse.self, from: .upcomingMovies).results
    }
    func fetchAiringToday() async throws -> [MediaItem] {
        try await fetch(MediaResponse.self, from: .airingToday).results
    }

    // MARK: - Search
    func search(query: String, page: Int = 1) async throws -> [MediaItem] {
        guard !query.isEmpty else { return [] }
        let results = try await fetch(MediaResponse.self, from: .search(query: query, page: page)).results
        return results.filter { $0.mediaType != "person" }
    }

    // MARK: - Details
    func fetchMovieDetails(id: Int) async throws -> MediaItem {
        try await fetch(MediaItem.self, from: .movieDetails(id: id))
    }
    func fetchTVDetails(id: Int) async throws -> MediaItem {
        try await fetch(MediaItem.self, from: .tvDetails(id: id))
    }

    // MARK: - Credits
    func fetchCredits(id: Int, isMovie: Bool) async throws -> CreditsResponse {
        let ep: APIEndpoint = isMovie ? .movieCredits(id: id) : .tvCredits(id: id)
        return try await fetch(CreditsResponse.self, from: ep)
    }

    // MARK: - Videos
    func fetchVideos(id: Int, isMovie: Bool) async throws -> [VideoResult] {
        let ep: APIEndpoint = isMovie ? .movieVideos(id: id) : .tvVideos(id: id)
        return try await fetch(VideosResponse.self, from: ep).results
    }

    // MARK: - Recommendations
    func fetchRecommendations(id: Int, isMovie: Bool) async throws -> [MediaItem] {
        let ep: APIEndpoint = isMovie ? .movieRecommendations(id: id) : .tvRecommendations(id: id)
        return try await fetch(MediaResponse.self, from: ep).results
    }

    // MARK: - Genres
    func fetchGenres(mediaType: String) async throws -> [Genre] {
        try await fetch(GenreResponse.self, from: .genres(mediaType: mediaType)).genres
    }
}
