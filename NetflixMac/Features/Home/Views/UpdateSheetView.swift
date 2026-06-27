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
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's Changed:")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.bottom, 2)
                    
                    // SwiftUI Text natively renders markdown tags
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
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
