// MARK: - NetflixWebViewContainer.swift
// Main wrapper container providing a full-bleed web player frame.

import SwiftUI

struct NetflixWebViewContainer: View {
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var commandCoordinator = NetflixWebView.CommandCoordinator()

    // Binge watching + Appearance settings from UserDefaults
    @AppStorage("autoSkipIntro") private var autoSkipIntro = true
    @AppStorage("autoPlayNext") private var autoPlayNext = true
    @AppStorage("pureOledBlack") private var pureOledBlack = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.netflixBlack.ignoresSafeArea()

            // Full-bleed web view
            NetflixWebView(
                url: URL(string: "https://www.netflix.com")!,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                isLoading: $isLoading,
                commandCoordinator: commandCoordinator,
                autoSkipIntro: autoSkipIntro,
                autoPlayNext: autoPlayNext,
                pureOledBlack: pureOledBlack
            )
            .ignoresSafeArea()

            // Transparent titlebar drag region (allows window dragging while keeping full-bleed look)
            DraggableArea()
                .frame(height: 28)
                .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Draggable Window Helper
struct DraggableArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DragNSView()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class DragNSView: NSView {
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            self.window?.zoom(nil)
        } else {
            self.window?.performDrag(with: event)
        }
    }
}
