// MARK: - PlaybackManager.swift
// Tracks resume positions and current playback state.

import Foundation
import SwiftUI
import Combine

@MainActor
final class PlaybackManager: ObservableObject {

    static let shared = PlaybackManager()

    // MARK: - Published State
    @Published var currentItem: MediaItem? = nil
    @Published var isPlaying: Bool = false
    @Published var volume: Double = 1.0
    @Published var isMuted: Bool = false
    @Published var isPiPActive: Bool = false

    // MARK: - Resume Positions
    private var positions: [Int: Double] = [:]
    private let positionsKey = "netflix_positions_v2"

    private init() { loadPositions() }

    // MARK: - Position API
    func savePosition(for item: MediaItem, position: Double) {
        guard position > 5 else { return }   // Only save if watched > 5 s
        positions[item.id] = position
        persistPositions()
    }

    func resumePosition(for item: MediaItem) -> Double {
        positions[item.id] ?? 0
    }

    func hasResumePoint(for item: MediaItem) -> Bool {
        (positions[item.id] ?? 0) > 10
    }

    func progressFraction(for item: MediaItem, duration: Double) -> Double {
        guard duration > 0 else { return 0 }
        return min((positions[item.id] ?? 0) / duration, 1.0)
    }

    func clearPosition(for item: MediaItem) {
        positions.removeValue(forKey: item.id)
        persistPositions()
    }

    // MARK: - Persistence
    private func persistPositions() {
        if let data = try? JSONEncoder().encode(positions) {
            UserDefaults.standard.set(data, forKey: positionsKey)
        }
    }

    private func loadPositions() {
        guard let data = UserDefaults.standard.data(forKey: positionsKey),
              let saved = try? JSONDecoder().decode([Int: Double].self, from: data)
        else { return }
        positions = saved
    }
}
