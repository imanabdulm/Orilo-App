import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root.appending(path: "Config/AppIcon.iconset", directoryHint: .isDirectory)
let menuBarIcon = root.appending(path: "Config/MenuBarIconTemplate.png")

try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func drawFlowerMark(
    in context: CGContext,
    center: CGPoint,
    markSize: CGFloat,
    fillColor: NSColor,
    centerCutoutColor: NSColor? = nil,
    clearCenterCutout: Bool = false
) {
    let petalWidth = markSize * 0.30
    let petalHeight = markSize * 0.50
    let petalOffset = markSize * 0.24

    context.saveGState()
    context.translateBy(x: center.x, y: center.y)
    fillColor.setFill()

    for index in 0..<6 {
        context.saveGState()
        context.rotate(by: CGFloat(index) * (.pi / 3))
        let petalRect = CGRect(
            x: -petalWidth / 2,
            y: petalOffset - petalHeight / 2,
            width: petalWidth,
            height: petalHeight
        )
        let petal = CGPath(
            roundedRect: petalRect,
            cornerWidth: petalWidth / 2,
            cornerHeight: petalWidth / 2,
            transform: nil
        )
        context.addPath(petal)
        context.fillPath()
        context.restoreGState()
    }

    context.addEllipse(in: CGRect(
        x: -markSize * 0.14,
        y: -markSize * 0.14,
        width: markSize * 0.28,
        height: markSize * 0.28
    ))
    context.fillPath()

    let cutoutRect = CGRect(
        x: -markSize * 0.06,
        y: -markSize * 0.06,
        width: markSize * 0.12,
        height: markSize * 0.12
    )

    if clearCenterCutout {
        context.saveGState()
        context.setBlendMode(.clear)
        context.addEllipse(in: cutoutRect)
        context.fillPath()
        context.restoreGState()
    } else if let centerCutoutColor {
        centerCutoutColor.setFill()
        context.addEllipse(in: cutoutRect)
        context.fillPath()
    }

    context.restoreGState()
}

func drawAppFlowerMark(in context: CGContext, center: CGPoint, markSize: CGFloat) {
    let petalWidth = markSize * 0.30
    let petalHeight = markSize * 0.50
    let petalOffset = markSize * 0.24

    context.saveGState()
    context.translateBy(x: center.x, y: center.y)

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -markSize * 0.035),
        blur: markSize * 0.07,
        color: NSColor.black.withAlphaComponent(0.18).cgColor
    )
    NSColor(calibratedRed: 0.73, green: 0.68, blue: 0.90, alpha: 0.22).setFill()
    for index in 0..<6 {
        context.saveGState()
        context.rotate(by: CGFloat(index) * (.pi / 3))
        let petalRect = CGRect(
            x: -petalWidth / 2,
            y: petalOffset - petalHeight / 2,
            width: petalWidth,
            height: petalHeight
        )
        context.addPath(CGPath(roundedRect: petalRect, cornerWidth: petalWidth / 2, cornerHeight: petalWidth / 2, transform: nil))
        context.fillPath()
        context.restoreGState()
    }
    context.restoreGState()

    guard let petalGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor(calibratedRed: 1.0, green: 0.99, blue: 1.0, alpha: 0.74).cgColor,
            NSColor(calibratedRed: 0.92, green: 0.90, blue: 1.0, alpha: 0.58).cgColor,
            NSColor(calibratedRed: 0.78, green: 0.72, blue: 0.96, alpha: 0.42).cgColor
        ] as CFArray,
        locations: [0.0, 0.56, 1.0]
    ) else {
        context.restoreGState()
        return
    }

    for index in 0..<6 {
        context.saveGState()
        context.rotate(by: CGFloat(index) * (.pi / 3))
        let petalRect = CGRect(
            x: -petalWidth / 2,
            y: petalOffset - petalHeight / 2,
            width: petalWidth,
            height: petalHeight
        )
        context.addPath(CGPath(roundedRect: petalRect, cornerWidth: petalWidth / 2, cornerHeight: petalWidth / 2, transform: nil))
        context.clip()
        context.drawLinearGradient(
            petalGradient,
            start: CGPoint(x: 0, y: petalRect.maxY),
            end: CGPoint(x: 0, y: petalRect.minY),
            options: []
        )

        NSColor.white.withAlphaComponent(0.46).setStroke()
        context.setLineWidth(max(1, markSize * 0.012))
        context.addPath(CGPath(
            roundedRect: petalRect.insetBy(dx: petalWidth * 0.08, dy: petalWidth * 0.08),
            cornerWidth: petalWidth / 2,
            cornerHeight: petalWidth / 2,
            transform: nil
        ))
        context.strokePath()
        context.restoreGState()
    }

    let centerDiscRect = CGRect(
        x: -markSize * 0.145,
        y: -markSize * 0.145,
        width: markSize * 0.29,
        height: markSize * 0.29
    )
    NSColor(calibratedRed: 0.98, green: 0.96, blue: 1.0, alpha: 0.70).setFill()
    context.addEllipse(in: centerDiscRect)
    context.fillPath()

    NSColor.white.withAlphaComponent(0.52).setStroke()
    context.setLineWidth(max(1, markSize * 0.01))
    context.addEllipse(in: centerDiscRect.insetBy(dx: markSize * 0.015, dy: markSize * 0.015))
    context.strokePath()

    guard let dotGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor(calibratedRed: 0.12, green: 0.36, blue: 0.96, alpha: 0.94).cgColor,
            NSColor(calibratedRed: 0.03, green: 0.20, blue: 0.68, alpha: 0.96).cgColor
        ] as CFArray,
        locations: [0.0, 1.0]
    ) else {
        context.restoreGState()
        return
    }

    let dotRect = CGRect(
        x: -markSize * 0.052,
        y: -markSize * 0.052,
        width: markSize * 0.104,
        height: markSize * 0.104
    )
    context.saveGState()
    context.addEllipse(in: dotRect)
    context.clip()
    context.drawLinearGradient(
        dotGradient,
        start: CGPoint(x: dotRect.minX, y: dotRect.maxY),
        end: CGPoint(x: dotRect.maxX, y: dotRect.minY),
        options: []
    )
    context.restoreGState()

    context.restoreGState()
}

func drawIcon(size: CGFloat) -> Data {
    let pixelSize = Int(size)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Failed to create bitmap for \(size)")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    let radius = size * 0.25
    let baseRect = rect.insetBy(dx: size * 0.07, dy: size * 0.07)
    let basePath = NSBezierPath(roundedRect: baseRect, xRadius: radius, yRadius: radius)

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.02, green: 0.16, blue: 0.58, alpha: 1),
        NSColor(calibratedRed: 0.08, green: 0.34, blue: 0.88, alpha: 1),
        NSColor(calibratedRed: 0.30, green: 0.70, blue: 1.0, alpha: 1)
    ])!
    gradient.draw(in: basePath, angle: -36)

    NSColor.white.withAlphaComponent(0.18).setStroke()
    basePath.lineWidth = max(1, size * 0.01)
    basePath.stroke()

    if let context = NSGraphicsContext.current?.cgContext {
        drawAppFlowerMark(
            in: context,
            center: CGPoint(x: rect.midX, y: rect.midY),
            markSize: size * 0.55
        )
    }

    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Failed to encode PNG for \(size)")
    }

    return png
}

func drawMenuBarTemplateIcon(size: CGFloat) -> Data {
    let pixelSize = Int(size)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Failed to create menu bar bitmap")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    if let context = NSGraphicsContext.current?.cgContext {
        drawFlowerMark(
            in: context,
            center: CGPoint(x: rect.midX, y: rect.midY),
            markSize: size * 0.92,
            fillColor: .black,
            clearCenterCutout: true
        )
    }

    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Failed to encode menu bar icon")
    }

    return png
}

for (name, size) in sizes {
    let png = drawIcon(size: size)
    try png.write(to: iconset.appending(path: name), options: .atomic)
}

try drawMenuBarTemplateIcon(size: 48).write(to: menuBarIcon, options: .atomic)
