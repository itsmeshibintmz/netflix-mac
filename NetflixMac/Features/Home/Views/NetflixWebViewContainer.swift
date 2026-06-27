// MARK: - NetflixWebViewContainer.swift
// Main wrapper container providing a full-bleed web player frame.

import SwiftUI

struct NetflixWebViewContainer: View {
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var commandCoordinator = NetflixWebView.CommandCoordinator()

    var body: some View {
        ZStack {
            Color.netflixBlack.ignoresSafeArea()

            // Full-bleed web view
            NetflixWebView(
                url: URL(string: "https://www.netflix.com")!,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                isLoading: $isLoading,
                commandCoordinator: commandCoordinator
            )
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
    }
}
