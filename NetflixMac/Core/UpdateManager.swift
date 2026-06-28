// MARK: - UpdateManager.swift
// Manages automatic updates by querying the GitHub Releases API, compares versions,
// and downloads the release installer DMG.

import Foundation
import AppKit
import Combine

final class UpdateManager: ObservableObject {
    static let shared = UpdateManager()
    
    @Published var isUpdateAvailable = false
    @Published var latestVersion = ""
    @Published var changelog = ""
    @Published var downloadURL: URL? = nil

    @Published var showWhatsNew = false
    @Published var whatsNewChangelog = ""

    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var isUpToDate = false // Shows "Up to Date" alert during manual menu check

    private var cancellables = Set<AnyCancellable>()
    private let repoPath = "itsmeshibintmz/netflix-mac"
    private var isManualCheck = false

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var lastSeenVersion: String {
        get { UserDefaults.standard.string(forKey: "lastSeenVersion") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "lastSeenVersion") }
    }

    /// Primary check run on application launch or manually via menu
    func checkForUpdates(manual: Bool = false) {
        isManualCheck = manual
        isUpToDate = false
        
        guard let url = URL(string: "https://api.github.com/repos/\(repoPath)/releases/latest") else { return }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData // Force check live API, ignoring system caches
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("NetflixMacWrapper-Updater", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: GitHubRelease.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] release in
                self?.handleLatestRelease(release)
            })
            .store(in: &cancellables)
    }

    private func handleLatestRelease(_ release: GitHubRelease) {
        // Normalize version tags (remove 'v.', 'v', or surrounding dots)
        var cleanedTag = release.tagName.lowercased()
        if cleanedTag.hasPrefix("v.") {
            cleanedTag = String(cleanedTag.dropFirst(2))
        } else if cleanedTag.hasPrefix("v") {
            cleanedTag = String(cleanedTag.dropFirst(1))
        }
        cleanedTag = cleanedTag.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        
        let current = currentVersion

        // Compare versions numerically (e.g. "1.3.0" > "1.2.0")
        if cleanedTag.compare(current, options: .numeric) == .orderedDescending {
            // Find Netflix.dmg asset
            if let dmgAsset = release.assets.first(where: { $0.name.lowercased().hasSuffix(".dmg") }) {
                self.latestVersion = cleanedTag
                self.changelog = release.body
                self.downloadURL = URL(string: dmgAsset.browserDownloadURL)
                self.isUpdateAvailable = true
            }
        } else {
            // No update available. If this was a manual check, trigger "Up to Date" status.
            if isManualCheck {
                self.isUpToDate = true
            } else {
                // First launch, save current version
                let lastSeen = lastSeenVersion
                if lastSeen.isEmpty {
                    lastSeenVersion = current
                } else if current.compare(lastSeen, options: .numeric) == .orderedDescending {
                    // We just updated! Fetch release notes of the current version to show the "What's New" screen
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
                // Scan the releases list for a matching cleaned tag version
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

    /// Downloads the DMG asset to the Downloads folder and opens/mounts it automatically
    func downloadAndInstall() {
        guard let downloadURL = downloadURL, !isDownloading else { return }

        isDownloading = true
        downloadProgress = 0.0

        let session = URLSession(configuration: .default, delegate: DownloadProgressDelegate(manager: self), delegateQueue: nil)
        let task = session.downloadTask(with: downloadURL)
        task.resume()
    }
}

// MARK: - Download Progress Delegate
private final class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate {
    let manager: UpdateManager

    init(manager: UpdateManager) {
        self.manager = manager
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.manager.downloadProgress = progress
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        let downloadsDir = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let destinationURL = downloadsDir.appendingPathComponent("Netflix.dmg")

        do {
            // Clean up existing file in Downloads if present
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            // Move downloaded file to Downloads
            try fileManager.moveItem(at: location, to: destinationURL)

            DispatchQueue.main.async {
                self.manager.isDownloading = false
                // Mount/open the DMG automatically
                NSWorkspace.shared.open(destinationURL)
            }
        } catch {
            print("Failed to move downloaded update: \(error)")
            DispatchQueue.main.async {
                self.manager.isDownloading = false
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download task completed with error: \(error)")
            DispatchQueue.main.async {
                self.manager.isDownloading = false
            }
        }
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
