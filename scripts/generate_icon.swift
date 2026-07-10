import AppKit

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "build/AppIcon.iconset")
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

struct IconAsset {
    let filename: String
    let size: CGFloat
}

let assets = [
    IconAsset(filename: "icon_16x16.png", size: 16),
    IconAsset(filename: "icon_16x16@2x.png", size: 32),
    IconAsset(filename: "icon_32x32.png", size: 32),
    IconAsset(filename: "icon_32x32@2x.png", size: 64),
    IconAsset(filename: "icon_128x128.png", size: 128),
    IconAsset(filename: "icon_128x128@2x.png", size: 256),
    IconAsset(filename: "icon_256x256.png", size: 256),
    IconAsset(filename: "icon_256x256@2x.png", size: 512),
    IconAsset(filename: "icon_512x512.png", size: 512),
    IconAsset(filename: "icon_512x512@2x.png", size: 1024)
]

for asset in assets {
    let destination = outputDirectory.appendingPathComponent(asset.filename)
    let pngData = drawIconPNG(size: Int(asset.size))
    try pngData.write(to: destination)
}

private func drawIconPNG(size: Int) -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Could not create \(size)x\(size) bitmap")
    }

    let size = CGFloat(size)
    bitmap.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    let scale = size / 1024
    let iconRect = rect.insetBy(dx: 72 * scale, dy: 72 * scale)
    let cornerRadius = 224 * scale
    let backgroundPath = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)

    let backgroundGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.07, green: 0.13, blue: 0.13, alpha: 1),
        NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.10, alpha: 1)
    ])
    backgroundGradient?.draw(in: backgroundPath, angle: -42)

    NSColor.white.withAlphaComponent(0.12).setStroke()
    backgroundPath.lineWidth = max(1, 5 * scale)
    backgroundPath.stroke()

    let highlightRect = NSRect(
        x: iconRect.minX + 72 * scale,
        y: iconRect.midY + 84 * scale,
        width: iconRect.width - 144 * scale,
        height: iconRect.height * 0.34
    )
    let highlight = NSBezierPath(roundedRect: highlightRect, xRadius: 96 * scale, yRadius: 96 * scale)
    NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.18),
        NSColor.white.withAlphaComponent(0.02)
    ])?.draw(in: highlight, angle: 90)

    drawEye(in: rect, scale: scale)
    drawPauseBars(in: rect, scale: scale)

    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode \(Int(size))x\(Int(size)) icon")
    }
    return pngData
}

private func drawEye(in rect: NSRect, scale: CGFloat) {
    let center = CGPoint(x: rect.midX, y: rect.midY + 46 * scale)
    let eyeWidth = 610 * scale
    let eyeHeight = 300 * scale
    let left = CGPoint(x: center.x - eyeWidth / 2, y: center.y)
    let right = CGPoint(x: center.x + eyeWidth / 2, y: center.y)

    let eyePath = NSBezierPath()
    eyePath.move(to: left)
    eyePath.curve(
        to: right,
        controlPoint1: CGPoint(x: center.x - 190 * scale, y: center.y + eyeHeight / 2),
        controlPoint2: CGPoint(x: center.x + 190 * scale, y: center.y + eyeHeight / 2)
    )
    eyePath.curve(
        to: left,
        controlPoint1: CGPoint(x: center.x + 190 * scale, y: center.y - eyeHeight / 2),
        controlPoint2: CGPoint(x: center.x - 190 * scale, y: center.y - eyeHeight / 2)
    )
    eyePath.close()

    let mint = NSColor(calibratedRed: 0.00, green: 0.80, blue: 0.73, alpha: 1)
    NSColor(calibratedRed: 0.00, green: 0.98, blue: 0.88, alpha: 0.17).setFill()
    eyePath.fill()
    mint.setStroke()
    eyePath.lineWidth = max(2, 44 * scale)
    eyePath.stroke()

    let irisRect = NSRect(
        x: center.x - 124 * scale,
        y: center.y - 124 * scale,
        width: 248 * scale,
        height: 248 * scale
    )
    NSColor(calibratedRed: 0.00, green: 0.87, blue: 0.78, alpha: 1).setFill()
    NSBezierPath(ovalIn: irisRect).fill()

    let pupilRect = NSRect(
        x: center.x - 44 * scale,
        y: center.y - 44 * scale,
        width: 88 * scale,
        height: 88 * scale
    )
    NSColor(calibratedRed: 0.04, green: 0.07, blue: 0.08, alpha: 1).setFill()
    NSBezierPath(ovalIn: pupilRect).fill()
}

private func drawPauseBars(in rect: NSRect, scale: CGFloat) {
    let barWidth = 46 * scale
    let barHeight = 138 * scale
    let radius = 23 * scale
    let y = rect.midY - 320 * scale
    let firstX = rect.midX - 61 * scale
    let secondX = rect.midX + 15 * scale

    let shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadowColor.setFill()
    for x in [firstX, secondX] {
        NSBezierPath(
            roundedRect: NSRect(x: x + 5 * scale, y: y - 7 * scale, width: barWidth, height: barHeight),
            xRadius: radius,
            yRadius: radius
        ).fill()
    }

    NSColor.white.withAlphaComponent(0.92).setFill()
    for x in [firstX, secondX] {
        NSBezierPath(
            roundedRect: NSRect(x: x, y: y, width: barWidth, height: barHeight),
            xRadius: radius,
            yRadius: radius
        ).fill()
    }
}
