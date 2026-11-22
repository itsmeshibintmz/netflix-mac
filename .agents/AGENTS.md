# Netflix macOS — Project Rules

## Release Workflow

Whenever the user asks to create a new release or release notes:

1. **Always bump the version first** — update `MARKETING_VERSION` in BOTH Debug and Release configurations inside `NetflixMac.xcodeproj/project.pbxproj` before doing anything else.

2. **Review release references across the repository** — update the README features and roadmap, this file's version history, and any other current-version or release-specific references affected by the release. Preserve historical versions. Verify the app's bundle version follows the marketing version.

3. **Always rebuild the DMG** — run `./build_dmg.sh` from the repo root after bumping the version. Use the existing Sparkle private key; never replace the public key or commit the private key.

4. **Update the appcast** — use the exact signed DMG's Sparkle signature and length, matching release tag, version and minimum macOS version. Publish the exact DMG before publishing the appcast; verify the live feed and update flow after publication.

5. **Always share the release note in chat** — output it as a fenced markdown code block (` ```markdown `) directly in the response so the user can copy-paste it straight to GitHub. Never write it to a file or artifact — always inline in chat.

6. **Release note format** — always follow this exact template:

```
### Release title
vX.Y.Z - Short Title Summary 🚀

### Release notes
Short overview summary of what this release is about.

---

## 🚀 What's New

### 🎨 Category Header Name:
* **Feature/Fix Name:** Description of what changed and why it matters.
* **Another Fix:** Description.
```

7. **Always place clean DMG on Desktop** — place the verified `Netflix.dmg` at `~/Desktop/Netflix.dmg` for attachment or local installation. The script defaults to `~/Desktop/netflix-mac-release` and refuses to overwrite artifacts; preserve any existing Desktop DMG before replacing it.

## Version History Reference

| Version | Notes |
|---------|-------|
| v1.0.0  | Initial release with SettingsView, auto-skip, OLED mode, and media controls |
| v1.1.0  | Add floating Liquid Glass control dock with auto-hide |
| v1.1.1  | Spoof desktop Safari User-Agent to enable desktop Netflix features |
| v1.2.0  | Native Auto-Updater & Custom Branded DMG 🚀 |
| v1.3.0  | Dynamic Video Quality & Liquid Glass Settings 🚀 |
| v1.3.1  | Robust Updater Caches & Native Markdown Rendering 🛠️ |
| v1.3.2  | Bundle ID Cleanups & Safari 18 DRM Profiles 🛠️ |
| v1.3.3  | Zero-Click Auto-Updates & Clean Release Notes 🚀 |
| v1.3.4  | Automated Zero-Click Updates & Clean Changelog rendering 🚀 |
| v1.3.5  | Sandbox Entitlements & Background Updater Authorization 🛠️ |
| v1.3.6  | Security Auditing & Playback Controls Fixes 🛡️ |
| v1.3.7  | Installer Permission Bypass & Playback Interaction Fixes 🛠️ |
| v1.4.0  | Clean Transparent App Icon, Updater & Playback Fixes 🚀 |
| v1.4.1  | macOS Sequoia Tinted & Dark Mode Icon Fixes 🎨 |
| v1.4.2  | macOS Sequoia Tinted & Dark Mode Icon Fixes & Security Hardening 🛡️ |
| v1.5.0  | Sparkle 2 Auto-Updater Engine & Kaset-Style UI Redesign 🚀 |
| v1.5.1  | Deep Code Signing Fix & Sparkle Framework Dyld Loading 🛡️ |
| v1.5.2  | Single Sparkle Updater UI & Feed Fixes 🚀 |
| v1.5.3  | Version & Build Number Syncing for Sparkle Auto-Updates 🛠️ |
| v1.5.4  | Full Releases History Link in Sparkle Appcast Feed 🌐 |
| v1.5.5  | EdDSA Cryptographic Signature Verification for Sparkle Updates 🔒 |
| v1.5.6  | Native Version History Viewer & Release Explorer Modal 📜 |
| v1.5.7  | Primary Kaset UI Updater Flow & Seamless Auto-Update Checks 🎨 |
| v1.6.0  | Navigation Bar Spacing & macOS Window Controls Gap 🎨 |
| v1.6.1  | In-Modal Version History Navigation & Direct DMG Downloader 🚀 |
| v1.6.2  | Dual-Mode Version History Sizing & Responsive Modal Fitting 🎨 |
| v1.7.0  | Native Control Center & Lock Screen Metadata Integration 🎵 |
| v1.7.1  | Automated In-App Updates & Live Media Metadata Sync 🛠️ |
| v2.0.0  | Playback and Update Improvements 🚀 |
| v2.1.0  | Adaptive Netflix App Icon 🎨 |
| v2.2.0  | Menu Bar Controls 🎛️ |
| v2.2.1  | Now Playing Cleanup 🛠️ |
| v2.3.0  | Mini Player 🎬 |
| v2.3.1  | Mini Player Shortcut and Mute Controls 🛠️ |
| v2.3.2  | Mini Player and Mute Controls Re-release 🛠️ |
