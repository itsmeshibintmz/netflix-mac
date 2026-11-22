import AppKit
import Combine
import SwiftUI
import XCTest

@MainActor
final class MiniPlayerTests: XCTestCase {
    func testMiniPlayerShrinksAndRestoresOriginalWindow() {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 200, y: 200, width: 1100, height: 720),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        let controller = MiniPlayerController()
        controller.attach(to: window)
        let originalFrame = window.frame
        let originalMinimum = window.contentMinSize
        let originalLevel = window.level

        controller.toggle()
        XCTAssertTrue(controller.isActive)
        XCTAssertEqual(window.level, .floating)
        XCTAssertEqual(window.contentMinSize, NSSize(width: 360, height: 230))
        XCTAssertEqual(window.contentRect(forFrameRect: window.frame).size, NSSize(width: 480, height: 300))

        controller.toggle()
        XCTAssertFalse(controller.isActive)
        XCTAssertEqual(window.frame, originalFrame)
        XCTAssertEqual(window.contentMinSize, originalMinimum)
        XCTAssertEqual(window.level, originalLevel)
    }

    func testEnteringFullscreenRestoresWindowAndBlocksMiniPlayer() {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 200, y: 200, width: 1100, height: 720),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        let controller = MiniPlayerController()
        controller.attach(to: window)
        let originalFrame = window.frame
        let originalLevel = window.level
        controller.toggle()

        NotificationCenter.default.post(name: NSWindow.willEnterFullScreenNotification, object: window)
        XCTAssertFalse(controller.isActive)
        XCTAssertTrue(controller.isFullScreen)
        XCTAssertEqual(window.frame, originalFrame)
        XCTAssertEqual(window.level, originalLevel)
        controller.toggle()
        XCTAssertFalse(controller.isActive)

        NotificationCenter.default.post(name: NSWindow.didExitFullScreenNotification, object: window)
        controller.toggle()
        XCTAssertTrue(controller.isActive)
        controller.restore()
    }

    func testMiniPlayerWithSwiftUIHostedContent() {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 200, y: 200, width: 1100, height: 720),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.contentView = NSHostingView(rootView: Color.black.frame(minWidth: 360, minHeight: 230))
        window.contentView?.layoutSubtreeIfNeeded()
        let controller = MiniPlayerController()
        controller.attach(to: window)
        let originalFrame = window.frame

        controller.toggle()
        window.contentView?.layoutSubtreeIfNeeded()
        XCTAssertEqual(window.contentRect(forFrameRect: window.frame).size, NSSize(width: 480, height: 300))
        controller.restore()
        window.contentView?.layoutSubtreeIfNeeded()
        XCTAssertEqual(window.frame, originalFrame)
    }

    func testWindowObserverAttachesThroughSwiftUIBackground() {
        _ = NSApplication.shared
        let controller = MiniPlayerController()
        let attached = expectation(description: "window observer attaches")
        let subscription = controller.$hasWindow.dropFirst().filter { $0 }.sink { _ in
            attached.fulfill()
        }
        let window = NSWindow(contentRect: NSRect(x: 200, y: 200, width: 1100, height: 720),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.contentView = NSHostingView(rootView:
            Color.black.background(MiniPlayerWindowObserver(controller: controller).frame(width: 0, height: 0))
        )
        window.contentView?.layoutSubtreeIfNeeded()
        wait(for: [attached], timeout: 2)
        XCTAssertTrue(controller.canToggle)
        withExtendedLifetime(subscription) {}
    }

    func testMiniPlayerShortcutOnlyHandlesMatchingWindowAndModifiers() throws {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 200, y: 200, width: 1100, height: 720),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        let otherWindow = NSWindow(contentRect: NSRect(x: 200, y: 200, width: 800, height: 600),
                                   styleMask: [.titled], backing: .buffered, defer: false)
        let controller = MiniPlayerController()
        controller.attach(to: window)

        func keyEvent(window: NSWindow, modifiers: NSEvent.ModifierFlags, repeatKey: Bool = false) throws -> NSEvent {
            try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers,
                                           timestamp: 0, windowNumber: window.windowNumber, context: nil,
                                           characters: "M", charactersIgnoringModifiers: "M",
                                           isARepeat: repeatKey, keyCode: 46))
        }

        let plainKey = try keyEvent(window: window, modifiers: [])
        XCTAssertNotNil(controller.handleShortcut(plainKey))
        let differentShortcut = try keyEvent(window: window, modifiers: [.command, .shift, .control])
        XCTAssertNotNil(controller.handleShortcut(differentShortcut))
        let otherWindowKey = try keyEvent(window: otherWindow, modifiers: [.command, .shift])
        XCTAssertNotNil(controller.handleShortcut(otherWindowKey))
        let shortcut = try keyEvent(window: window, modifiers: [.command, .shift])
        XCTAssertNil(controller.handleShortcut(shortcut))
        XCTAssertTrue(controller.isActive)
        let repeatedShortcut = try keyEvent(window: window, modifiers: [.command, .shift], repeatKey: true)
        XCTAssertNil(controller.handleShortcut(repeatedShortcut))
        XCTAssertTrue(controller.isActive)
        XCTAssertNil(controller.handleShortcut(shortcut))
        XCTAssertFalse(controller.isActive)
    }

    func testClosingMiniPlayerRestoresWindowAndAllowsReattachment() {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 200, y: 200, width: 1100, height: 720),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        let controller = MiniPlayerController()
        controller.attach(to: window)
        let originalFrame = window.frame
        controller.toggle()

        NotificationCenter.default.post(name: NSWindow.willCloseNotification, object: window)
        XCTAssertFalse(controller.isActive)
        XCTAssertFalse(controller.canToggle)
        XCTAssertEqual(window.frame, originalFrame)
        XCTAssertEqual(window.level, .normal)

        controller.attach(to: window)
        XCTAssertTrue(controller.canToggle)
        controller.toggle()
        XCTAssertTrue(controller.isActive)
        controller.restore()
    }
}
