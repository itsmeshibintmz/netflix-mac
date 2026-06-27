# Netflix for macOS 🎬

A beautiful, fully native macOS Netflix client built with **SwiftUI + Combine**, featuring **Apple's Liquid Glass design language**, MVVM architecture, and TMDB API integration.

> **Personal use only.** Not affiliated with or endorsed by Netflix, Inc.

---

## ✨ Features

| Feature | Details |
|---|---|
| 🪟 Liquid Glass UI | `.ultraThinMaterial` sidebar, floating glass cards, specular highlights |
| 🎬 Hero Banner | Full-bleed auto-cycling backdrop with gradient overlays |
| 🔍 Search | Live results with 320ms debounce, genre filters, recent history |
| 📋 My List | Persistent watchlist with adaptive grid |
| 🎭 Detail View | Cast carousel, trailer button, backdrop hero, recommendations |
| 📺 AVKit Player | Custom controls, PiP, keyboard shortcuts, resume position |
| 👤 Profiles | Up to 5 profiles with avatars, colors, Kids mode |
| ⚙️ Settings | Playback, subtitles, audio, notifications, about |
| 🔔 Status Bar | Mini player in macOS menu bar |
| ⌨️ Shortcuts | Space, ←/→/↑/↓, ⌘F, ⌘⇧P |
| 🌙 Dark Mode | Full dark-mode design throughout |
| 🖥️ Universal | Runs on Apple Silicon (M1/M2/M3/M4) and Intel Macs |

---

## 🚀 Setup

### Prerequisites
- **macOS 13 (Ventura)** or later
- **Xcode 15** or later
- A **free TMDB API key** (see below)

### Step 1 — Get a TMDB API Key (free)
1. Sign up at [themoviedb.org](https://www.themoviedb.org/signup)
2. Go to **Settings → API** and request a Developer API key
3. Copy your **API Key (v3 auth)**

### Step 2 — Add Your Key to the App
Open [`NetflixMac/Core/Config/APIConfig.swift`](NetflixMac/Core/Config/APIConfig.swift) and replace:

```swift
static let apiKey = "YOUR_TMDB_API_KEY_HERE"
```

with your actual key:

```swift
static let apiKey = "abc123yourkeyhere"
```

### Step 3 — Open in Xcode
```bash
open NetflixMac.xcodeproj
```

### Step 4 — Build & Run
- Select the **NetflixMac** scheme
- Choose **My Mac** as the destination
- Press **⌘R** to build and run

> **Note:** If Xcode shows signing errors, go to **Signing & Capabilities** and set your Team to your personal Apple ID.

---

## 📁 Project Structure

```
NetflixMac/
├── App/
│   ├── NetflixMacApp.swift        ← @main entry + keyboard commands
│   ├── AppDelegate.swift          ← Status bar, appearance, Touch Bar
│   └── MainAppView.swift          ← NavigationSplitView + Sidebar
├── Core/
│   ├── Config/APIConfig.swift     ← 🔑 PUT YOUR API KEY HERE
│   ├── Network/
│   │   ├── NetworkService.swift   ← async/await URLSession + caching
│   │   └── APIEndpoints.swift     ← All TMDB endpoint definitions
│   ├── Models/                    ← MediaItem, Cast, Genre, VideoResult
│   └── Extensions/                ← Color+Netflix, View+LiquidGlass
├── Features/
│   ├── Auth/                      ← Onboarding, Profile selection, AuthVM
│   ├── Home/                      ← Hero banner, content rows, HomeVM
│   ├── Search/                    ← Live search, SearchVM
│   ├── Detail/                    ← DetailView, CastScroll, DetailVM
│   ├── Player/                    ← AVKit player, MiniPlayer
│   ├── MyList/                    ← Watchlist grid
│   ├── Downloads/                 ← Downloads manager UI
│   └── Settings/                  ← All settings + about
├── Shared/
│   ├── Components/                ← LiquidGlassCard, AsyncPosterImage, etc.
│   └── Managers/                  ← WatchlistManager, PlaybackManager
└── Resources/
    ├── Assets.xcassets            ← App icon, images
    ├── Info.plist                 ← Bundle config, entitlements
    └── NetflixMac.entitlements    ← Sandbox + network permissions
```

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Space` | Play / Pause |
| `⌘→` | Seek forward 10s |
| `⌘←` | Seek back 10s |
| `⌘↑` | Volume up |
| `⌘↓` | Volume down |
| `⌘F` | Toggle fullscreen |
| `⌘⇧P` | Picture in Picture |
| `⌘,` | Open Settings |

---

## 🎨 Liquid Glass Design

The app uses Apple's **Liquid Glass** design language throughout:

- **`.ultraThinMaterial`** on the sidebar, toolbar, and overlays
- **Specular highlights** — a white gradient strip at the top of glass surfaces
- **Soft border strokes** — `strokeBorder` with gradient from `white.opacity(0.35)` → `white.opacity(0.08)`
- **Depth shadows** — `radius: 20–30` with `y: 8–15` offset
- **Hover lift** — Spring-animated `scaleEffect` + enhanced shadow on hover
- **Glow effects** — Double `shadow` trick for ambient glow on rating badges

---

## 🔌 API

Content is powered by **The Movie Database (TMDB)**. All endpoints used:

- `/trending/all/day` — Trending content
- `/movie/popular`, `/tv/popular` — Popular movies/shows
- `/movie/top_rated` — Top rated movies
- `/movie/now_playing`, `/movie/upcoming` — Cinema listings
- `/tv/airing_today` — Live TV
- `/search/multi` — Universal search
- `/movie/{id}`, `/tv/{id}` — Rich detail
- `/movie/{id}/credits`, `/tv/{id}/aggregate_credits` — Cast
- `/movie/{id}/videos`, `/tv/{id}/videos` — Trailers
- `/movie/{id}/recommendations` — Similar content
- `/genre/movie/list` — Genre list

---

## 📝 Notes

- **Video streaming**: Real Netflix DRM content is not accessible. The player opens YouTube trailers via TMDB's video endpoint. For full streaming, you would need to integrate Netflix's proprietary Widevine DRM SDK (not publicly available).
- **Downloads**: UI is implemented. Full download logic requires `AVAssetDownloadURLSession` and actual streamable HLS content.
- **Handoff**: Configured in Info.plist — implement `NSUserActivity` on detail pages to enable cross-device handoff.

---

## 🏗️ Built With

- **SwiftUI** — Declarative UI
- **Combine** — Reactive data binding
- **AVKit / AVFoundation** — Video playback, PiP
- **URLSession** — Networking with disk cache
- **UserDefaults** — Watchlist + position persistence
- **TMDB API** — Content data

---

*Made with ❤️ for personal use. All content metadata © TMDB contributors.*
