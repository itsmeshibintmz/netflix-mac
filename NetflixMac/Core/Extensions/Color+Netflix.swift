// MARK: - Color+Netflix.swift
// Netflix-inspired color palette & gradients.

import SwiftUI

extension Color {
    // MARK: Brand
    static let netflixRed      = Color(red: 0.898, green: 0.078, blue: 0.078)
    static let netflixDarkRed  = Color(red: 0.70,  green: 0.05,  blue: 0.05)

    // MARK: Surface
    static let netflixBlack    = Color(red: 0.067, green: 0.067, blue: 0.067)
    static let netflixDarkBG   = Color(red: 0.10,  green: 0.10,  blue: 0.10)
    static let netflixDarkGray = Color(red: 0.15,  green: 0.15,  blue: 0.15)
    static let netflixMidGray  = Color(red: 0.25,  green: 0.25,  blue: 0.25)
    static let netflixLightGray = Color(red: 0.55,  green: 0.55,  blue: 0.55)

    // MARK: Liquid Glass
    static let glassWhite      = Color.white.opacity(0.10)
    static let glassHighlight  = Color.white.opacity(0.22)
    static let glassBorder     = Color.white.opacity(0.16)
    static let glassShadow     = Color.black.opacity(0.45)

    // MARK: Ratings
    static let ratingGreen     = Color(red: 0.12, green: 0.85, blue: 0.40)
    static let ratingYellow    = Color(red: 1.00, green: 0.80, blue: 0.00)
    static let ratingRed       = Color.netflixRed

    static func ratingColor(for rating: Double) -> Color {
        rating >= 7.0 ? .ratingGreen : rating >= 5.0 ? .ratingYellow : .ratingRed
    }
}

extension LinearGradient {
    // Hero banner overlay
    static let netflixHero = LinearGradient(
        colors: [.clear, Color.netflixBlack.opacity(0.6), Color.netflixBlack],
        startPoint: .top,
        endPoint: .bottom
    )

    // Card bottom overlay
    static let netflixCard = LinearGradient(
        colors: [.clear, Color.black.opacity(0.85)],
        startPoint: .center,
        endPoint: .bottom
    )

    // Liquid glass surface
    static let liquidGlass = LinearGradient(
        colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Specular highlight (top-only)
    static let specularHighlight = LinearGradient(
        colors: [Color.white.opacity(0.28), .clear],
        startPoint: .top,
        endPoint: UnitPoint(x: 0.5, y: 0.35)
    )

    // Sidebar gradient
    static let sidebarGradient = LinearGradient(
        colors: [Color.netflixBlack, Color.netflixDarkBG],
        startPoint: .top,
        endPoint: .bottom
    )
}
