import Foundation

enum BreakKind: String {
    case eyes
    case stand

    var title: String {
        switch self {
        case .eyes: return "Rest your eyes"
        case .stand: return "Stand up and look far away"
        }
    }

    var message: String {
        switch self {
        case .eyes:
            return "Look at the farthest point you can see. Blink slowly."
        case .stand:
            return "Step away from the screen, stretch, and look into the distance."
        }
    }
}

enum BreakResult {
    case completed
    case skipped
    case snoozed
}

final class AppSettings {
    private let defaults = UserDefaults.standard

    private enum Key {
        static let isEnabled = "isEnabled"
        static let eyeInterval = "eyeInterval"
        static let eyeDuration = "eyeDuration"
        static let standInterval = "standInterval"
        static let standDuration = "standDuration"
        static let snoozeDuration = "snoozeDuration"
        static let launchAtLogin = "launchAtLogin"
    }

    init() {
        defaults.register(defaults: [
            Key.isEnabled: true,
            Key.eyeInterval: 20,
            Key.eyeDuration: 20,
            Key.standInterval: 60,
            Key.standDuration: 90,
            Key.snoozeDuration: 5,
            Key.launchAtLogin: false
        ])
    }

    var isEnabled: Bool {
        get { defaults.bool(forKey: Key.isEnabled) }
        set { defaults.set(newValue, forKey: Key.isEnabled) }
    }

    var eyeIntervalMinutes: Int {
        get { defaults.integer(forKey: Key.eyeInterval) }
        set { defaults.set(clamped(newValue, min: 1, max: 240), forKey: Key.eyeInterval) }
    }

    var eyeDurationSeconds: Int {
        get { defaults.integer(forKey: Key.eyeDuration) }
        set { defaults.set(clamped(newValue, min: 5, max: 600), forKey: Key.eyeDuration) }
    }

    var standIntervalMinutes: Int {
        get { defaults.integer(forKey: Key.standInterval) }
        set { defaults.set(clamped(newValue, min: 5, max: 480), forKey: Key.standInterval) }
    }

    var standDurationSeconds: Int {
        get { defaults.integer(forKey: Key.standDuration) }
        set { defaults.set(clamped(newValue, min: 10, max: 900), forKey: Key.standDuration) }
    }

    var snoozeDurationMinutes: Int {
        get { defaults.integer(forKey: Key.snoozeDuration) }
        set { defaults.set(clamped(newValue, min: 1, max: 60), forKey: Key.snoozeDuration) }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Key.launchAtLogin) }
        set { defaults.set(newValue, forKey: Key.launchAtLogin) }
    }

    func intervalSeconds(for kind: BreakKind) -> TimeInterval {
        switch kind {
        case .eyes: return TimeInterval(eyeIntervalMinutes * 60)
        case .stand: return TimeInterval(standIntervalMinutes * 60)
        }
    }

    func durationSeconds(for kind: BreakKind) -> Int {
        switch kind {
        case .eyes: return eyeDurationSeconds
        case .stand: return standDurationSeconds
        }
    }

    private func clamped(_ value: Int, min: Int, max: Int) -> Int {
        Swift.max(min, Swift.min(max, value))
    }
}
