// MARK: - APIConfig.swift
// Netflix macOS — TMDB API Configuration
//
// ⚠️  ACTION REQUIRED: Replace "YOUR_TMDB_API_KEY_HERE" with your free API key.
//     Get one at: https://www.themoviedb.org/settings/api  (free account)
//

import Foundation

enum APIConfig {

    // MARK: - 🔑 Your API Key
    static let apiKey = "YOUR_TMDB_API_KEY_HERE"

    // MARK: - Base URLs
    static let baseURL       = "https://api.themoviedb.org/3"
    static let imageBaseURL  = "https://image.tmdb.org/t/p/"

    // MARK: - Image Sizes
    enum ImageSize {
        static let poster   = "w500"
        static let backdrop = "w1280"
        static let profile  = "w185"
        static let original = "original"
    }

    // MARK: - URL Builders
    static func posterURL(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "\(imageBaseURL)\(ImageSize.poster)\(path)")
    }

    static func backdropURL(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "\(imageBaseURL)\(ImageSize.backdrop)\(path)")
    }

    static func profileURL(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "\(imageBaseURL)\(ImageSize.profile)\(path)")
    }
}
