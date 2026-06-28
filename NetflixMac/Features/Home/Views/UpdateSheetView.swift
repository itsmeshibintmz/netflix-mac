// MARK: - UpdateSheetView.swift
// A Liquid Glass styled modal view presenting updates or changelogs to the user.

import SwiftUI

struct UpdateSheetView: View {
    let title: String
    let version: String
    let notes: String
    let primaryButtonText: String
    
    // Download tracking
    var isDownloading: Bool = false
    var downloadProgress: Double = 0.0
    
    let primaryAction: () -> Void
    var cancelAction: (() -> Void)? = nil

    private struct ChangelogLine: Identifiable {
        let id = UUID()
        let text: String
        let type: LineType
        
        enum LineType {
            case title
            case header
            case bullet
            case paragraph
        }
    }

    private var changelogLines: [ChangelogLine] {
        let normalized = notes.replacingOccurrences(of: "\r\n", with: "\n")
        let rawLines = normalized.components(separatedBy: .newlines)
        var result = [ChangelogLine]()
        
        for line in rawLines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            if trimmed == "---" || trimmed == "***" { continue }
            
            if trimmed.hasPrefix("# ") {
                let text = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
                // Filter out version/latest title duplicate
                if text.contains(version) || text.lowercased().contains("version") || text.lowercased().contains("latest") {
                    continue
                }
                result.append(ChangelogLine(text: text, type: .title))
            } else if trimmed.hasPrefix("## ") {
                let text = trimmed.dropFirst(3).trimmingCharacters(in: .whitespaces)
                result.append(ChangelogLine(text: text, type: .header))
            } else if trimmed.hasPrefix("### ") {
                let text = trimmed.dropFirst(4).trimmingCharacters(in: .whitespaces)
                result.append(ChangelogLine(text: text, type: .header))
            } else if trimmed.hasPrefix("- ") {
                let text = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
                result.append(ChangelogLine(text: text, type: .bullet))
            } else if trimmed.hasPrefix("* ") {
                let text = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
                result.append(ChangelogLine(text: text, type: .bullet))
            } else {
                result.append(ChangelogLine(text: trimmed, type: .paragraph))
            }
        }
        
        return result
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header Group
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.netflixRed)
                    Text(title)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)
                }
                
                Text("Version \(version)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .padding(.top, 8)

            // Scrollable Changelog Box
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(changelogLines) { line in
                        switch line.type {
                        case .title:
                            Text(line.text)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.top, 6)
                        case .header:
                            Text(line.text)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.netflixRed)
                                .padding(.top, 4)
                        case .bullet:
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.netflixRed)
                                Text(LocalizedStringKey(line.text))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.white.opacity(0.85))
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(3)
                            }
                            .padding(.leading, 6)
                        case .paragraph:
                            Text(LocalizedStringKey(line.text))
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                                .lineSpacing(4)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 220)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            // Action / Progress Group
            if isDownloading {
                VStack(spacing: 8) {
                    ProgressView(value: downloadProgress, total: 1.0)
                        .tint(Color.netflixRed)
                        .progressViewStyle(.linear)
                        
                    Text("Downloading update... \(Int(downloadProgress * 100))%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            } else {
                HStack(spacing: 12) {
                    if let cancelAction = cancelAction {
                        Button(action: cancelAction) {
                            Text("Later")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .hoverLift(scale: 1.03)
                    }
                    
                    Button(action: primaryAction) {
                        Text(primaryButtonText)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.netflixRed)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .hoverLift(scale: 1.03)
                    .glow(color: Color.netflixRed, radius: 10)
                }
                .padding(.bottom, 4)
            }
        }
        .padding(24)
        .frame(width: 480, height: 400)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .preferredColorScheme(.dark)
    }
}
