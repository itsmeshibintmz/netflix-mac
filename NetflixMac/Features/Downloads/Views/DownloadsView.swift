// MARK: - DownloadsView.swift
// Downloads manager UI (demo — uses AVAssetDownloadURLSession concept).

import SwiftUI

// MARK: - Download Item Model
struct DownloadItem: Identifiable {
    let id = UUID()
    let mediaItem: MediaItem
    var progress: Double       // 0.0 – 1.0
    var status: Status

    enum Status: String {
        case downloading = "Downloading"
        case completed   = "Downloaded"
        case paused      = "Paused"
        case failed      = "Failed"

        var icon: String {
            switch self {
            case .downloading: return "arrow.down.circle.fill"
            case .completed:   return "checkmark.circle.fill"
            case .paused:      return "pause.circle.fill"
            case .failed:      return "exclamationmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .downloading: return .netflixRed
            case .completed:   return .ratingGreen
            case .paused:      return .netflixLightGray
            case .failed:      return .ratingRed
            }
        }
    }
}

struct DownloadsView: View {
    // Demo downloads state — in production use AVAssetDownloadURLSession
    @State private var downloads: [DownloadItem] = []

    var body: some View {
        ZStack {
            Color.netflixBlack.ignoresSafeArea()

            if downloads.isEmpty {
                emptyState
            } else {
                downloadsList
            }
        }
        .navigationTitle("Downloads")
    }

    // MARK: - Downloads List
    private var downloadsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Downloads")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                ForEach(downloads) { download in
                    DownloadRowView(download: download) {
                        downloads.removeAll { $0.id == download.id }
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 60))
                .foregroundStyle(Color.netflixMidGray)

            Text("No Downloads")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Downloaded titles will appear here for offline viewing.\nOpen a title's detail page and tap Download.")
                .font(.callout)
                .foregroundStyle(Color.netflixLightGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Text("Powered by AVAssetDownloadURLSession")
                .font(.caption)
                .foregroundStyle(Color.netflixMidGray)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Download Row
struct DownloadRowView: View {
    let download: DownloadItem
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            AsyncPosterImage(url: download.mediaItem.posterURL)
                .frame(width: 60, height: 90)
                .smoothCorners(8)

            VStack(alignment: .leading, spacing: 6) {
                Text(download.mediaItem.displayTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Image(systemName: download.status.icon)
                        .foregroundStyle(download.status.color)
                    Text(download.status.rawValue)
                        .font(.caption)
                        .foregroundStyle(download.status.color)
                }

                if download.status == .downloading {
                    ProgressView(value: download.progress)
                        .tint(Color.netflixRed)
                        .frame(maxWidth: 200)
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(Color.netflixRed)
            }
            .buttonStyle(.plain)
            .help("Delete download")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.netflixDarkGray.opacity(0.3))
    }
}
