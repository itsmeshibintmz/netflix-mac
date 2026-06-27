// MARK: - APIEndpoints.swift
// All TMDB API endpoint definitions.

import Foundation

enum APIEndpoint {
    case trending(mediaType: String = "all", timeWindow: String = "day")
    case popular(mediaType: String)
    case topRated(mediaType: String)
    case nowPlaying
    case upcomingMovies
    case airingToday
    case search(query: String, page: Int = 1)
    case movieDetails(id: Int)
    case tvDetails(id: Int)
    case movieCredits(id: Int)
    case tvCredits(id: Int)
    case movieVideos(id: Int)
    case tvVideos(id: Int)
    case movieRecommendations(id: Int)
    case tvRecommendations(id: Int)
    case genres(mediaType: String)
    case discoverMovies(genreId: Int? = nil, page: Int = 1)
    case discoverTV(genreId: Int? = nil, page: Int = 1)

    // MARK: - URL Construction
    var url: URL? {
        var components = URLComponents(string: "\(APIConfig.baseURL)\(path)")
        var items = [URLQueryItem(name: "api_key", value: APIConfig.apiKey)]
        items.append(contentsOf: queryItems)
        components?.queryItems = items
        return components?.url
    }

    private var path: String {
        switch self {
        case .trending(let m, let t):         return "/trending/\(m)/\(t)"
        case .popular(let m):                 return "/\(m)/popular"
        case .topRated(let m):                return "/\(m)/top_rated"
        case .nowPlaying:                     return "/movie/now_playing"
        case .upcomingMovies:                 return "/movie/upcoming"
        case .airingToday:                    return "/tv/airing_today"
        case .search:                         return "/search/multi"
        case .movieDetails(let id):           return "/movie/\(id)"
        case .tvDetails(let id):              return "/tv/\(id)"
        case .movieCredits(let id):           return "/movie/\(id)/credits"
        case .tvCredits(let id):              return "/tv/\(id)/aggregate_credits"
        case .movieVideos(let id):            return "/movie/\(id)/videos"
        case .tvVideos(let id):               return "/tv/\(id)/videos"
        case .movieRecommendations(let id):   return "/movie/\(id)/recommendations"
        case .tvRecommendations(let id):      return "/tv/\(id)/recommendations"
        case .genres(let m):                  return "/genre/\(m)/list"
        case .discoverMovies:                 return "/discover/movie"
        case .discoverTV:                     return "/discover/tv"
        }
    }

    private var queryItems: [URLQueryItem] {
        switch self {
        case .search(let q, let p):
            return [URLQueryItem(name: "query", value: q),
                    URLQueryItem(name: "page", value: "\(p)")]
        case .discoverMovies(let g, let p):
            var items = [URLQueryItem(name: "page", value: "\(p)"),
                         URLQueryItem(name: "sort_by", value: "popularity.desc")]
            if let g { items.append(URLQueryItem(name: "with_genres", value: "\(g)")) }
            return items
        case .discoverTV(let g, let p):
            var items = [URLQueryItem(name: "page", value: "\(p)"),
                         URLQueryItem(name: "sort_by", value: "popularity.desc")]
            if let g { items.append(URLQueryItem(name: "with_genres", value: "\(g)")) }
            return items
        default:
            return []
        }
    }
}
