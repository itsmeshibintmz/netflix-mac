# <img src="images/app_icon.png" width="60" align="center" valign="middle"> Netflix for macOS

A beautiful, native macOS desktop app wrapper for **Netflix**. Built with **SwiftUI + WebKit**, it runs Netflix full-bleed (edge-to-edge) as a standalone desktop app outside of your web browser.

---

## 📸 Screenshots

### The App Interface
The interface runs completely edge-to-edge, with Netflix's top menu shifted to make room for the macOS window controls.
![Netflix macOS Interface](images/app_screenshot.png)

---

## ✨ Features

*   **📺 Full-bleed Video Canvas:** The video player runs edge-to-edge, sitting directly under the macOS translucent title bar.
*   **🚥 Smart Window Layout:** Netflix's web header is dynamically shifted by `80px` to the right, keeping it clear of the native macOS Close, Minimize, and Maximize traffic lights.
*   **🫵 Trackpad Gestures:** Support for native trackpad swipes (left/right) to navigate back and forward, just like in Safari.
*   **👤 Saved Login Sessions:** Keeps you logged in between launches by securely persisting your session cookies.
*   **📜 Custom Thin Scrollbars:** Replaces chunky web scrollbars with ultra-thin, sleek translucent tracks that match macOS system styles.
*   **💎 Liquid Glass Icon:** Custom high-res glassmorphism app icon designed to look native on your Dock.

---

## 🚀 How to Run (Simple Steps)

### 1. Open the project
Double-click `NetflixMac.xcodeproj` to open it in Xcode.

### 2. Set up signing
1. Click the blue **`Netflix`** project at the top of the left sidebar.
2. Select the **`Netflix`** target.
3. Click the **`Signing & Capabilities`** tab at the top.
4. Set the **Team** dropdown to your Apple ID.
   * *Note:* If Xcode asks for a keychain password you don't know, uncheck "Automatically manage signing" and change the **Signing Certificate** dropdown to **`Sign to Run Locally`** to bypass it.

### 3. Build & Run
* Press **⌘R** (or click the Play button in Xcode).
* Log in with your real Netflix credentials and start watching!

---

## 🛠️ Built With

- **SwiftUI** — Modern declarative UI framework.
- **WebKit (WKWebView)** — High-performance HTML5 rendering engine.
- **FairPlay DRM** — Native Apple hardware-decryption for secure streaming.
