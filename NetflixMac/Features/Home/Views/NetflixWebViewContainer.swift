// MARK: - NetflixWebViewContainer.swift
// Main wrapper container providing a full-bleed web player frame with a floating "Liquid Glass" controls dock.

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

    // Floating pill hover states & auto-hide timer
    @State private var showPill = false
    @State private var isHoveringPill = false
    @State private var hideTimer: Timer? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
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
                .ignoresSafeArea(edges: .top)

            // Floating Liquid Glass Control Pill Dock
            LiquidGlassPill(
                canGoBack: canGoBack,
                canGoForward: canGoForward,
                goBackAction: { commandCoordinator.goBackAction?() },
                goForwardAction: { commandCoordinator.goForwardAction?() },
                reloadAction: { commandCoordinator.reloadAction?() },
                homeAction: { commandCoordinator.loadHomeAction?() },
                isHoveredSelf: $isHoveringPill
            )
            .padding(.bottom, 24)
            .offset(y: (showPill || isHoveringPill) ? 0 : 80)
            .opacity((showPill || isHoveringPill) ? 1.0 : 0.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showPill || isHoveringPill)
        }
        .preferredColorScheme(.dark)
        // Detect mouse movement inside the window using continuous hover tracking
        .onContinuousHover { phase in
            switch phase {
            case .active:
                // Mouse is moving, reveal the control dock
                if !showPill {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showPill = true
                    }
                }
                resetHideTimer()
            case .ended:
                // Mouse left the app window boundary, hide dock
                withAnimation(.easeInOut(duration: 0.25)) {
                    showPill = false
                }
                hideTimer?.invalidate()
            }
        }
    }

    // Reset the auto-hide timer after 2.5 seconds of mouse stillness
    private func resetHideTimer() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
            // Only hide if the user's cursor is not hovering directly over the dock itself
            if !isHoveringPill {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPill = false
                }
            }
        }
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
