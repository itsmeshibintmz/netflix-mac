# Netflix for macOS 🎬

A beautiful, native macOS Netflix desktop app wrapper built using **SwiftUI + WebKit (WKWebView)**, designed to provide a clean, edge-to-edge desktop streaming experience outside of a standard browser.

---

## ✨ Features

| Feature | Details |
|---|---|
| 🪟 Full-bleed UI | Edge-to-edge video canvas starting directly underneath the macOS title bar |
| 🛡️ DRM & Video Playback | Natively handles FairPlay/Widevine HTML5 video playback without plugins |
| 👤 Persistent Sessions | Automatically retains your Netflix cookies and login state across launches |
| 🫵 Swipe Navigation | Supports Safari-style swipe left/right trackpad gestures to go back/forward |
| 🚥 Window Controls Alignment | Custom CSS shifts Netflix's navigation menu to prevent overlap with the macOS Close/Minimize/Maximize traffic lights |
| 🎨 Liquid Glass App Icon | Custom macOS-style glassmorphism app icon for your Dock |
| 📜 Elegant Scrollbars | Custom ultra-thin scrollbar tracks matching macOS system styles |

---

## 🚀 Setup & Run

### Prerequisites
- **macOS 13 (Ventura)** or later
- **Xcode 15** or later

### Step 1 — Clone and Open in Xcode
Double-click `NetflixMac.xcodeproj` to open it in Xcode, or run:
```bash
open NetflixMac.xcodeproj
```

### Step 2 — Configure Signing
1. Click the blue **`NetflixMac`** project at the top of the left sidebar.
2. Select the **`NetflixMac`** target under TARGETS.
3. Click the **`Signing & Capabilities`** tab.
4. Set **Team** to your personal Apple ID team (to generate local signing certificates).
   * *Note:* If you get keychain access errors, you can uncheck "Automatically manage signing" and set the **Signing Certificate** dropdown to **`Sign to Run Locally`** to bypass the keychain.

### Step 3 — Build & Run
* Press **⌘R** (or click the ▶ Play button in Xcode).
* The real Netflix login page will load immediately. Log in to your actual account to start streaming in 4K/HDR!

---

## 📁 Project Structure

The project has been refactored into a highly optimized, lightweight architecture containing just **6 Swift files**:

```
NetflixMac/
├── App/
│   ├── NetflixMacApp.swift        ← @main app entry point
│   └── AppDelegate.swift          ← Force dark-mode appearance & lifecycle
├── Core/
│   └── Extensions/
│       ├── Color+Netflix.swift    ← Custom brand colors
│       └── View+LiquidGlass.swift ← General glassmorphism styling
├── Features/
│   └── Home/
│       └── Views/
│           └── NetflixWebViewContainer.swift  ← Full-bleed web container layout
└── Shared/
    └── Components/
        └── NetflixWebView.swift   ← WKWebView wrapper, CSS injections, User-Agent setup
```

---

## 🛠️ Built With

- **SwiftUI** — Native declarative UI
- **WebKit (WKWebView)** — High-performance HTML5 rendering engine
- **FairPlay DRM** — Native Apple hardware-decryption framework for secure streaming
- **macOS App Sandbox** — Sandboxed environment with outgoing network client access
