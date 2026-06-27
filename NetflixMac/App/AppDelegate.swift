// MARK: - AppDelegate.swift
// NSApplicationDelegate: status bar mini player, appearance, Touch Bar.

import AppKit
import SwiftUI
import AVKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Status Bar
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    // MARK: - Launch
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        setupAppearance()
        requestNotificationPermission()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep alive in status bar (dock icon hidden) — set LSUIElement if desired
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Status Bar Mini Player
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            let image = NSImage(systemSymbolName: "play.circle.fill",
                                accessibilityDescription: "Netflix Mini Player")
            image?.isTemplate = true
            button.image = image
            button.action = #selector(togglePopover(_:))
            button.target  = self
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button else { return }

        if let popover, popover.isShown {
            popover.performClose(sender)
        } else {
            let pop = NSPopover()
            pop.contentSize  = NSSize(width: 300, height: 190)
            pop.behavior     = .transient
            pop.animates     = true
            pop.contentViewController = NSHostingController(
                rootView: MiniPlayerView()
                    .environmentObject(PlaybackManager.shared)
                    .frame(width: 300, height: 190)
            )
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            self.popover = pop
        }
    }

    // MARK: - Appearance
    private func setupAppearance() {
        // Force dark aqua appearance globally
        NSApp.appearance = NSAppearance(named: .darkAqua)
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    // MARK: - Notifications
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Touch Bar (for Intel Macs)
    // Touch Bar items are registered via NSTouchBarProvider on NSWindowController
    // See: https://developer.apple.com/documentation/appkit/nstouchbar
}

// Needed for UNUserNotificationCenter
import UserNotifications
