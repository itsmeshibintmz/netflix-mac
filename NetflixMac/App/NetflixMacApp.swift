// MARK: - NetflixMacApp.swift
// Main entry point for the Netflix macOS web wrapper application.

import SwiftUI

@main
struct NetflixMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var updateManager = UpdateManager.shared
    @AppStorage("keepRunningInMenuBar") private var keepRunningInMenuBar = false

    var body: some Scene {
        Window("Netflix", id: "main") {
            NetflixWebViewContainer()
                .frame(minWidth: 1024, minHeight: 680)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            // Remove New Window command
            CommandGroup(replacing: .newItem) {}
            
            // Add Check for Updates option under application info menu
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updateManager.checkForUpdates(manual: true)
                }
                .disabled(updateManager.isCheckingForUpdates)
            }
        }

        // Native Preferences Window (accessed via ⌘,)
        Settings {
            SettingsView()
                .preferredColorScheme(.dark)
        }

        MenuBarExtra("Netflix", systemImage: "play.tv", isInserted: $keepRunningInMenuBar) {
            NetflixMenuBar()
        }
    }
}

private struct NetflixMenuBar: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject private var nowPlaying = NowPlayingManager.shared

    var body: some View {
        Text(nowPlaying.title ?? "Nothing playing")

        Button(nowPlaying.isPlaying ? "Pause" : "Play") {
            nowPlaying.togglePlayPause()
        }
        .disabled(nowPlaying.title == nil)

        Divider()

        Button("Open Netflix") {
            openWindow(id: "main")
            NSApp.unhide(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        Button("Hide Netflix") {
            NSApp.hide(nil)
        }
        Divider()
        Button("Quit Netflix") {
            NSApp.terminate(nil)
        }
    }
}
