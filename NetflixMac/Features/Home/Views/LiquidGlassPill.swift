// MARK: - LiquidGlassPill.swift
// A capsule-shaped controls overlay dock designed to float at the bottom center of the window, styled with Apple Liquid Glass.

import SwiftUI

struct LiquidGlassPill: View {
    let canGoBack: Bool
    let canGoForward: Bool
    let goBackAction: () -> Void
    let goForwardAction: () -> Void
    let reloadAction: () -> Void
    let homeAction: () -> Void

    @Binding var isHoveredSelf: Bool
    @AppStorage("pureOledBlack") private var pureOledBlack = false

    // Hover state specifically for the SettingsLink button
    @State private var isSettingsHovered = false

    var body: some View {
        HStack(spacing: 20) {
            // 1. Back button
            PillButton(icon: "chevron.left", isEnabled: canGoBack, activeColor: Color.netflixRed) {
                goBackAction()
            }

            // 2. Forward button
            PillButton(icon: "chevron.right", isEnabled: canGoForward, activeColor: Color.netflixRed) {
                goForwardAction()
            }

            Divider()
                .frame(height: 18)
                .background(Color.white.opacity(0.12))

            // 3. Reload button
            PillButton(icon: "arrow.clockwise", isEnabled: true, activeColor: Color.netflixRed) {
                reloadAction()
            }

            // 4. Home button
            PillButton(icon: "house.fill", isEnabled: true, activeColor: Color.netflixRed) {
                homeAction()
            }

            Divider()
                .frame(height: 18)
                .background(Color.white.opacity(0.12))

            // 5. OLED Black Quick Toggle
            PillButton(
                icon: pureOledBlack ? "moon.stars.fill" : "moon.stars",
                isEnabled: true,
                activeColor: .purple,
                isSelected: pureOledBlack
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    pureOledBlack.toggle()
                }
            }

            // 6. Settings gear button
            if #available(macOS 14.0, *) {
                // Native SettingsLink for macOS 14+ to prevent Xcode deprecation warnings
                SettingsLink {
                    settingsLabel
                }
                .buttonStyle(.plain)
                .hoverLift(scale: 1.1, shadowRadius: 10)
                .focusable(false)
                .onHover { hovering in
                    isSettingsHovered = hovering
                }
            } else {
                // Fallback AppKit selector for macOS 13
                Button(action: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    
                    // Force the settings window to bring itself key and front
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let settingsWindow = NSApp.windows.first(where: { $0.title == "Settings" || $0.title == "Preferences" }) {
                            settingsWindow.makeKeyAndOrderFront(nil)
                            NSApp.activate(ignoringOtherApps: true)
                        }
                    }
                }) {
                    settingsLabel
                }
                .buttonStyle(.plain)
                .hoverLift(scale: 1.1, shadowRadius: 10)
                .focusable(false)
                .onHover { hovering in
                    isSettingsHovered = hovering
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: 24) // Apply custom specular gradient highlight & 3D borders
        .onHover { hovering in
            isHoveredSelf = hovering
        }
    }

    // Shared visual label for settings button
    private var settingsLabel: some View {
        Image(systemName: "gearshape.fill")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(isSettingsHovered ? Color.blue : .white.opacity(0.75))
            .frame(width: 32, height: 32)
            .background {
                if isSettingsHovered {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .shadow(color: Color.blue.opacity(0.3), radius: 6)
                }
            }
    }
}

// MARK: - Pill Button Component
struct PillButton: View {
    let icon: String
    let isEnabled: Bool
    let activeColor: Color
    var isSelected: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(
                    isSelected ? activeColor :
                    (isEnabled ? (isHovered ? activeColor : .white.opacity(0.75)) : .white.opacity(0.2))
                )
                .frame(width: 32, height: 32)
                .background {
                    if isEnabled && isHovered {
                        Circle()
                            .fill(activeColor.opacity(0.15))
                            .shadow(color: activeColor.opacity(0.3), radius: 6)
                    } else if isSelected {
                        Circle()
                            .fill(activeColor.opacity(0.08))
                    }
                }
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
        .focusable(false)
        .hoverLift(scale: 1.1, shadowRadius: 10) // Custom design-system lift/hover effect
        .onHover { hovering in
            if isEnabled {
                isHovered = hovering
            }
        }
    }
}
