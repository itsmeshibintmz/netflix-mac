// MARK: - VersionHistoryView.swift
// A Liquid Glass styled modal view displaying the full release history of Netflix for macOS.

import SwiftUI
import AppKit

struct ReleaseItem: Identifiable, Decodable {
    var id: String { tagName }
    let tagName: String
    let name: String?
    let body: String
    let publishedAt: String?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case publishedAt = "published_at"
    }

    var displayVersion: String {
        var tag = tagName
        if tag.hasPrefix("v.") {
            tag = String(tag.dropFirst(2))
        } else if tag.hasPrefix("v") {
            tag = String(tag.dropFirst(1))
        }
        return "v\(tag)"
    }

    var formattedDate: String {
        guard let publishedAt = publishedAt else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: publishedAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return ""
    }
}

struct VersionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var releases: [ReleaseItem] = []
    @State private var selectedReleaseID: String? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    private struct LineItem: Identifiable {
        let id = UUID()
        let text: String
        let type: LineType
        
        enum LineType {
            case title
            case header
            case bullet
            case paragraph
        }
    }

    private func parseLines(from notes: String) -> [LineItem] {
        let normalized = notes.replacingOccurrences(of: "\r\n", with: "\n")
        let rawLines = normalized.components(separatedBy: .newlines)
        var result = [LineItem]()
        
        for line in rawLines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed == "---" || trimmed == "***" { continue }
            
            if trimmed.hasPrefix("# ") {
                let text = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
                result.append(LineItem(text: text, type: .title))
            } else if trimmed.hasPrefix("## ") {
                let text = trimmed.dropFirst(3).trimmingCharacters(in: .whitespaces)
                result.append(LineItem(text: text, type: .header))
            } else if trimmed.hasPrefix("### ") {
                let text = trimmed.dropFirst(4).trimmingCharacters(in: .whitespaces)
                result.append(LineItem(text: text, type: .header))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                let text = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
                result.append(LineItem(text: text, type: .bullet))
            } else {
                result.append(LineItem(text: trimmed, type: .paragraph))
            }
        }
        return result
    }

    private var selectedRelease: ReleaseItem? {
        releases.first(where: { $0.id == selectedReleaseID }) ?? releases.first
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header Bar
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.netflixRed)

                    Text("Version History")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .hoverLift(scale: 1.1)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()
                .background(Color.white.opacity(0.1))

            // MARK: - Content Body
            if isLoading {
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView()
                        .tint(Color.netflixRed)
                    Text("Loading Release History...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.netflixRed)
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.8))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 0) {
                    // MARK: - Left Release Sidebar
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(releases) { release in
                                let isSelected = (selectedRelease?.id == release.id)
                                Button(action: { selectedReleaseID = release.id }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(release.displayVersion)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(isSelected ? .white : Color.white.opacity(0.8))

                                            if !release.formattedDate.isEmpty {
                                                Text(release.formattedDate)
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.white.opacity(0.5))
                                            }
                                        }

                                        Spacer()

                                        if isSelected {
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(Color.netflixRed)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(isSelected ? Color.netflixRed.opacity(0.2) : Color.white.opacity(0.04))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(isSelected ? Color.netflixRed.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                    .frame(width: 200)

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // MARK: - Right Detail Pane
                    if let selected = selectedRelease {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text(selected.name ?? selected.displayVersion)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white)

                                    Spacer()

                                    Text(selected.displayVersion)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color.white.opacity(0.7))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(Color.netflixRed.opacity(0.2)))
                                }

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                ForEach(parseLines(from: selected.body)) { line in
                                    switch line.type {
                                    case .title:
                                        Text(line.text)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.top, 4)
                                    case .header:
                                        Text(line.text)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(Color.netflixRed)
                                            .padding(.top, 4)
                                    case .bullet:
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("•")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(Color.netflixRed)
                                            Text(LocalizedStringKey(line.text))
                                                .font(.system(size: 12.5))
                                                .foregroundStyle(Color.white.opacity(0.85))
                                                .multilineTextAlignment(.leading)
                                                .lineSpacing(3)
                                        }
                                        .padding(.leading, 4)
                                    case .paragraph:
                                        Text(LocalizedStringKey(line.text))
                                            .font(.system(size: 12.5))
                                            .foregroundStyle(Color.white.opacity(0.8))
                                            .multilineTextAlignment(.leading)
                                            .lineSpacing(4)
                                    }
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .frame(width: 680, height: 480)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .preferredColorScheme(.dark)
        .onAppear {
            fetchReleases()
        }
    }

    private func fetchReleases() {
        guard let url = URL(string: "https://api.github.com/repos/itsmeshibintmz/netflix-mac/releases") else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("NetflixMacWrapper-Updater", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data, let decoded = try? JSONDecoder().decode([ReleaseItem].self, from: data) {
                    self.releases = decoded
                    if self.selectedReleaseID == nil {
                        self.selectedReleaseID = decoded.first?.id
                    }
                } else {
                    self.errorMessage = "Failed to load release history."
                }
            }
        }.resume()
    }
}
