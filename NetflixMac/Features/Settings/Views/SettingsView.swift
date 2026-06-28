// MARK: - SettingsView.swift
// Preferences panel for controlling Netflix macOS app settings.

import SwiftUI

struct SettingsView: View {
    @AppStorage("autoSkipIntro") private var autoSkipIntro = true
    @AppStorage("autoPlayNext") private var autoPlayNext = true
    @AppStorage("pureOledBlack") private var pureOledBlack = false
    @AppStorage("streamingQuality") private var streamingQuality = "Auto"

    @State private var activeTab: SettingsTab = .general

    enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case quality = "Quality"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .general: return "gearshape.fill"
            case .quality: return "video.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar Navigation
            VStack(spacing: 6) {
                // Top margin to push items below window controls
                Spacer().frame(height: 32)

                // Navigation Items
                ForEach(SettingsTab.allCases) { tab in
                    Button(action: { activeTab = tab }) {
                        HStack(spacing: 10) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13))
                                .foregroundStyle(activeTab == tab ? .white : .gray)
                                .frame(width: 16)
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: activeTab == tab ? .bold : .regular))
                                .foregroundStyle(activeTab == tab ? .white : .gray)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(activeTab == tab ? Color.netflixRed : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .hoverLift(scale: 1.02)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12) // Margin to prevent touching the window borders
            .frame(width: 160)
            .background(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1),
                alignment: .trailing
            )

            // Details Panel
            VStack(alignment: .leading, spacing: 0) {
                switch activeTab {
                case .general:
                    generalPane
                case .quality:
                    qualityPane
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.netflixBlack.opacity(0.65).background(.thinMaterial))
        }
        .frame(width: 580, height: 360)
        .preferredColorScheme(.dark)
        .navigationTitle("Preferences")
    }

    private var generalPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("General Preferences")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                Text("Customize your playback behavior and display options.")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }
            
            VStack(spacing: 10) {
                generalToggleRow(
                    isOn: $autoSkipIntro,
                    title: "Auto Skip Intro & Recaps",
                    description: "Automatically clicks credits, intros, and recaps when they appear.",
                    icon: "forward.frame.fill"
                )
                
                Divider().background(Color.white.opacity(0.06))

                generalToggleRow(
                    isOn: $autoPlayNext,
                    title: "Auto Play Next Episode",
                    description: "Instantly begins the countdown and loads the next episode.",
                    icon: "forward.end.fill"
                )

                Divider().background(Color.white.opacity(0.06))

                generalToggleRow(
                    isOn: $pureOledBlack,
                    title: "Pure OLED Black Mode",
                    description: "Forces a clean Pitch Black (#000000) backdrop to save battery.",
                    icon: "moon.stars.fill",
                    iconColor: Color.yellow.opacity(0.85)
                )
            }
            .padding(14)
            .background(Color.white.opacity(0.02))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )

            Spacer()
        }
        .padding(20)
    }

    private var qualityPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Streaming Quality")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                Text("Cap your stream resolution to monitor data usage.")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }
            
            // Grid of 4 Interactive Cards
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(QualityLevel.allCases) { level in
                    Button(action: { streamingQuality = level.rawValue }) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: level.icon)
                                    .font(.system(size: 15))
                                    .foregroundStyle(streamingQuality == level.rawValue ? Color.netflixRed : .white)
                                Spacer()
                                if streamingQuality == level.rawValue {
                                    Circle()
                                        .fill(Color.netflixRed)
                                        .frame(width: 6, height: 6)
                                        .glow(color: Color.netflixRed, radius: 4)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(level.label)
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundStyle(.white)
                                Text(level.resolution)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.white.opacity(0.6))
                            }
                            
                            Spacer().frame(height: 2)
                            
                            Text(level.dataUsage)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(streamingQuality == level.rawValue ? Color.netflixRed : Color.white.opacity(0.4))
                        }
                        .padding(10)
                        .frame(height: 94)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(streamingQuality == level.rawValue ? Color.white.opacity(0.04) : Color.white.opacity(0.01))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(streamingQuality == level.rawValue ? Color.netflixRed.opacity(0.8) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .hoverLift(scale: 1.02)
                }
            }
            
            Text("ℹ️ Note: Changing quality will automatically reload the web page.")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.35))
                .padding(.top, 2)
            
            Spacer()
        }
        .padding(20)
    }

    private func generalToggleRow(isOn: Binding<Bool>, title: String, description: String, icon: String, iconColor: Color = .netflixRed, hasStroke: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 22, height: 22)
                .background(Color.white.opacity(0.03))
                .cornerRadius(6)
                .overlay(
                    Group {
                        if hasStroke {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        }
                    }
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .tint(Color.netflixRed)
        }
    }
}
