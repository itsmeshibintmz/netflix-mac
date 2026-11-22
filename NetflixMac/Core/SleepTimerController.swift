import AppKit
import Combine

@MainActor
final class SleepTimerController: ObservableObject {
    static let customDurationRange = 1...720

    @Published private(set) var deadline: Date?
    @Published var errorMessage: String?

    private let pause: (@escaping (Error?) -> Void) -> Void
    private let now: () -> Date
    private var timer: Timer?
    private var wakeObserver: NSObjectProtocol?

    init(
        pause: @escaping (@escaping (Error?) -> Void) -> Void,
        now: @escaping () -> Date = Date.init
    ) {
        self.pause = pause
        self.now = now
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.checkDeadline()
            }
        }
    }

    deinit {
        timer?.invalidate()
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
    }

    func start(minutes: Int) {
        precondition(minutes > 0, "Sleep timer duration must be positive")
        timer?.invalidate()
        errorMessage = nil
        deadline = now().addingTimeInterval(TimeInterval(minutes) * 60)
        scheduleTimer()
    }

    @discardableResult
    func start(customMinutes value: String) -> Bool {
        guard let minutes = Self.customMinutes(from: value) else { return false }
        start(minutes: minutes)
        return true
    }

    static func customMinutes(from value: String) -> Int? {
        guard let minutes = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)),
              customDurationRange.contains(minutes) else {
            return nil
        }
        return minutes
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        deadline = nil
    }

    private func scheduleTimer() {
        guard let deadline else { return }
        let timer = Timer(timeInterval: max(deadline.timeIntervalSince(now()), 0.01), repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.checkDeadline()
            }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func checkDeadline() {
        guard let deadline else { return }
        timer?.invalidate()
        timer = nil
        guard now() >= deadline else {
            scheduleTimer()
            return
        }
        self.deadline = nil
        pause { [weak self] error in
            guard let error else { return }
            self?.errorMessage = "The sleep timer couldn't pause Netflix: \(error.localizedDescription)"
        }
    }
}
