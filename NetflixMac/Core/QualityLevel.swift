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
        case .auto: return "Netflix-selected"
        case .low: return "Mobile profile"
        case .medium: return "Chrome profile"
        case .high: return "Safari profile"
        }
    }

    var dataUsage: String {
        switch self {
        case .auto: return "Netflix-managed"
        case .low, .medium, .high: return "Not guaranteed"
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
            // User-agent profiles are hints; Netflix controls the delivered resolution.
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
        case .medium:
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
        case .low:
            return "Mozilla/5.0 (iPad; CPU OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/605.1.15"
        }
    }
}
