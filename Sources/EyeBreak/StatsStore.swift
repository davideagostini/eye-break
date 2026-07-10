import Foundation

struct DailyBreakStats: Codable {
    var day: String
    var activeSeconds: TimeInterval = 0
    var completedEyes: Int = 0
    var skippedEyes: Int = 0
    var snoozedEyes: Int = 0
    var completedStand: Int = 0
    var skippedStand: Int = 0
    var snoozedStand: Int = 0

    var completedTotal: Int { completedEyes + completedStand }
    var skippedTotal: Int { skippedEyes + skippedStand }
    var snoozedTotal: Int { snoozedEyes + snoozedStand }
}

final class StatsStore {
    private var recordsByDay: [String: DailyBreakStats] = [:]
    private let calendar = Calendar.current
    private let fileURL: URL

    init() {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        let directory = baseURL.appendingPathComponent("EyeBreak", isDirectory: true)
        fileURL = directory.appendingPathComponent("stats.json")

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        load()
    }

    func recordActiveTime(_ seconds: TimeInterval, at date: Date = Date()) {
        guard seconds > 0 else { return }
        var record = record(for: date)
        record.activeSeconds += seconds
        recordsByDay[record.day] = record
        save()
    }

    func recordBreak(kind: BreakKind, result: BreakResult, at date: Date = Date()) {
        var record = record(for: date)

        switch (kind, result) {
        case (.eyes, .completed):
            record.completedEyes += 1
        case (.eyes, .skipped):
            record.skippedEyes += 1
        case (.eyes, .snoozed):
            record.snoozedEyes += 1
        case (.stand, .completed):
            record.completedStand += 1
        case (.stand, .skipped):
            record.skippedStand += 1
        case (.stand, .snoozed):
            record.snoozedStand += 1
        }

        recordsByDay[record.day] = record
        save()
    }

    func recentRecords(days: Int = 7) -> [DailyBreakStats] {
        (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            return record(for: date)
        }
    }

    private func record(for date: Date) -> DailyBreakStats {
        let key = dayKey(for: date)
        return recordsByDay[key] ?? DailyBreakStats(day: key)
    }

    private func dayKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        guard let records = try? JSONDecoder().decode([DailyBreakStats].self, from: data) else { return }
        recordsByDay = Dictionary(uniqueKeysWithValues: records.map { ($0.day, $0) })
    }

    private func save() {
        let records = recordsByDay.values.sorted { $0.day < $1.day }
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
