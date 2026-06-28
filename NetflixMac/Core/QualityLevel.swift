// MARK: - QualityLevel.swift
// Defines the streaming quality levels, custom resolutions, data usage estimates,
// and the corresponding User-Agents to cap video bitrates inside the webview wrapper.

import Foundation

enum QualityLevel: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }

    var label: String { rawValue }

    var resolution: String {
        switch self {
        case .auto: return "Auto"
        case .low: return "480p SD"
        case .medium: return "720p HD"
        case .high: return "1080p/4K UHD"
        }
    }

    var dataUsage: String {
        switch self {
        case .auto: return "Varies with speed"
        case .low: return "Up to 0.3 GB / hr"
        case .medium: return "Up to 0.7 GB / hr"
        case .high: return "Up to 3.0 - 7.0 GB / hr"
        }
    }

    var icon: String {
        switch self {
        case .auto: return "speedometer"
        case .low: return "leaf.fill"
        case .medium: return "play.circle.fill"
        case .high: return "sparkles"
        }
    }

    var userAgent: String {
        switch self {
        case .auto, .high:
            // Standard macOS Safari - Unlocks native hardware FairPlay DRM (1080p and 4K)
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        case .medium:
            // macOS Chrome - Restricts playback to standard software Widevine DRM (caps at 720p)
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
        case .low:
            // iPad Safari - Forces Netflix to deliver mobile HLS streams (caps at 480p / mobile low-bitrate)
            return "Mozilla/5.0 (iPad; CPU OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/605.1.15"
        }
    }
}
