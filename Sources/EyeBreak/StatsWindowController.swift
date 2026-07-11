import AppKit

final class StatsWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    private let statsStore: StatsStore
    private let settings = AppSettings()
    private let contentStack = NSStackView()
    private let tableView = NSTableView()
    private let computerTimeValueLabel = NSTextField(labelWithString: "")
    private let computerTimeDetailLabel = NSTextField(labelWithString: "")
    private let expectedValueLabel = NSTextField(labelWithString: "")
    private let expectedDetailLabel = NSTextField(labelWithString: "")
    private let completedValueLabel = NSTextField(labelWithString: "")
    private let completedDetailLabel = NSTextField(labelWithString: "")
    private let skippedValueLabel = NSTextField(labelWithString: "")
    private let skippedDetailLabel = NSTextField(labelWithString: "")
    private var records: [DailyBreakStats] = []
    private var refreshTimer: Timer?

    init(statsStore: StatsStore) {
        self.statsStore = statsStore

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 460),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Eye Break Stats"
        window.center()
        super.init(window: window)
        window.delegate = self
        window.contentView = makeContentView()
        refresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        refresh()
        startRefreshTimer()
        super.showWindow(sender)
    }

    func windowWillClose(_ notification: Notification) {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func makeContentView() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        contentStack.orientation = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 22),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -22),
            contentStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 22),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -22)
        ])

        buildContent()
        return container
    }

    private func buildContent() {
        let title = NSTextField(labelWithString: "Today")
        title.font = NSFont.systemFont(ofSize: 22, weight: .semibold)
        contentStack.addArrangedSubview(title)

        let cards = NSStackView(views: [
            metricCard(title: "Computer time", valueLabel: computerTimeValueLabel, detailLabel: computerTimeDetailLabel),
            metricCard(title: "Expected", valueLabel: expectedValueLabel, detailLabel: expectedDetailLabel),
            metricCard(title: "Completed", valueLabel: completedValueLabel, detailLabel: completedDetailLabel),
            metricCard(title: "Skipped", valueLabel: skippedValueLabel, detailLabel: skippedDetailLabel)
        ])
        cards.orientation = .horizontal
        cards.spacing = 10
        cards.distribution = .fillEqually
        contentStack.addArrangedSubview(cards)

        let tableTitle = NSTextField(labelWithString: "Last 7 days")
        tableTitle.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        contentStack.addArrangedSubview(tableTitle)

        let table = makeTableView()
        tableView.reloadData()
        contentStack.addArrangedSubview(table)

        let note = NSTextField(labelWithString: "Expected breaks are estimated from active computer time and your current break intervals.")
        note.font = NSFont.systemFont(ofSize: 12)
        note.textColor = .secondaryLabelColor
        contentStack.addArrangedSubview(note)
    }

    private func refresh() {
        records = statsStore.recentRecords(days: 7)
        let today = records.first ?? DailyBreakStats(day: todayKey())
        let expectedToday = expectedBreaks(for: today)

        computerTimeValueLabel.stringValue = formatActiveTime(today.activeSeconds)
        computerTimeDetailLabel.stringValue = "active use"

        expectedValueLabel.stringValue = "\(expectedToday.total)"
        expectedDetailLabel.stringValue = "\(expectedToday.eyes) eye, \(expectedToday.stand) stand"

        completedValueLabel.stringValue = "\(today.completedTotal)"
        completedDetailLabel.stringValue = "\(today.completedEyes) eye, \(today.completedStand) stand"

        skippedValueLabel.stringValue = "\(today.skippedTotal)"
        skippedDetailLabel.stringValue = "\(today.skippedEyes) eye, \(today.skippedStand) stand"

        tableView.reloadData()
    }

    private func metricCard(title: String, valueLabel: NSTextField, detailLabel: NSTextField) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 8
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.65).cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 78).isActive = true

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 24, weight: .semibold)
        valueLabel.textColor = .labelColor
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        detailLabel.font = NSFont.systemFont(ofSize: 11)
        detailLabel.textColor = .tertiaryLabelColor
        detailLabel.lineBreakMode = .byTruncatingTail
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        container.addSubview(detailLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),

            valueLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            detailLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            detailLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            detailLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2)
        ])

        return container
    }

    private func makeTableView() -> NSScrollView {
        if tableView.tableColumns.isEmpty {
            addColumn(id: "day", title: "Day", width: 120)
            addColumn(id: "active", title: "Computer", width: 100)
            addColumn(id: "expected", title: "Expected", width: 86)
            addColumn(id: "completed", title: "Done", width: 74)
            addColumn(id: "skipped", title: "Skipped", width: 82)
            addColumn(id: "snoozed", title: "Snoozed", width: 82)

            tableView.delegate = self
            tableView.dataSource = self
            tableView.headerView = NSTableHeaderView()
            tableView.usesAlternatingRowBackgroundColors = true
            tableView.rowHeight = 28
            tableView.gridStyleMask = [.solidHorizontalGridLineMask]
            tableView.allowsColumnReordering = false
            tableView.allowsColumnResizing = false
            tableView.allowsColumnSelection = false
            tableView.allowsMultipleSelection = false
            tableView.selectionHighlightStyle = .none
        }

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .lineBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.heightAnchor.constraint(equalToConstant: 230).isActive = true
        return scrollView
    }

    private func addColumn(id: String, title: String, width: CGFloat) {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
        column.title = title
        column.width = width
        column.minWidth = width
        column.maxWidth = width
        tableView.addTableColumn(column)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        records.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < records.count, let identifier = tableColumn?.identifier.rawValue else { return nil }

        let record = records[row]
        let expected = expectedBreaks(for: record)
        let text: String

        switch identifier {
        case "day":
            text = displayDay(record.day)
        case "active":
            text = formatActiveTime(record.activeSeconds)
        case "expected":
            text = "\(expected.total)"
        case "completed":
            text = "\(record.completedTotal)"
        case "skipped":
            text = "\(record.skippedTotal)"
        case "snoozed":
            text = "\(record.snoozedTotal)"
        default:
            text = ""
        }

        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = .labelColor
        label.lineBreakMode = .byTruncatingTail
        label.alignment = identifier == "day" || identifier == "active" ? .left : .right

        let cell = NSTableCellView()
        cell.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }

    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        refreshTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func expectedBreaks(for record: DailyBreakStats) -> (eyes: Int, stand: Int, total: Int) {
        let eyes = Int(floor(record.activeSeconds / settings.intervalSeconds(for: .eyes)))
        let stand = Int(floor(record.activeSeconds / settings.intervalSeconds(for: .stand)))
        return (eyes, stand, eyes + stand)
    }

    private func displayDay(_ day: String) -> String {
        if day == todayKey() {
            return "Today"
        }
        return day
    }

    private func todayKey() -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    private func formatActiveTime(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
