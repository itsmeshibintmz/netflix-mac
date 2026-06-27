// MARK: - SearchViewModel.swift
// Debounced live search with recent history and genre filtering.

import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {

    @Published var query: String = ""
    @Published var results: [MediaItem] = []
    @Published var isLoading: Bool = false
    @Published var recentSearches: [String] = []
    @Published var genres: [Genre] = []
    @Published var selectedGenre: Genre? = nil

    private var cancellables = Set<AnyCancellable>()
    private let network = NetworkService.shared
    private let recentKey = "netflix_recent_searches"

    init() {
        loadRecent()
        setupDebounce()
        Task { await loadGenres() }
    }

    // MARK: - Debounced Search
    private func setupDebounce() {
        $query
            .debounce(for: .milliseconds(320), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] q in
                guard let self else { return }
                Task { await self.performSearch(q) }
            }
            .store(in: &cancellables)
    }

    func performSearch(_ q: String) async {
        let trimmed = q.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { results = []; return }
        isLoading = true
        do {
            results = try await network.search(query: trimmed)
            saveRecent(trimmed)
        } catch {
            results = []
        }
        isLoading = false
    }

    // MARK: - Genres
    private func loadGenres() async {
        guard genres.isEmpty else { return }
        do { genres = try await network.fetchGenres(mediaType: "movie") } catch {}
    }

    var filteredResults: [MediaItem] {
        guard let g = selectedGenre else { return results }
        return results.filter { $0.genreIds?.contains(g.id) == true }
    }

    // MARK: - Recent Searches
    private func saveRecent(_ q: String) {
        recentSearches.removeAll { $0.lowercased() == q.lowercased() }
        recentSearches.insert(q, at: 0)
        recentSearches = Array(recentSearches.prefix(8))
        UserDefaults.standard.set(recentSearches, forKey: recentKey)
    }

    func clearRecent() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: recentKey)
    }

    private func loadRecent() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentKey) ?? []
    }
}
