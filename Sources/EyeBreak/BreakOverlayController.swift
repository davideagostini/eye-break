import AppKit

final class BreakOverlayController {
    var onFinish: ((BreakResult) -> Void)?

    private let breakKind: BreakKind
    private let settings: AppSettings
    private var windows: [NSWindow] = []
    private var remainingSeconds: Int
    private var timer: Timer?
    private var countdownLabels: [NSTextField] = []
    private var didFinish = false

    init(breakKind: BreakKind, settings: AppSettings) {
        self.breakKind = breakKind
        self.settings = settings
        self.remainingSeconds = settings.durationSeconds(for: breakKind)
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)

        windows = NSScreen.screens.map { screen in
            let window = OverlayWindow(contentRect: screen.frame)
            window.screenRef = screen
            window.onCancel = { [weak self] in
                self?.cancel()
            }
            window.contentView = makeContentView()
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            return window
        }

        updateLabels()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func cancel() {
        finish(.skipped)
    }

    private func makeContentView() -> NSView {
        let view = BlockingOverlayView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(calibratedWhite: 0.04, alpha: 0.92).cgColor

        let icon = AnimatedBreakIconView(breakKind: breakKind)
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = NSTextField(labelWithString: breakKind.title)
        title.font = NSFont.systemFont(ofSize: 38, weight: .semibold)
        title.textColor = .white
        title.alignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false

        let message = NSTextField(labelWithString: breakKind.message)
        message.font = NSFont.systemFont(ofSize: 20, weight: .regular)
        message.textColor = NSColor(white: 0.86, alpha: 1)
        message.alignment = .center
        message.maximumNumberOfLines = 2
        message.lineBreakMode = .byWordWrapping
        message.translatesAutoresizingMaskIntoConstraints = false

        let countdown = NSTextField(labelWithString: "")
        countdown.font = NSFont.monospacedDigitSystemFont(ofSize: 82, weight: .medium)
        countdown.textColor = .white
        countdown.alignment = .center
        countdown.translatesAutoresizingMaskIntoConstraints = false
        countdownLabels.append(countdown)

        let skipButton = overlayButton(
            title: "Skip",
            backgroundColor: NSColor(calibratedWhite: 1, alpha: 0.30),
            textColor: .white,
            action: #selector(skip)
        )
        skipButton.keyEquivalent = "\u{1b}"

        let snoozeButton = overlayButton(
            title: "Snooze \(settings.snoozeDurationMinutes)m",
            backgroundColor: NSColor.systemMint.withAlphaComponent(0.82),
            textColor: NSColor(calibratedWhite: 0.03, alpha: 1),
            action: #selector(snooze)
        )

        let buttons = NSStackView(views: [skipButton, snoozeButton])
        buttons.orientation = .horizontal
        buttons.spacing = 12
        buttons.alignment = .centerY
        buttons.distribution = .fillEqually
        buttons.translatesAutoresizingMaskIntoConstraints = false

        let contentStack = NSStackView(views: [icon, title, message, countdown, buttons])
        contentStack.orientation = .vertical
        contentStack.spacing = 18
        contentStack.alignment = .centerX
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 40),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -40),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),

            icon.widthAnchor.constraint(equalToConstant: 112),
            icon.heightAnchor.constraint(equalToConstant: 88),

            title.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 48),
            title.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -48),

            message.widthAnchor.constraint(lessThanOrEqualToConstant: 720),
            message.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 48),
            message.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -48),

            skipButton.widthAnchor.constraint(equalToConstant: 168),
            snoozeButton.widthAnchor.constraint(equalToConstant: 168),
            skipButton.heightAnchor.constraint(equalToConstant: 48),
            snoozeButton.heightAnchor.constraint(equalToConstant: 48)
        ])

        return view
    }

    private func overlayButton(
        title: String,
        backgroundColor: NSColor,
        textColor: NSColor,
        action: Selector
    ) -> GlassOverlayButton {
        let button = GlassOverlayButton(title: title, target: self, action: action)
        button.configure(backgroundColor: backgroundColor, textColor: textColor)
        button.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.systemFont(ofSize: 17, weight: .semibold),
                .foregroundColor: textColor
            ]
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func tick() {
        remainingSeconds -= 1
        updateLabels()

        if remainingSeconds <= 0 {
            finish(.completed)
        }
    }

    private func updateLabels() {
        let safeRemainingSeconds = max(0, remainingSeconds)
        let minutes = safeRemainingSeconds / 60
        let seconds = safeRemainingSeconds % 60
        countdownLabels.forEach { $0.stringValue = String(format: "%02d:%02d", minutes, seconds) }
    }

    @objc private func skip() {
        finish(.skipped)
    }

    @objc private func snooze() {
        finish(.snoozed)
    }

    private func finish(_ result: BreakResult) {
        guard !didFinish else { return }
        didFinish = true
        timer?.invalidate()
        timer = nil
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        onFinish?(result)
    }
}
