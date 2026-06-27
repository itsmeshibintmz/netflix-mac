// MARK: - SettingsView.swift
// Preferences panel for controlling Netflix macOS app settings.

import SwiftUI

struct SettingsView: View {
    @AppStorage("autoSkipIntro") private var autoSkipIntro = true
    @AppStorage("autoPlayNext") private var autoPlayNext = true
    @AppStorage("pureOledBlack") private var pureOledBlack = false

    var body: some View {
        Form {
            // Binge Watching Settings
            Section(header: Text("Binge Watching").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $autoSkipIntro) {
                        HStack(spacing: 8) {
                            Image(systemName: "forward.frame.fill")
                                .foregroundStyle(Color.netflixRed)
                                .font(.system(size: 14))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto Skip Intro & Recaps")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Automatically skips credits, intros, and recaps when the button appears.")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }

                    Divider().padding(.vertical, 4)

                    Toggle(isOn: $autoPlayNext) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.next.to.fill")
                                .foregroundStyle(Color.netflixRed)
                                .font(.system(size: 14))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto Play Next Episode")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Instantly loads the next episode when credit roll begins.")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }

            Spacer().frame(height: 16)

            // Appearance Settings
            Section(header: Text("Appearance").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $pureOledBlack) {
                        HStack(spacing: 8) {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.black)
                                .font(.system(size: 14))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pure OLED Black Mode")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Changes player and library background from dark gray to pure black to save battery on MacBook XDR screens.")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 280)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SettingsView()
}
