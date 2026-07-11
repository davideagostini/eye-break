import CoreGraphics
import Foundation
import IOKit

final class BreakScheduler {
    var onBreakRequested: ((BreakKind) -> Void)?

    private let maximumTickInterval: TimeInterval = 5
    private var settings: AppSettings
    private let statsStore: StatsStore
    private var timer: Timer?
    private var eyeActiveSeconds: TimeInterval = 0
    private var standActiveSeconds: TimeInterval = 0
    private var lastTick = Date()
    private var activeBreak: BreakKind?
    private var snoozedUntil: Date?
    private var pausedUntil: Date?

    init(settings: AppSettings, statsStore: StatsStore) {
        self.settings = settings
        self.statsStore = statsStore
    }

    func start() {
        timer?.invalidate()
        lastTick = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func reloadSettings() {
        settings = AppSettings()
    }

    var hasActiveBreak: Bool {
        activeBreak != nil
    }

    var manualPauseRemainingSeconds: TimeInterval? {
        guard let pausedUntil else { return nil }
        let remaining = pausedUntil.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }

    var snoozeRemainingSeconds: TimeInterval? {
        guard let snoozedUntil else { return nil }
        let remaining = snoozedUntil.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }

    var isManuallyPaused: Bool {
        manualPauseRemainingSeconds != nil
    }

    func remainingSeconds(until kind: BreakKind) -> TimeInterval {
        settings = AppSettings()
        let elapsed: TimeInterval
        switch kind {
        case .eyes:
            elapsed = eyeActiveSeconds
        case .stand:
            elapsed = standActiveSeconds
        }
        return max(0, settings.intervalSeconds(for: kind) - elapsed)
    }

    func requestManualBreak(_ kind: BreakKind = .eyes) {
        guard activeBreak == nil else { return }
        pausedUntil = nil
        snoozedUntil = nil
        requestBreak(kind)
    }

    func pause(for duration: TimeInterval) {
        pausedUntil = Date().addingTimeInterval(duration)
        lastTick = Date()
    }

    func resume() {
        pausedUntil = nil
        snoozedUntil = nil
        lastTick = Date()
    }

    func breakFinished(_ kind: BreakKind, result: BreakResult) {
        activeBreak = nil
        statsStore.recordBreak(kind: kind, result: result)

        switch result {
        case .completed, .skipped:
            switch kind {
            case .eyes:
                eyeActiveSeconds = 0
            case .stand:
                eyeActiveSeconds = 0
                standActiveSeconds = 0
            }
            snoozedUntil = nil
        case .snoozed:
            snoozedUntil = Date().addingTimeInterval(TimeInterval(settings.snoozeDurationMinutes * 60))
        }
    }

    func cancelActiveBreak() {
        activeBreak = nil
        snoozedUntil = nil
    }

    private func tick() {
        settings = AppSettings()
        guard settings.isEnabled, activeBreak == nil else {
            lastTick = Date()
            return
        }

        if let pausedUntil {
            if Date() < pausedUntil {
                lastTick = Date()
                return
            }
            self.pausedUntil = nil
        }

        if let snoozedUntil, Date() < snoozedUntil {
            lastTick = Date()
            return
        }

        let now = Date()
        let delta = now.timeIntervalSince(lastTick)
        lastTick = now

        guard delta <= maximumTickInterval else { return }
        guard isUserActive else { return }
        eyeActiveSeconds += delta
        standActiveSeconds += delta
        statsStore.recordActiveTime(delta)

        if standActiveSeconds >= settings.intervalSeconds(for: .stand) {
            requestBreak(.stand)
        } else if eyeActiveSeconds >= settings.intervalSeconds(for: .eyes) {
            requestBreak(.eyes)
        }
    }

    private func requestBreak(_ kind: BreakKind) {
        activeBreak = kind
        onBreakRequested?(kind)
    }

    private var isUserActive: Bool {
        IdleTime.secondsSinceLastInput < 60
    }
}

enum IdleTime {
    static var secondsSinceLastInput: TimeInterval {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
        guard service != 0 else {
            return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
        }
        defer { IOObjectRelease(service) }

        let key = "HIDIdleTime" as CFString
        guard let unmanaged = IORegistryEntryCreateCFProperty(service, key, kCFAllocatorDefault, 0) else {
            return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
        }

        let value = unmanaged.takeRetainedValue()
        if CFGetTypeID(value) == CFNumberGetTypeID() {
            let number = value as! CFNumber
            var nanoseconds: Int64 = 0
            CFNumberGetValue(number, .sInt64Type, &nanoseconds)
            return TimeInterval(nanoseconds) / 1_000_000_000
        }

        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
    }
}
