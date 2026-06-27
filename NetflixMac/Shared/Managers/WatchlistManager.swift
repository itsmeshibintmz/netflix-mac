// MARK: - WatchlistManager.swift
// Persistent "My List" using UserDefaults + JSON encoding.

import Foundation
import SwiftUI

@MainActor
final class WatchlistManager: ObservableObject {

    static let shared = WatchlistManager()

    @Published private(set) var items: [MediaItem] = []

    private let storageKey = "netflix_watchlist_v2"

    private init() { load() }

    // MARK: - Public API
    var isEmpty: Bool { items.isEmpty }

    func isInWatchlist(_ item: MediaItem) -> Bool {
        items.contains { $0.id == item.id }
    }

    func toggle(_ item: MediaItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if isInWatchlist(item) {
                items.removeAll { $0.id == item.id }
            } else {
                items.insert(item, at: 0)
            }
        }
        save()
    }

    func remove(_ item: MediaItem) {
        withAnimation { items.removeAll { $0.id == item.id } }
        save()
    }

    // MARK: - Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([MediaItem].self, from: data)
        else { return }
        items = saved
    }
}
