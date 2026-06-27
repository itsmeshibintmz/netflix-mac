// MARK: - MyListView.swift
// Grid display of saved watchlist items.

import SwiftUI

struct MyListView: View {
    @Binding var selectedMedia: MediaItem?
    @Binding var showDetail: Bool
    @EnvironmentObject var watchlist: WatchlistManager

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)]

    var body: some View {
        ZStack {
            Color.netflixBlack.ignoresSafeArea()

            if watchlist.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("My List")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundStyle(.white)
                                Text("\(watchlist.items.count) title\(watchlist.items.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.netflixLightGray)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        // Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(watchlist.items) { item in
                                PosterCardView(
                                    item: item,
                                    width: 160,
                                    height: 240,
                                    onTap: { selectedMedia = item }
                                )
                                .contextMenu {
                                    Button(role: .destructive) {
                                        watchlist.remove(item)
                                    } label: {
                                        Label("Remove from My List", systemImage: "minus.circle")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.netflixMidGray)

            Text("Your list is empty")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Browse content and tap + to save titles here.")
                .font(.callout)
                .foregroundStyle(Color.netflixLightGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
