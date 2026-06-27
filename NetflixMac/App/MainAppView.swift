// MARK: - MainAppView.swift
// Root navigation: translucent sidebar + detail area.

import SwiftUI

// MARK: - Sidebar Items
enum SidebarItem: String, CaseIterable, Identifiable {
    case home      = "Home"
    case search    = "Search"
    case myList    = "My List"
    case downloads = "Downloads"
    case settings  = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home:      return "house.fill"
        case .search:    return "magnifyingglass"
        case .myList:    return "bookmark.fill"
        case .downloads: return "arrow.down.circle.fill"
        case .settings:  return "gearshape.fill"
        }
    }
}

// MARK: - Main App View
struct MainAppView: View {
    @State private var selectedItem: SidebarItem = .home
    @State private var selectedMedia: MediaItem? = nil
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var watchlist: WatchlistManager
    @EnvironmentObject var playback: PlaybackManager

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(selection: $selectedItem)
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.prominentDetail)
        .sheet(item: $selectedMedia) { item in
            DetailView(item: item, showDetail: .constant(true))
                .environmentObject(watchlist)
                .environmentObject(playback)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .home:
            HomeView(selectedMedia: $selectedMedia, showDetail: .constant(false))
                .environmentObject(watchlist)
                .environmentObject(playback)
        case .search:
            SearchView(selectedMedia: $selectedMedia, showDetail: .constant(false))
                .environmentObject(watchlist)
                .environmentObject(playback)
        case .myList:
            MyListView(selectedMedia: $selectedMedia, showDetail: .constant(false))
                .environmentObject(watchlist)
                .environmentObject(playback)
        case .downloads:
            DownloadsView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @Binding var selection: SidebarItem
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Logo
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.netflixRed)
                        .frame(width: 32, height: 32)
                    Text("N")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)
                        .italic()
                }
                Text("Netflix")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 20)

            // MARK: Profile badge
            if let profile = authVM.selectedProfile {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(profile.avatarColor.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: profile.avatarIcon)
                            .font(.system(size: 18))
                            .foregroundStyle(profile.avatarColor)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(profile.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                        if profile.isKidsProfile {
                            Text("Kids").font(.caption2).foregroundStyle(Color.netflixLightGray)
                        }
                    }
                    Spacer()
                    Button { authVM.deselectProfile() } label: {
                        Image(systemName: "arrow.left.arrow.right.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.netflixLightGray)
                    }
                    .buttonStyle(.plain)
                    .help("Switch profile")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .liquidGlass(cornerRadius: 12)
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }

            // MARK: Nav Items
            VStack(spacing: 2) {
                ForEach(SidebarItem.allCases) { item in
                    SidebarRow(item: item, isSelected: selection == item) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = item
                        }
                    }
                }
            }

            Spacer()

            // MARK: Sign Out
            Divider()
                .background(Color.netflixMidGray.opacity(0.4))
                .padding(.horizontal, 16)

            Button {
                authVM.signOut()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14, weight: .medium))
                    Text("Sign Out")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Color.netflixLightGray)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 240)
        .background(.ultraThinMaterial)
        .background(Color.netflixBlack.opacity(0.7))
    }
}

// MARK: - Sidebar Row
struct SidebarRow: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.netflixRed : isHovered ? .white : Color.netflixLightGray)
                    .frame(width: 22)

                Text(item.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : isHovered ? .white : Color.netflixLightGray)

                Spacer()

                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.netflixRed)
                        .frame(width: 3, height: 20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background {
                if isSelected || isHovered {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Color.netflixRed.opacity(0.15) : Color.white.opacity(0.06))
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.15)) { isHovered = h }
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
