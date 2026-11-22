import AppKit
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
