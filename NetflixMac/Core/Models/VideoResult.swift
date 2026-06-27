// MARK: - VideoResult.swift
// Trailer / Video model from TMDB Videos endpoint.

import Foundation

struct VideoResult: Identifiable, Codable {
    let id: String
    let key: String
    let name: String
    let site: String
    let type: String
    let official: Bool?

    var isYouTubeTrailer: Bool {
        site.lowercased() == "youtube" &&
        (type.lowercased() == "trailer" || type.lowercased() == "teaser")
    }

    var youtubeURL: URL? {
        URL(string: "https://www.youtube.com/watch?v=\(key)")
    }

    var youtubeThumbnailURL: URL? {
        URL(string: "https://img.youtube.com/vi/\(key)/hqdefault.jpg")
    }
}

struct VideosResponse: Codable {
    let results: [VideoResult]
}
