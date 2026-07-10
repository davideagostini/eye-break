import AppKit

final class OverlayWindow: NSWindow {
    weak var screenRef: NSScreen?
    var onCancel: (() -> Void)?

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        acceptsMouseMovedEvents = true
        ignoresMouseEvents = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }
}

final class BlockingOverlayView: NSView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {}
    override func mouseDragged(with event: NSEvent) {}
    override func mouseUp(with event: NSEvent) {}
    override func rightMouseDown(with event: NSEvent) {}
    override func rightMouseDragged(with event: NSEvent) {}
    override func rightMouseUp(with event: NSEvent) {}
    override func otherMouseDown(with event: NSEvent) {}
    override func otherMouseDragged(with event: NSEvent) {}
    override func otherMouseUp(with event: NSEvent) {}
    override func scrollWheel(with event: NSEvent) {}
}

final class AnimatedBreakIconView: NSView {
    private let breakKind: BreakKind
    private let imageView = NSImageView()

    init(breakKind: BreakKind) {
        self.breakKind = breakKind
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            imageView.layer?.removeAllAnimations()
        } else {
            startAnimation()
        }
    }

    private func setup() {
        wantsLayer = true
        layer?.masksToBounds = false

        imageView.image = NSImage(
            systemSymbolName: breakKind == .eyes ? "eye" : "figure.stand",
            accessibilityDescription: nil
        )
        imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 64, weight: .regular)
        imageView.contentTintColor = NSColor.systemMint
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.wantsLayer = true
        imageView.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        imageView.layer?.shadowColor = NSColor.systemMint.cgColor
        imageView.layer?.shadowOpacity = 0.28
        imageView.layer?.shadowRadius = 18
        imageView.layer?.shadowOffset = .zero
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 96),
            imageView.heightAnchor.constraint(equalToConstant: 78)
        ])
    }

    private func startAnimation() {
        imageView.layer?.removeAllAnimations()

        switch breakKind {
        case .eyes:
            startEyeAnimation()
        case .stand:
            startStandAnimation()
        }
    }

    private func startEyeAnimation() {
        let blink = CAKeyframeAnimation(keyPath: "transform.scale.y")
        blink.values = [1, 1, 0.18, 1, 1]
        blink.keyTimes = [0, 0.54, 0.60, 0.68, 1]
        blink.duration = 2.6
        blink.repeatCount = .infinity
        blink.timingFunctions = [
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        imageView.layer?.add(blink, forKey: "eyeBlink")

        let glow = CABasicAnimation(keyPath: "shadowOpacity")
        glow.fromValue = 0.18
        glow.toValue = 0.42
        glow.duration = 1.3
        glow.autoreverses = true
        glow.repeatCount = .infinity
        glow.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        imageView.layer?.add(glow, forKey: "eyeGlow")
    }

    private func startStandAnimation() {
        let breathe = CAKeyframeAnimation(keyPath: "transform.scale")
        breathe.values = [1, 1.055, 1]
        breathe.keyTimes = [0, 0.5, 1]
        breathe.duration = 2.2
        breathe.repeatCount = .infinity
        breathe.timingFunctions = [
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        imageView.layer?.add(breathe, forKey: "standBreathe")

        let rise = CAKeyframeAnimation(keyPath: "transform.translation.y")
        rise.values = [0, 3, 0]
        rise.keyTimes = [0, 0.5, 1]
        rise.duration = 2.2
        rise.repeatCount = .infinity
        rise.timingFunctions = [
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        imageView.layer?.add(rise, forKey: "standRise")
    }
}

final class GlassOverlayButton: NSButton {
    private var baseBackgroundColor = NSColor.white.withAlphaComponent(0.3)
    private var textColor = NSColor.white
    private var trackingArea: NSTrackingArea?

    func configure(backgroundColor: NSColor, textColor: NSColor) {
        self.baseBackgroundColor = backgroundColor
        self.textColor = textColor
        isBordered = false
        wantsLayer = true
        font = NSFont.systemFont(ofSize: 17, weight: .semibold)
        layer?.cornerRadius = 24
        layer?.masksToBounds = false
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.35).cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.28
        layer?.shadowRadius = 18
        layer?.shadowOffset = CGSize(width: 0, height: 8)
        updateAppearance(alphaBoost: 0)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        )
        trackingArea = area
        addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        updateAppearance(alphaBoost: 0.12)
    }

    override func mouseExited(with event: NSEvent) {
        updateAppearance(alphaBoost: 0)
    }

    override func mouseDown(with event: NSEvent) {
        updateAppearance(alphaBoost: 0.22)
        super.mouseDown(with: event)
        updateAppearance(alphaBoost: 0.12)
    }

    private func updateAppearance(alphaBoost: CGFloat) {
        guard let layer else { return }
        let color = baseBackgroundColor.withAlphaComponent(min(baseBackgroundColor.alphaComponent + alphaBoost, 0.95))
        layer.backgroundColor = color.cgColor
        layer.borderColor = NSColor.white.withAlphaComponent(0.42 + alphaBoost).cgColor
        contentTintColor = textColor
    }
}
