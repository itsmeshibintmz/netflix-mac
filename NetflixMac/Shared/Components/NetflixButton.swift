// MARK: - NetflixButton.swift
// Reusable button styles matching the Netflix design language.

import SwiftUI

// MARK: - Primary (Red) Button
struct NetflixPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    @State private var isHovered = false

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 14, weight: .semibold)) }
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isHovered ? Color.netflixDarkRed : Color.netflixRed)
                    .animation(.easeInOut(duration: 0.15), value: isHovered)
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
    }
}

// MARK: - Secondary (Glass) Button
struct NetflixSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    @State private var isHovered = false

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 14, weight: .medium)) }
                Text(title).font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .liquidGlass(cornerRadius: 8)
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isHovered = h }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
    }
}

// MARK: - Icon Button
struct NetflixIconButton: View {
    let icon: String
    let tooltip: String
    var size: CGFloat = 44
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .liquidGlass(cornerRadius: size / 2)
                .scaleEffect(isHovered ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { h in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { isHovered = h }
        }
    }
}

// MARK: - Watchlist Toggle Button
struct WatchlistButton: View {
    let item: MediaItem
    @EnvironmentObject var watchlist: WatchlistManager

    private var inList: Bool { watchlist.isInWatchlist(item) }

    var body: some View {
        NetflixIconButton(
            icon: inList ? "checkmark" : "plus",
            tooltip: inList ? "Remove from My List" : "Add to My List"
        ) {
            watchlist.toggle(item)
        }
        .glow(color: inList ? .ratingGreen : .clear, radius: inList ? 12 : 0)
    }
}
