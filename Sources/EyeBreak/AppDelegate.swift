import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var scheduler: BreakScheduler!
    private var settingsWindowController: SettingsWindowController?
    private var statsWindowController: StatsWindowController?
    private var activeOverlayController: BreakOverlayController?
    private var enabledItem: NSMenuItem!
    private var pause30Item: NSMenuItem!
    private var pause60Item: NSMenuItem!
    private var resumeItem: NSMenuItem!
    private let statsStore = StatsStore()
    private let loginItem = LoginItemManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let settings = AppSettings()
        scheduler = BreakScheduler(settings: settings, statsStore: statsStore)
        scheduler.onBreakRequested = { [weak self] breakKind in
            self?.showBreak(breakKind)
        }

        configureStatusItem(settings: settings)
        scheduler.start()

        if settings.launchAtLogin {
            try? loginItem.setEnabled(true)
        }
    }

    private func configureStatusItem(settings: AppSettings) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Eye Break")

        let menu = NSMenu()
        menu.addItem(sectionHeader("Status"))

        enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledItem.state = settings.isEnabled ? .on : .off
        enabledItem.target = self
        menu.addItem(enabledItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(sectionHeader("Controls"))

        let stopItem = NSMenuItem(title: "Stop Current Break", action: #selector(stopCurrentBreak), keyEquivalent: ".")
        stopItem.target = self
        stopItem.image = textBadgeIcon("STOP")
        menu.addItem(stopItem)

        pause30Item = NSMenuItem(title: "Pause for 30 min", action: #selector(pauseFor30Minutes), keyEquivalent: "")
        pause30Item.target = self
        pause30Item.image = textBadgeIcon("30m")
        menu.addItem(pause30Item)

        pause60Item = NSMenuItem(title: "Pause for 1 hour", action: #selector(pauseForOneHour), keyEquivalent: "")
        pause60Item.target = self
        pause60Item.image = textBadgeIcon("1h")
        menu.addItem(pause60Item)

        resumeItem = NSMenuItem(title: "Resume", action: #selector(resumeBreaks), keyEquivalent: "")
        resumeItem.target = self
        resumeItem.image = textBadgeIcon("GO")
        menu.addItem(resumeItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(sectionHeader("Test"))

        let eyeBreakItem = NSMenuItem(title: "Show Eye Break Now", action: #selector(showEyeBreakNow), keyEquivalent: "")
        eyeBreakItem.target = self
        eyeBreakItem.image = menuIcon("eye")
        menu.addItem(eyeBreakItem)

        let standBreakItem = NSMenuItem(title: "Test Stand Break Now", action: #selector(showStandBreakNow), keyEquivalent: "")
        standBreakItem.target = self
        standBreakItem.image = menuIcon("figure.stand")
        menu.addItem(standBreakItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(sectionHeader("App"))

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.image = menuIcon("gearshape")
        menu.addItem(settingsItem)

        let statsItem = NSMenuItem(title: "Today's Stats...", action: #selector(openStats), keyEquivalent: "")
        statsItem.target = self
        statsItem.image = menuIcon("chart.bar")
        menu.addItem(statsItem)

        let versionItem = NSMenuItem(title: "Version \(appVersionString())", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        versionItem.image = menuIcon("info.circle")
        menu.addItem(versionItem)

        let quitItem = NSMenuItem(title: "Quit Eye Break", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.image = menuIcon("power")
        menu.addItem(quitItem)

        statusItem.menu = menu
        updateMenuState()
    }

    private func sectionHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title.uppercased(), action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.attributedTitle = NSAttributedString(
            string: title.uppercased(),
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        return item
    }

    private func menuIcon(_ symbolName: String) -> NSImage? {
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        image?.isTemplate = true
        image?.size = NSSize(width: 16, height: 16)
        return image
    }

    private func appVersionString() -> String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }

    private func textBadgeIcon(_ text: String) -> NSImage {
        let size = NSSize(width: 34, height: 16)
        let image = NSImage(size: size)
        image.lockFocus()

        let rect = NSRect(origin: .zero, size: size)
        NSColor.controlAccentColor.withAlphaComponent(0.18).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5).fill()

        NSColor.controlAccentColor.withAlphaComponent(0.9).setStroke()
        let strokePath = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 4.5, yRadius: 4.5)
        strokePath.lineWidth = 1
        strokePath.stroke()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: NSColor.labelColor
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        attributedText.draw(at: NSPoint(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2
        ))

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        let settings = AppSettings()
        settings.isEnabled.toggle()
        sender.state = settings.isEnabled ? .on : .off
        scheduler.reloadSettings()

        if settings.isEnabled {
            scheduler.resume()
        } else {
            stopCurrentBreak()
        }
        updateMenuState()
    }

    @objc private func showEyeBreakNow() {
        scheduler.requestManualBreak(.eyes)
    }

    @objc private func showStandBreakNow() {
        scheduler.requestManualBreak(.stand)
    }

    @objc private func stopCurrentBreak() {
        if let controller = activeOverlayController {
            controller.cancel()
        } else {
            scheduler.cancelActiveBreak()
        }
        updateMenuState()
    }

    @objc private func pauseFor30Minutes() {
        pauseBreaks(for: 30 * 60)
    }

    @objc private func pauseForOneHour() {
        pauseBreaks(for: 60 * 60)
    }

    @objc private func resumeBreaks() {
        scheduler.resume()
        updateMenuState()
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(
                scheduler: scheduler,
                loginItem: loginItem
            )
        }

        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(nil)
    }

    @objc private func openStats() {
        if statsWindowController == nil {
            statsWindowController = StatsWindowController(statsStore: statsStore)
        }

        NSApp.activate(ignoringOtherApps: true)
        statsWindowController?.showWindow(nil)
    }

    private func showBreak(_ breakKind: BreakKind) {
        let controller = BreakOverlayController(breakKind: breakKind, settings: AppSettings())
        controller.onFinish = { [weak self] result in
            self?.activeOverlayController = nil
            self?.scheduler.breakFinished(breakKind, result: result)
            self?.updateMenuState()
        }
        activeOverlayController = controller
        controller.show()
    }

    private func pauseBreaks(for duration: TimeInterval) {
        scheduler.pause(for: duration)
        if let controller = activeOverlayController {
            controller.cancel()
        } else {
            scheduler.cancelActiveBreak()
        }
        updateMenuState()
    }

    private func updateMenuState() {
        let settings = AppSettings()
        enabledItem?.state = settings.isEnabled ? .on : .off
        pause30Item?.isEnabled = settings.isEnabled
        pause60Item?.isEnabled = settings.isEnabled
        resumeItem?.isEnabled = settings.isEnabled && scheduler.isManuallyPaused
    }
}
