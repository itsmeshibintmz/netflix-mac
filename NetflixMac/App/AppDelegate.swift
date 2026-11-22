// MARK: - AppDelegate.swift
// NSApplicationDelegate: Handles global appearance and application lifecycle.

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupAppearance()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !UserDefaults.standard.bool(forKey: "keepRunningInMenuBar")
    }

    private func setupAppearance() {
        // Force dark aqua appearance globally
        NSApp.appearance = NSAppearance(named: .darkAqua)
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}
