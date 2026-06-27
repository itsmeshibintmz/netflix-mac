// MARK: - SearchView.swift
// Full-featured search with live results, genre filters, and recent searches.

import SwiftUI

struct SearchView: View {
    @Binding var selectedMedia: MediaItem?
    @Binding var showDetail: Bool

    @StateObject private var vm = SearchViewModel()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            Color.netflixBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Search Header
                searchHeader

                // MARK: Genre Filters (when not searching)
                if vm.query.isEmpty && !vm.genres.isEmpty {
                    genreFilterBar
                }

                // MARK: Content
                if vm.query.isEmpty {
                    recentAndBrowseView
                } else if vm.isLoading {
                    loadingView
                } else if vm.filteredResults.isEmpty {
                    emptyResultsView
                } else {
                    searchResultsGrid
                }
            }
        }
        .navigationTitle("Search")
    }

    // MARK: - Search Header
    private var searchHeader: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(vm.query.isEmpty ? .netflixLightGray : .white)

                TextField("Search movies, shows, actors…", text: $vm.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .focused($isSearchFocused)

                if !vm.query.isEmpty {
                    Button { vm.query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.netflixLightGray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .liquidGlass(cornerRadius: 12)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Genre Filter Bar
    private var genreFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                GenrePill(text: "All", isSelected: vm.selectedGenre == nil) {
                    vm.selectedGenre = nil
                }
                ForEach(vm.genres.prefix(15)) { genre in
                    GenrePill(text: genre.name, isSelected: vm.selectedGenre?.id == genre.id) {
                        vm.selectedGenre = vm.selectedGenre?.id == genre.id ? nil : genre
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Recent + Browse
    private var recentAndBrowseView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !vm.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Searches")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                            Spacer()
                            Button("Clear") { vm.clearRecent() }
                                .font(.subheadline)
                                .foregroundStyle(Color.netflixRed)
                                .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)

                        ForEach(vm.recentSearches, id: \.self) { term in
                            Button {
                                vm.query = term
                                isSearchFocused = true
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundStyle(.netflixLightGray)
                                    Text(term)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .foregroundStyle(.netflixLightGray)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            .background(Color.netflixDarkGray.opacity(0.5))
                        }
                    }
                }

                Text("Tap a genre to explore")
                    .font(.subheadline)
                    .foregroundStyle(.netflixLightGray)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                Spacer(minLength: 60)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Results Grid
    private var searchResultsGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)],
                spacing: 16
            ) {
                ForEach(vm.filteredResults) { item in
                    PosterCardView(item: item, width: 160, height: 240) {
                        selectedMedia = item
                    }
                }
            }
            .padding(24)
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView().tint(Color.netflixRed).scaleEffect(1.3)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.netflixMidGray)
            Text("No results for \"\(vm.query)\"")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("Try a different spelling or search term.")
                .font(.callout)
                .foregroundStyle(.netflixLightGray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
