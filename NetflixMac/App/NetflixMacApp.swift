// MARK: - NetflixMacApp.swift
// Main entry point for the Netflix macOS web wrapper application.

import SwiftUI

@main
struct NetflixMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var updateManager = UpdateManager.shared
    @StateObject private var miniPlayer = MiniPlayerController()
    @StateObject private var sleepTimer = SleepTimerController(pause: NowPlayingManager.shared.pausePlayback)
    @State private var isCustomSleepTimerPresented = false

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
                .sheet(isPresented: $isCustomSleepTimerPresented) {
                    CustomSleepTimerView(controller: sleepTimer)
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
                    Divider()
                    Button("Custom...") {
                        isCustomSleepTimerPresented = true
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

private struct CustomSleepTimerView: View {
    @ObservedObject var controller: SleepTimerController
    @Environment(\.dismiss) private var dismiss
    @State private var minutes = ""

    private var parsedMinutes: Int? {
        SleepTimerController.customMinutes(from: minutes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Custom Sleep Timer")
                    .font(.title2.bold())
                Text("Netflix will pause automatically after this duration.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                TextField("Minutes", text: $minutes)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onSubmit(startTimer)
                Text("minutes")
                    .foregroundStyle(.secondary)
            }

            Text("Enter 1 to \(SleepTimerController.customDurationRange.upperBound) minutes.")
                .font(.caption)
                .foregroundStyle(parsedMinutes == nil && !minutes.isEmpty ? Color.red : Color.secondary)

            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Spacer()
                Button("Start Timer") {
                    startTimer()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(parsedMinutes == nil)
            }
        }
        .padding(24)
        .frame(width: 340)
        .onAppear {
            minutes = ""
        }
    }

    private func startTimer() {
        if controller.start(customMinutes: minutes) {
            dismiss()
        }
    }
}
