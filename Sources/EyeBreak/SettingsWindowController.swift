import AppKit

final class SettingsWindowController: NSWindowController {
    private let scheduler: BreakScheduler
    private let loginItem: LoginItemManager
    private let settings = AppSettings()

    init(scheduler: BreakScheduler, loginItem: LoginItemManager) {
        self.scheduler = scheduler
        self.loginItem = loginItem

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 390),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Eye Break Settings"
        window.center()
        super.init(window: window)
        window.contentView = makeContentView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeContentView() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let enabled = checkbox("Enabled", isOn: settings.isEnabled, action: #selector(toggleEnabled(_:)))
        let login = checkbox("Start at login", isOn: settings.launchAtLogin, action: #selector(toggleLogin(_:)))

        let eyeInterval = stepperRow("Eye break every", value: settings.eyeIntervalMinutes, suffix: "min", action: #selector(updateEyeInterval(_:)))
        let eyeDuration = stepperRow("Eye break duration", value: settings.eyeDurationSeconds, suffix: "sec", action: #selector(updateEyeDuration(_:)))
        let standInterval = stepperRow("Stand break every", value: settings.standIntervalMinutes, suffix: "min", action: #selector(updateStandInterval(_:)))
        let standDuration = stepperRow("Stand break duration", value: settings.standDurationSeconds, suffix: "sec", action: #selector(updateStandDuration(_:)))
        let snooze = stepperRow("Snooze duration", value: settings.snoozeDurationMinutes, suffix: "min", action: #selector(updateSnooze(_:)))

        let stack = NSStackView(views: [
            enabled,
            login,
            separator(),
            eyeInterval,
            eyeDuration,
            standInterval,
            standDuration,
            snooze
        ])
        stack.orientation = .vertical
        stack.spacing = 14
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 24)
        ])

        return container
    }

    private func checkbox(_ title: String, isOn: Bool, action: Selector) -> NSButton {
        let button = NSButton(checkboxWithTitle: title, target: self, action: action)
        button.state = isOn ? .on : .off
        return button
    }

    private func separator() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        box.translatesAutoresizingMaskIntoConstraints = false
        box.widthAnchor.constraint(equalToConstant: 360).isActive = true
        return box
    }

    private func stepperRow(_ labelText: String, value: Int, suffix: String, action: Selector) -> NSView {
        let label = NSTextField(labelWithString: labelText)
        label.font = .systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false

        let valueField = NSTextField(string: "\(value)")
        valueField.isEditable = true
        valueField.alignment = .right
        valueField.tag = valueFieldTag(for: action)
        valueField.target = self
        valueField.action = action
        valueField.translatesAutoresizingMaskIntoConstraints = false

        let suffixLabel = NSTextField(labelWithString: suffix)
        suffixLabel.textColor = .secondaryLabelColor

        let row = NSStackView(views: [label, valueField, suffixLabel])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: 180),
            valueField.widthAnchor.constraint(equalToConstant: 72)
        ])

        return row
    }

    private func valueFieldTag(for action: Selector) -> Int {
        switch action {
        case #selector(updateEyeInterval(_:)): return 1
        case #selector(updateEyeDuration(_:)): return 2
        case #selector(updateStandInterval(_:)): return 3
        case #selector(updateStandDuration(_:)): return 4
        default: return 5
        }
    }

    @objc private func toggleEnabled(_ sender: NSButton) {
        settings.isEnabled = sender.state == .on
        scheduler.reloadSettings()
    }

    @objc private func toggleLogin(_ sender: NSButton) {
        let enabled = sender.state == .on
        settings.launchAtLogin = enabled
        do {
            try loginItem.setEnabled(enabled)
        } catch {
            sender.state = enabled ? .off : .on
            settings.launchAtLogin = sender.state == .on
            showError("Could not update login item: \(error.localizedDescription)")
        }
    }

    @objc private func updateEyeInterval(_ sender: NSTextField) {
        settings.eyeIntervalMinutes = sender.integerValue
        scheduler.reloadSettings()
    }

    @objc private func updateEyeDuration(_ sender: NSTextField) {
        settings.eyeDurationSeconds = sender.integerValue
        scheduler.reloadSettings()
    }

    @objc private func updateStandInterval(_ sender: NSTextField) {
        settings.standIntervalMinutes = sender.integerValue
        scheduler.reloadSettings()
    }

    @objc private func updateStandDuration(_ sender: NSTextField) {
        settings.standDurationSeconds = sender.integerValue
        scheduler.reloadSettings()
    }

    @objc private func updateSnooze(_ sender: NSTextField) {
        settings.snoozeDurationMinutes = sender.integerValue
        scheduler.reloadSettings()
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Eye Break"
        alert.informativeText = message
        alert.runModal()
    }
}
