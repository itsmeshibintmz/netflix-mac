// MARK: - UpdateManager.swift
// Manages application updates using Sparkle 2 framework.

import Foundation
import AppKit
import Combine
import Sparkle

@MainActor
final class UpdateManager: ObservableObject {
    static let shared = UpdateManager()
    
    /// Sparkle standard updater controller
    let updaterController: SPUStandardUpdaterController
    
    @Published var canCheckForUpdates = false
    @Published var isUpdateAvailable = false
    @Published var latestVersion = ""
    @Published var changelog = ""
    @Published var downloadURL: URL? = nil

    @Published var showWhatsNew = false
    @Published var whatsNewChangelog = ""
    @Published var showVersionHistory = false

    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var isUpToDate = false

    private var cancellables = Set<AnyCancellable>()
    private let repoPath = "itsmeshibintmz/netflix-mac"

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var lastSeenVersion: String {
        get { UserDefaults.standard.string(forKey: "lastSeenVersion") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "lastSeenVersion") }
    }

    private init() {
        // Initialize Sparkle standard updater controller
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        // Bind Sparkle's canCheckForUpdates state
        self.updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    /// Primary check run on application launch or manually via menu
    func checkForUpdates(manual: Bool = false) {
        self.isUpToDate = false
        queryGitHubReleaseAPI(manual: manual)
    }

    private func queryGitHubReleaseAPI(manual: Bool) {
        guard let url = URL(string: "https://api.github.com/repos/\(repoPath)/releases/latest") else { return }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("NetflixMacWrapper-Updater", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: GitHubRelease.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] release in
                self?.handleLatestRelease(release, manual: manual)
            })
            .store(in: &cancellables)
    }

    private func handleLatestRelease(_ release: GitHubRelease, manual: Bool) {
        var cleanedTag = release.tagName.lowercased()
        if cleanedTag.hasPrefix("v.") {
            cleanedTag = String(cleanedTag.dropFirst(2))
        } else if cleanedTag.hasPrefix("v") {
            cleanedTag = String(cleanedTag.dropFirst(1))
        }
        cleanedTag = cleanedTag.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        
        let current = currentVersion

        if cleanedTag.compare(current, options: .numeric) == .orderedDescending {
            if let dmgAsset = release.assets.first(where: { $0.name.lowercased().hasSuffix(".dmg") }) {
                self.latestVersion = cleanedTag
                self.changelog = release.body
                self.downloadURL = URL(string: dmgAsset.browserDownloadURL)
                self.isUpdateAvailable = true
            }
        } else {
            if manual {
                self.isUpToDate = true
            } else {
                let lastSeen = lastSeenVersion
                if lastSeen.isEmpty {
                    lastSeenVersion = current
                } else if current.compare(lastSeen, options: .numeric) == .orderedDescending {
                    fetchReleaseNotes(for: current)
                }
            }
        }
    }

    private func fetchReleaseNotes(for version: String) {
        guard let url = URL(string: "https://api.github.com/repos/\(repoPath)/releases") else { return }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("NetflixMacWrapper-Updater", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [GitHubRelease].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] releases in
                if let matchingRelease = releases.first(where: { release in
                    var tag = release.tagName.lowercased()
                    if tag.hasPrefix("v.") {
                        tag = String(tag.dropFirst(2))
                    } else if tag.hasPrefix("v") {
                        tag = String(tag.dropFirst(1))
                    }
                    tag = tag.trimmingCharacters(in: CharacterSet(charactersIn: "."))
                    return tag == version
                }) {
                    self?.whatsNewChangelog = matchingRelease.body
                    self?.showWhatsNew = true
                    self?.lastSeenVersion = version
                }
            })
            .store(in: &cancellables)
    }

    /// Triggers Sparkle's native automatic updater flow
    func downloadAndInstall() {
        isUpdateAvailable = false
        updaterController.checkForUpdates(nil)
    }
}

// MARK: - Decodable GitHub API models
private struct GitHubRelease: Decodable {
    let tagName: String
    let body: String
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case body
        case assets
    }
}

private struct GitHubAsset: Decodable {
    let name: String
    let browserDownloadURL: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}
