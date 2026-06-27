// MARK: - Cast.swift
// Cast & Crew models from TMDB Credits endpoint.

import Foundation

// MARK: - Cast Member
struct CastMember: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    let order: Int?

    var profileURL: URL? { APIConfig.profileURL(profilePath) }

    enum CodingKeys: String, CodingKey {
        case id, name, character, order
        case profilePath = "profile_path"
    }
}

// MARK: - Crew Member
struct CrewMember: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let job: String?
    let department: String?
    let profilePath: String?

    var profileURL: URL? { APIConfig.profileURL(profilePath) }

    enum CodingKeys: String, CodingKey {
        case id, name, job, department
        case profilePath = "profile_path"
    }
}

// MARK: - Credits Response
struct CreditsResponse: Codable {
    let cast: [CastMember]
    let crew: [CrewMember]?
}
