# Netflix macOS — Project Rules

## Release Workflow

Whenever the user asks to create a new release or release notes:

1. **Always bump the version first** — update `MARKETING_VERSION` in BOTH Debug and Release configurations inside `NetflixMac.xcodeproj/project.pbxproj` before doing anything else.

2. **Always rebuild the DMG** — run `./build_dmg.sh` from the repo root after bumping the version.

3. **Always share the release note in chat** — output it as a fenced markdown code block (` ```markdown `) directly in the response so the user can copy-paste it straight to GitHub. Never write it to a file or artifact — always inline in chat.

4. **Release note format** — always follow this exact template:

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
