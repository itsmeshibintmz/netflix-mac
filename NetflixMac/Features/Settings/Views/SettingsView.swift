// MARK: - SettingsView.swift
// macOS-native settings with Liquid Glass panels.

import SwiftUI

struct SettingsView: View {
    // MARK: - Playback Settings
    @AppStorage("autoplay_next")        var autoplayNext: Bool = true
    @AppStorage("autoplay_previews")    var autoplayPreviews: Bool = true
    @AppStorage("default_quality")      var defaultQuality: String = "Auto"
    @AppStorage("default_subtitles")    var defaultSubtitles: Bool = false
    @AppStorage("subtitle_language")    var subtitleLanguage: String = "English"
    @AppStorage("audio_language")       var audioLanguage: String = "Original"
    @AppStorage("tmdb_api_key")         var apiKeyOverride: String = ""

    private let qualities = ["Auto", "Low", "Medium", "High", "Ultra HD"]
    private let languages = ["English", "Spanish", "French", "German", "Japanese", "Korean", "Hindi"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                Text("Settings")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.top, 32)

                // MARK: API Configuration
                SettingsSection(title: "API Configuration", icon: "key.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TMDB API Key")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.netflixLightGray)

                        TextField("Enter your TMDB API key…", text: $apiKeyOverride)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(10)
                            .liquidGlass(cornerRadius: 8)
                            .onChange(of: apiKeyOverride) { newValue in
                                // Could propagate to APIConfig at runtime
                            }

                        Link("Get a free API key at themoviedb.org →",
                             destination: URL(string: "https://www.themoviedb.org/settings/api")!)
                            .font(.caption)
                            .foregroundStyle(Color.netflixRed)
                    }
                }

                // MARK: Playback
                SettingsSection(title: "Playback", icon: "play.rectangle.fill") {
                    VStack(spacing: 0) {
                        ToggleRow(label: "Autoplay next episode", isOn: $autoplayNext)
                        Divider().background(Color.netflixMidGray)
                        ToggleRow(label: "Autoplay previews on hover", isOn: $autoplayPreviews)
                        Divider().background(Color.netflixMidGray)

                        PickerRow(label: "Default Quality", selection: $defaultQuality, options: qualities)
                    }
                }

                // MARK: Subtitles & Audio
                SettingsSection(title: "Subtitles & Audio", icon: "captions.bubble.fill") {
                    VStack(spacing: 0) {
                        ToggleRow(label: "Show subtitles by default", isOn: $defaultSubtitles)
                        Divider().background(Color.netflixMidGray)
                        PickerRow(label: "Subtitle Language", selection: $subtitleLanguage, options: languages)
                        Divider().background(Color.netflixMidGray)
                        PickerRow(label: "Audio Language", selection: $audioLanguage, options: ["Original"] + languages)
                    }
                }

                // MARK: Notifications
                SettingsSection(title: "Notifications", icon: "bell.fill") {
                    VStack(spacing: 0) {
                        ToggleRow(label: "New episode alerts", isOn: .constant(true))
                        Divider().background(Color.netflixMidGray)
                        ToggleRow(label: "New releases from saved list", isOn: .constant(true))
                    }
                }

                // MARK: About
                SettingsSection(title: "About", icon: "info.circle.fill") {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "App", value: "Netflix for macOS")
                        InfoRow(label: "Version", value: "1.0.0")
                        InfoRow(label: "Data Source", value: "TMDB API")
                        InfoRow(label: "Platform", value: "macOS 13+  •  Universal")
                        InfoRow(label: "Design", value: "Liquid Glass (Apple HIG 2026)")
                    }
                }

                Spacer(minLength: 60)
            }
        }
        .background(Color.netflixBlack)
        .preferredColorScheme(.dark)
        .frame(minWidth: 540, minHeight: 600)
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.netflixRed)
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 32)

            content()
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Toggle Row
struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(label, isOn: $isOn)
            .toggleStyle(.switch)
            .tint(Color.netflixRed)
            .font(.system(size: 14))
            .foregroundStyle(.white)
            .padding(.vertical, 12)
    }
}

// MARK: - Picker Row
struct PickerRow: View {
    let label: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { Text($0) }
            }
            .pickerStyle(.menu)
            .frame(width: 160)
            .tint(.white)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color.netflixLightGray)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 6)
    }
}
