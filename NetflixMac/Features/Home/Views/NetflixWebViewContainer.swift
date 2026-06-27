// MARK: - NetflixWebViewContainer.swift
// Main wrapper container providing a Liquid Glass toolbar and embedded Netflix web player.

import SwiftUI

struct NetflixWebViewContainer: View {
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false

    // Coordinate actions between toolbar and WKWebView
    @State private var commandCoordinator = NetflixWebView.CommandCoordinator()

    var body: some View {
        ZStack(alignment: .top) {
            Color.netflixBlack.ignoresSafeArea()

            // Embedded Web View
            NetflixWebView(
                url: URL(string: "https://www.netflix.com")!,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                isLoading: $isLoading,
                commandCoordinator: commandCoordinator
            )
            .padding(.top, 48) // Clear space for the custom toolbar
            .ignoresSafeArea()

            // MARK: Custom Liquid Glass Toolbar
            HStack(spacing: 16) {
                // Navigation buttons
                HStack(spacing: 8) {
                    ToolbarButton(icon: "chevron.left", isEnabled: canGoBack) {
                        commandCoordinator.goBackAction?()
                    }

                    ToolbarButton(icon: "chevron.right", isEnabled: canGoForward) {
                        commandCoordinator.goForwardAction?()
                    }
                }

                ToolbarButton(icon: "arrow.clockwise", isEnabled: true) {
                    commandCoordinator.reloadAction?()
                }

                ToolbarButton(icon: "house.fill", isEnabled: true) {
                    commandCoordinator.loadHomeAction?()
                }

                Spacer()

                // Netflix Logo
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.netflixRed)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("N").font(.system(size: 15, weight: .black)).foregroundStyle(.white).italic()
                        )
                    Text("Netflix")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                }

                Spacer()

                // Loading Indicator
                if isLoading {
                    ProgressView()
                        .tint(Color.netflixRed)
                        .scaleEffect(0.8)
                        .frame(width: 32, height: 32)
                } else {
                    Spacer().frame(width: 32)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(.ultraThinMaterial)
            .overlay(
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1)
                }
            )
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Toolbar Button
struct ToolbarButton: View {
    let icon: String
    let isEnabled: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isEnabled ? (isHovered ? .white : .white.opacity(0.8)) : .white.opacity(0.25))
                .frame(width: 32, height: 32)
                .background {
                    if isEnabled && isHovered {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    }
                }
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
        .onHover { h in
            if isEnabled { isHovered = h }
        }
    }
}
