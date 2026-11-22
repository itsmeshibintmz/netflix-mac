import AppKit
import Combine
import SwiftUI

final class MiniPlayerController: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var isFullScreen = false
    @Published private(set) var hasWindow = false

    var canToggle: Bool { hasWindow && !isFullScreen }

    private weak var window: NSWindow?
    private var originalFrame: NSRect?
    private var originalMinimumSize: NSSize?
    private var originalLevel: NSWindow.Level?
    private var fullScreenObserver: NSObjectProtocol?
    private var exitFullScreenObserver: NSObjectProtocol?
    private var closeObserver: NSObjectProtocol?

    func attach(to window: NSWindow) {
        guard self.window !== window else { return }
        restore()
        removeObservers()
        self.window = window
        hasWindow = true
        window.contentMinSize = NSSize(width: 1024, height: 680)
        isFullScreen = window.styleMask.contains(.fullScreen)
        fullScreenObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willEnterFullScreenNotification, object: window, queue: .main
        ) { [weak self] _ in
            self?.restore()
            self?.isFullScreen = true
        }
        exitFullScreenObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didExitFullScreenNotification, object: window, queue: .main
        ) { [weak self] _ in
            self?.isFullScreen = false
        }
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: window, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.restore()
            self.removeObservers()
            self.window = nil
            self.hasWindow = false
            self.isFullScreen = false
        }
    }

    func toggle() {
        if isActive {
            restore()
            return
        }
        guard let window, !isFullScreen, !window.styleMask.contains(.fullScreen) else { return }

        originalFrame = window.frame
        originalMinimumSize = window.contentMinSize
        originalLevel = window.level
        window.contentMinSize = NSSize(width: 360, height: 230)
        window.level = .floating
        let size = window.frameRect(forContentRect: NSRect(x: 0, y: 0, width: 480, height: 300)).size
        var frame = NSRect(x: window.frame.maxX - size.width, y: window.frame.maxY - size.height,
                           width: size.width, height: size.height)
        if let screen = window.screen {
            frame = window.constrainFrameRect(frame, to: screen)
        }
        isActive = true
        window.setFrame(frame, display: true)
    }

    func restore() {
        guard isActive else { return }
        if let window, let frame = originalFrame, let minimumSize = originalMinimumSize, let level = originalLevel {
            window.contentMinSize = minimumSize
            window.level = level
            window.setFrame(frame, display: true)
        }
        originalFrame = nil
        originalMinimumSize = nil
        originalLevel = nil
        isActive = false
    }

    private func removeObservers() {
        if let fullScreenObserver { NotificationCenter.default.removeObserver(fullScreenObserver) }
        if let exitFullScreenObserver { NotificationCenter.default.removeObserver(exitFullScreenObserver) }
        if let closeObserver { NotificationCenter.default.removeObserver(closeObserver) }
        fullScreenObserver = nil
        exitFullScreenObserver = nil
        closeObserver = nil
    }

    deinit {
        removeObservers()
    }
}

struct MiniPlayerWindowObserver: NSViewRepresentable {
    let controller: MiniPlayerController

    func makeNSView(context: Context) -> WindowObserverView {
        WindowObserverView(controller: controller)
    }

    func updateNSView(_ nsView: WindowObserverView, context: Context) {}
}

final class WindowObserverView: NSView {
    private let controller: MiniPlayerController

    init(controller: MiniPlayerController) {
        self.controller = controller
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        DispatchQueue.main.async { [weak self, weak window] in
            guard let self, let window, self.window === window else { return }
            self.controller.attach(to: window)
        }
    }
}
