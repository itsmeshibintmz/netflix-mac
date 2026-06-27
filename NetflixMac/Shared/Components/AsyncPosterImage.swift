// MARK: - AsyncPosterImage.swift
// Async image loading with disk cache and placeholder shimmer.

import SwiftUI

struct AsyncPosterImage: View {
    let url: URL?
    var cornerRadius: CGFloat = 10
    var contentMode: ContentMode = .fill

    @State private var phase: AsyncImagePhase = .empty

    var body: some View {
        Group {
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                failurePlaceholder
            default:
                ShimmerView()
            }
        }
        .smoothCorners(cornerRadius)
        .task(id: url) {
            await loadImage()
        }
    }

    // MARK: - Failure Placeholder
    private var failurePlaceholder: some View {
        ZStack {
            Color.netflixDarkGray
            VStack(spacing: 8) {
                Image(systemName: "film")
                    .font(.system(size: 28))
                    .foregroundStyle(.netflixLightGray)
                Text("No Image")
                    .font(.caption)
                    .foregroundStyle(.netflixLightGray)
            }
        }
    }

    // MARK: - Load with Cache
    private func loadImage() async {
        guard let url else {
            phase = .failure(URLError(.badURL))
            return
        }

        // Check URLCache first
        let request = URLRequest(url: url)
        if let cached = URLCache.shared.cachedResponse(for: request),
           let nsImage = NSImage(data: cached.data) {
            phase = .success(Image(nsImage: nsImage))
            return
        }

        // Download
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let nsImage = NSImage(data: data) {
                // Cache it
                let cached = CachedURLResponse(response: response, data: data)
                URLCache.shared.storeCachedResponse(cached, for: request)
                phase = .success(Image(nsImage: nsImage))
            } else {
                phase = .failure(URLError(.cannotDecodeContentData))
            }
        } catch {
            phase = .failure(error)
        }
    }
}

// MARK: - Preview helper
#Preview {
    AsyncPosterImage(url: URL(string: "https://image.tmdb.org/t/p/w500/placeholder.jpg"))
        .frame(width: 200, height: 300)
}
