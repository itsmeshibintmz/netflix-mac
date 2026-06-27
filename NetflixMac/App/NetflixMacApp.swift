// MARK: - NetflixMacApp.swift
// @main entry point for the Netflix macOS application.

import SwiftUI

@main
struct NetflixMacApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Shared global state
    @StateObject private var authVM          = AuthViewModel()
    @StateObject private var watchlistManager = WatchlistManager.shared
    @StateObject private var playbackManager  = PlaybackManager.shared

    var body: some Scene {

        // MARK: Main Window
        WindowGroup {
            ContentRootView()
                .environmentObject(authVM)
                .environmentObject(watchlistManager)
                .environmentObject(playbackManager)
                .frame(minWidth: 1024, minHeight: 680)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            // Remove New Window command
            CommandGroup(replacing: .newItem) {}

            // Playback menu
            CommandMenu("Playback") {
                Button("Play / Pause") {
                    playbackManager.isPlaying.toggle()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("Seek Forward 10s") {}
                    .keyboardShortcut(.rightArrow, modifiers: .command)

                Button("Seek Back 10s") {}
                    .keyboardShortcut(.leftArrow, modifiers: .command)

                Divider()

                Button("Toggle Fullscreen") {
                    NSApp.mainWindow?.toggleFullScreen(nil)
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Picture in Picture") {}
                    .keyboardShortcut("p", modifiers: [.command, .shift])

                Divider()

                Button("Volume Up")   {}.keyboardShortcut(.upArrow,   modifiers: .command)
                Button("Volume Down") {}.keyboardShortcut(.downArrow,  modifiers: .command)
            }
        }

        // MARK: Settings Window (⌘,)
        Settings {
            SettingsView()
                .frame(minWidth: 540, minHeight: 600)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Content Root (auth gate)
struct ContentRootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isSignedIn {
                if authVM.selectedProfile != nil {
                    MainAppView()
                } else {
                    ProfileSelectionView()
                }
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.45), value: authVM.isSignedIn)
        .animation(.easeInOut(duration: 0.45), value: authVM.selectedProfile?.id)
    }
}
