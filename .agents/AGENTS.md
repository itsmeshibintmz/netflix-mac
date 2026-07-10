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
| v1.2.0  | Initial release |
| v1.3.0  | Liquid Glass Pill Dock, mini player, and settings menu |
| v1.3.1  | trap SIGHUP and PID checking to stabilize update relauncher |
| v1.3.2  | Pill layout padding and playback interaction adjustments |
| v1.3.3  | Spacebar play/pause focus preservation (.focusable(false)) |
| v1.3.4  | Relauncher output logging redirect for diagnostic testing |
| v1.3.5  | Switch update folder to /tmp to bypass macOS TCC security prompts |
| v1.3.6  | Build system and dependency cleanup |
| v1.3.7  | OLED mode style updates and floating pill menu layout refinements |
| v1.4.0  | Redesigned app icon scaling, automated updater fixes |
| v1.4.1  | Pure transparent app icon & target 15.0 to fix dark/tinted modes |
