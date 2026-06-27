// MARK: - ShimmerView.swift
// Animated loading skeleton using gradient animation.

import SwiftUI

struct ShimmerView: View {
    @State private var phase: CGFloat = -1.0

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [
                    Color.netflixDarkGray,
                    Color.netflixMidGray.opacity(0.8),
                    Color.netflixDarkGray
                ],
                startPoint: UnitPoint(x: phase, y: 0.5),
                endPoint:   UnitPoint(x: phase + 1, y: 0.5)
            )
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.4)
                .repeatForever(autoreverses: false)
            ) {
                phase = 1.5
            }
        }
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(ShimmerView())
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

#Preview {
    ShimmerView()
        .frame(width: 200, height: 300)
        .smoothCorners(10)
}
