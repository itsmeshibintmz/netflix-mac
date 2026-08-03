// MARK: - UpdateSheetView.swift
// A Kaset-style modal view presenting application updates or changelogs to the user.

import SwiftUI
import AppKit

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
            // MARK: - Header View (Kaset style)
            headerView

            // MARK: - Content Card (Kaset style)
            contentCard

            // MARK: - Footer View (Kaset style)
            footerView
        }
        .padding(24)
        .frame(width: 580)
        .frame(height: 540)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .preferredColorScheme(.dark)
    }

    // MARK: - Header Component
    private var headerView: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.netflixRed.opacity(0.15))
                    .frame(width: 84, height: 84)

                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 54, height: 54)
            }

            Text("Version \(version)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Content Card Component
    private var contentCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 13, weight: .semibold))

                Text("Release Notes")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()
            }
            .foregroundStyle(Color.white.opacity(0.7))
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .background(Color.white.opacity(0.1))

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(changelogLines) { line in
                        switch line.type {
                        case .title:
                            Text(line.text)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.top, 4)
                        case .header:
                            Text(line.text)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.netflixRed)
                                .padding(.top, 4)
                        case .bullet:
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.netflixRed)
                                Text(LocalizedStringKey(line.text))
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(Color.white.opacity(0.85))
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(3)
                            }
                            .padding(.leading, 4)
                        case .paragraph:
                            Text(LocalizedStringKey(line.text))
                                .font(.system(size: 12.5))
                                .foregroundStyle(Color.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                                .lineSpacing(4)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Footer Component
    private var footerView: some View {
        HStack {
            Button(action: { UpdateManager.shared.showVersionHistory = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12, weight: .bold))
                    Text("Version History")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Color.netflixRed)
            }
            .buttonStyle(.plain)

            Spacer()

            if isDownloading {
                VStack(spacing: 6) {
                    ProgressView(value: downloadProgress, total: 1.0)
                        .tint(Color.netflixRed)
                        .progressViewStyle(.linear)
                        .frame(width: 140)
                    Text("Downloading... \(Int(downloadProgress * 100))%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            } else {
                HStack(spacing: 12) {
                    if let cancelAction = cancelAction {
                        Button(action: cancelAction) {
                            Text("Later")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.8))
                                .padding(.horizontal, 18)
                                .frame(height: 38)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .hoverLift(scale: 1.03)
                    }

                    Button(action: primaryAction) {
                        Text(primaryButtonText)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .frame(height: 38)
                            .background(Color.netflixRed)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .hoverLift(scale: 1.03)
                    .glow(color: Color.netflixRed, radius: 8)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}
