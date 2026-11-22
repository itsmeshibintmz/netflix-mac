# 🍿 Netflix for macOS

[![GitHub Downloads](https://img.shields.io/github/downloads/itsmeshibintmz/netflix-mac/total?style=flat-square&logo=apple&label=Downloads&color=2d5a27)](https://github.com/itsmeshibintmz/netflix-mac/releases)
[![GitHub Stars](https://img.shields.io/github/stars/itsmeshibintmz/netflix-mac?style=flat-square&logo=github&label=Stars&color=81b64c)](https://github.com/itsmeshibintmz/netflix-mac/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/itsmeshibintmz/netflix-mac?style=flat-square&logo=github&label=Forks&color=4a90d9)](https://github.com/itsmeshibintmz/netflix-mac/forks)
[![Latest Release](https://img.shields.io/github/v/release/itsmeshibintmz/netflix-mac?style=flat-square&logo=github&label=Latest&color=555)](https://github.com/itsmeshibintmz/netflix-mac/releases/latest)

> The native macOS Netflix app everyone has been waiting for.

A beautiful, fast, and modern macOS client built with SwiftUI and Apple's latest design language.

> ⚠️ Unofficial project. Not affiliated with, endorsed by, or sponsored by Netflix.

<img width="1774" height="887" alt="netflix banner" src="https://github.com/user-attachments/assets/36ef8c75-570b-4cc0-ae19-171a3f34aa89" />

---

## ✨ Features

- 🪟 Native macOS experience
- 🍎 SwiftUI interface
- 💎 Liquid Glass design
- ⚡ Native performance
- 🌙 Beautiful dark mode
- 🖥️ Fullscreen support
- ⌨️ Native keyboard shortcuts
- 🎬 Smooth video playback
- 📺 Responsive layouts
- 🔄 Frequent updates

More features coming soon.

---

## Screenshots

<p align="center">
<img src="images/app_screenshot.png" width="900">
</p>

---

## Installation

Requires macOS 15 or later.

Download the latest release from the Releases page.

Drag the app into Applications and launch.

## Maintainer Release Build

`build_dmg.sh` builds an ad-hoc-signed, **not notarized** DMG; no paid Apple Developer account is required. Install Xcode and `create-dmg`, then configure:

- `SPARKLE_SIGN_UPDATE`: path to Sparkle's `sign_update` executable
- `SPARKLE_PRIVATE_KEY_FILE` (optional): private EdDSA key file; otherwise `sign_update` uses the Keychain
- `OUTPUT_DIR` (optional): output directory; defaults to `~/Desktop/netflix-mac-release`
- `DMG_SKIP_FINDER=1` (optional): skip Finder styling when automation is unavailable

The script refuses to overwrite an existing artifact and verifies the DMG signature against the app's configured Sparkle public key before writing the output. Keep the matching Sparkle private key in the Keychain or a secure local file; never commit it. Publish the exact signed DMG as `Netflix.dmg` in the matching GitHub release before publishing the updated `appcast.xml` to the default branch. Use its generated signature and length, and set the appcast minimum system version to match the build. Without the existing private key, do not publish an update or replace the public key: existing installations cannot securely verify it.

Because the app is not notarized, Gatekeeper may block its first launch. Users can inspect the download and use macOS Privacy & Security settings to open it. Ad-hoc signing does not establish developer identity; Sparkle's EdDSA signature protects updates, not the initial download.
The app disables hardened-runtime library validation so an ad-hoc-signed build can load Sparkle. Other hardened-runtime protections remain enabled, but this permits loading libraries without a matching developer identity.

---

## Roadmap

- [x] Native macOS client
- [x] Liquid Glass UI
- [x] Modern navigation
- [x] Mini Player
- [x] Global media controls
- [ ] Picture in Picture
- [ ] Downloads
- [ ] Menu Bar controls
- [ ] Spotlight integration
- [ ] Apple Shortcuts
- [ ] Handoff support
- [ ] Live Activities (future)

---

## Contributing

Issues, feature requests and pull requests are welcome.

---

## Disclaimer

Netflix is a trademark of Netflix, Inc.

This project is an independent, open-source client and is not affiliated with Netflix in any way.

---

Made with ❤️ using SwiftUI
