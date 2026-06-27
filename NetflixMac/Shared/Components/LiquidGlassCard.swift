// MARK: - LiquidGlassCard.swift
// Standalone reusable Liquid Glass card container.

import SwiftUI

struct LiquidGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 18
    var padding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    var material: Material = .ultraThinMaterial
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .liquidGlass(cornerRadius: cornerRadius, material: material)
    }
}

// MARK: - Rating Badge
struct RatingBadge: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 9, weight: .bold))
            Text(String(format: "%.1f", rating))
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(Color.ratingColor(for: rating))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().strokeBorder(Color.ratingColor(for: rating).opacity(0.4), lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Maturity Badge
struct MaturityBadge: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.netflixMidGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Genre Pill
struct GenrePill: View {
    let text: String
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? .black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(isSelected ? Color.white : Color.netflixMidGray.opacity(0.7))
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        LiquidGlassCard { Text("Glass Card").foregroundStyle(.white) }
        RatingBadge(rating: 8.3)
        MaturityBadge(label: "TV-14")
        GenrePill(text: "Action", isSelected: true) {}
    }
    .padding()
    .background(Color.netflixBlack)
}
