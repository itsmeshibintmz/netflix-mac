// MARK: - MediaItem.swift
// Unified model for movies & TV shows from TMDB API.

import Foundation

// MARK: - MediaItem
struct MediaItem: Identifiable, Codable, Hashable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let voteCount: Int?
    let popularity: Double?
    let genreIds: [Int]?
    let mediaType: String?
    let adult: Bool?
    let runtime: Int?
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let tagline: String?
    let status: String?

    // MARK: Computed
    var displayTitle: String { title ?? name ?? "Unknown" }
    var displayDate: String  { releaseDate ?? firstAirDate ?? "" }
    var year: String         { String(displayDate.prefix(4)) }

    var isMovie: Bool {
        if let mt = mediaType { return mt == "movie" }
        return title != nil
    }

    var posterURL: URL?   { APIConfig.posterURL(posterPath) }
    var backdropURL: URL? { APIConfig.backdropURL(backdropPath) }

    var ratingString: String {
        guard let r = voteAverage else { return "N/A" }
        return String(format: "%.1f", r)
    }

    var ratingPercent: Double { (voteAverage ?? 0) / 10.0 }

    var runtimeString: String {
        guard let r = runtime, r > 0 else { return "" }
        let h = r / 60; let m = r % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    var maturityRating: String {
        guard let r = voteAverage else { return "NR" }
        return r >= 7 ? "TV-14" : "TV-MA"
    }

    // MARK: Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, title, name, overview, adult, popularity, runtime, tagline, status
        case posterPath       = "poster_path"
        case backdropPath     = "backdrop_path"
        case releaseDate      = "release_date"
        case firstAirDate     = "first_air_date"
        case voteAverage      = "vote_average"
        case voteCount        = "vote_count"
        case genreIds         = "genre_ids"
        case mediaType        = "media_type"
        case numberOfSeasons  = "number_of_seasons"
        case numberOfEpisodes = "number_of_episodes"
    }
}

// MARK: - Paged Response
struct MediaResponse: Codable {
    let page: Int
    let results: [MediaItem]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages   = "total_pages"
        case totalResults = "total_results"
    }
}
