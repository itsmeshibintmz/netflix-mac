// MARK: - NetflixMacApp.swift
// Main entry point for the Netflix macOS web wrapper application.

import SwiftUI

@main
struct NetflixMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var updateManager = UpdateManager.shared
    @StateObject private var miniPlayer = MiniPlayerController()
    @StateObject private var sleepTimer = SleepTimerController(pause: NowPlayingManager.shared.pausePlayback)

    var body: some Scene {
        Window("Netflix", id: "main") {
            NetflixWebViewContainer(miniPlayer: miniPlayer)
                .frame(minWidth: 360, minHeight: 230)
                .preferredColorScheme(.dark)
                .alert("Sleep Timer", isPresented: Binding(
                    get: { sleepTimer.errorMessage != nil },
                    set: { if !$0 { sleepTimer.errorMessage = nil } }
                )) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(sleepTimer.errorMessage ?? "")
                }
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

            CommandMenu("Playback") {
                Button(miniPlayer.isActive ? "Exit Mini Player" : "Enter Mini Player") {
                    miniPlayer.toggle()
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
                .disabled(!miniPlayer.canToggle)

                Menu("Sleep Timer") {
                    if let deadline = sleepTimer.deadline {
                        Text("Pause at \(deadline.formatted(date: .omitted, time: .shortened))")
                        Button("Cancel Sleep Timer") {
                            sleepTimer.cancel()
                        }
                        Divider()
                    }
                    ForEach([15, 30, 45, 60, 90, 120], id: \.self) { minutes in
                        Button("\(minutes) minutes") {
                            sleepTimer.start(minutes: minutes)
                        }
                    }
                }
            }
        }

        // Native Preferences Window (accessed via ⌘,)
        Settings {
            SettingsView()
                .preferredColorScheme(.dark)
        }

    }
}
