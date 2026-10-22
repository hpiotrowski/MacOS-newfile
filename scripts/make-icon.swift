#!/usr/bin/env swift
//
// Renders the app icon (macOS squircle with an SF Symbol) and writes
// Resources/AppIcon.icns. Run from the repository root:
//
//     swift scripts/make-icon.swift
//
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent("build/AppIcon.iconset")
let output = root.appendingPathComponent("Resources/AppIcon.icns")

try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func renderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    guard let context = NSGraphicsContext.current?.cgContext else { return image }

    let scale = size / 1024.0
    let inset = 100.0 * scale
    let rect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = 190.0 * scale

    // Squircle background with a soft vertical gradient.
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    context.saveGState()
    context.addPath(path)
    context.clip()

    let colors = [
        NSColor(calibratedWhite: 0.99, alpha: 1.0).cgColor,
        NSColor(calibratedWhite: 0.88, alpha: 1.0).cgColor
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: colors,
                                 locations: [0.0, 1.0]) {
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: size),
            end: CGPoint(x: 0, y: 0),
            options: []
        )
    }
    context.restoreGState()

    // Hairline border.
    context.saveGState()
    context.addPath(path)
    context.setStrokeColor(NSColor(calibratedWhite: 0.0, alpha: 0.08).cgColor)
    context.setLineWidth(2.0 * scale)
    context.strokePath()
    context.restoreGState()

    // Symbol.
    let blue = NSColor(calibratedRed: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
    let config = NSImage.SymbolConfiguration(pointSize: 430.0 * scale, weight: .regular)
        .applying(NSImage.SymbolConfiguration(paletteColors: [blue, blue]))

    if let symbol = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let symbolSize = symbol.size
        let symbolRect = CGRect(
            x: (size - symbolSize.width) / 2,
            y: (size - symbolSize.height) / 2,
            width: symbolSize.width,
            height: symbolSize.height
        )
        symbol.draw(in: symbolRect)
    }

    return image
}

let sizes: [(String, CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]

for (name, size) in sizes {
    let image = renderIcon(size: size)
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to render \(name)")
    }
    try png.write(to: iconset.appendingPathComponent("\(name).png"))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus != 0 {
    fatalError("iconutil failed with status \(process.terminationStatus)")
}

print("Wrote \(output.path)")
