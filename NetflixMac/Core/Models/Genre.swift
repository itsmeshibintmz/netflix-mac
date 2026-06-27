// MARK: - Genre.swift

import Foundation

struct Genre: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
}

struct GenreResponse: Codable {
    let genres: [Genre]
}
