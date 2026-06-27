// MARK: - ContentRowView.swift
// Horizontally scrolling row of poster cards with a section title.

import SwiftUI

struct ContentRowView: View {
    let title: String
    let items: [MediaItem]
    var cardWidth: CGFloat = 160
    var cardHeight: CGFloat = 240
    let onSelect: (MediaItem) -> Void

    @State private var isHeaderHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // MARK: Section Header
            HStack(alignment: .center, spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                if isHeaderHovered {
                    HStack(spacing: 4) {
                        Text("Explore All")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.netflixRed)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.netflixRed)
                    }
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .onHover { h in
                withAnimation(.easeInOut(duration: 0.2)) { isHeaderHovered = h }
            }

            // MARK: Horizontal Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(items) { item in
                        PosterCardView(
                            item: item,
                            width: cardWidth,
                            height: cardHeight,
                            onTap: { onSelect(item) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)   // room for hover shadow
            }
        }
    }
}

// MARK: - Wide Card Row (for Top 10)
struct TopTenRowView: View {
    let items: [MediaItem]
    let onSelect: (MediaItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top 10 Today")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(Array(items.prefix(10).enumerated()), id: \.element.id) { idx, item in
                        TopTenCard(item: item, rank: idx + 1, onTap: { onSelect(item) })
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Top 10 Card
struct TopTenCard: View {
    let item: MediaItem
    let rank: Int
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                AsyncPosterImage(url: item.posterURL)
                    .frame(width: 140, height: 200)

                // Rank number
                Text("\(rank)")
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .shadow(color: .white.opacity(0.15), radius: 2, x: 1, y: 1)
                    .offset(x: -20, y: 25)
                    .frame(height: 90, alignment: .bottomLeading)
            }
            .frame(width: 180, height: 200)
            .smoothCorners(8)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .shadow(color: .black.opacity(isHovered ? 0.5 : 0.2),
                    radius: isHovered ? 18 : 6, y: isHovered ? 8 : 2)
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) { isHovered = h }
        }
    }
}
