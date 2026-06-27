// MARK: - View+LiquidGlass.swift
// Apple Liquid Glass design language modifiers.

import SwiftUI

// MARK: - Liquid Glass Modifier
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var material: Material
    var shadowRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(material)
                    .overlay {
                        // Gradient tint
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(LinearGradient.liquidGlass)
                    }
                    .overlay {
                        // Specular highlight — top strip only
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(LinearGradient.specularHighlight)
                    }
                    .overlay {
                        // Thin border
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    }
                    .shadow(color: Color.glassShadow, radius: shadowRadius, y: 8)
            }
    }
}

// MARK: - Hover Lift Modifier
struct HoverLiftModifier: ViewModifier {
    @State private var isHovered = false
    var scale: CGFloat
    var shadowRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .shadow(
                color: .black.opacity(isHovered ? 0.55 : 0.25),
                radius: isHovered ? shadowRadius : 8,
                y: isHovered ? 12 : 4
            )
            .onHover { hovering in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Glow Modifier
struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

// MARK: - View Extensions
extension View {
    func liquidGlass(
        cornerRadius: CGFloat = 16,
        material: Material = .ultraThinMaterial,
        shadowRadius: CGFloat = 20
    ) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            material: material,
            shadowRadius: shadowRadius
        ))
    }

    func hoverLift(scale: CGFloat = 1.05, shadowRadius: CGFloat = 24) -> some View {
        modifier(HoverLiftModifier(scale: scale, shadowRadius: shadowRadius))
    }

    func glow(color: Color = .netflixRed, radius: CGFloat = 16) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }

    func netflixShadow(radius: CGFloat = 20) -> some View {
        shadow(color: .black.opacity(0.5), radius: radius, x: 0, y: 10)
    }

    /// Clips with continuous corner radius
    func smoothCorners(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
