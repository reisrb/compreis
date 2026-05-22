#!/usr/bin/env swift
import AppKit
import Foundation

let iconDir = "Compreis/Assets.xcassets/AppIcon.appiconset"

func createIcon(dark: Bool) -> Data? {
    let size = CGFloat(1024)

    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size), pixelsHigh: Int(size),
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Background
    let bg = dark
        ? NSColor.black
        : NSColor(red: 0.204, green: 0.780, blue: 0.349, alpha: 1)
    bg.setFill()
    NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
                 xRadius: 230, yRadius: 230).fill()

    // Cart — large, centered, slightly low
    let cartConf = NSImage.SymbolConfiguration(pointSize: 480, weight: .medium)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    if let cart = NSImage(systemSymbolName: "cart.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(cartConf) {
        let s = cart.size
        cart.draw(in: NSRect(x: (size - s.width) / 2, y: size * 0.04,
                             width: s.width, height: s.height))
    }

    // Guitar — rotated 20°, upper-right, rock vibe
    let guitarConf = NSImage.SymbolConfiguration(pointSize: 250, weight: .medium)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    if let guitar = NSImage(systemSymbolName: "guitars", accessibilityDescription: nil)?
        .withSymbolConfiguration(guitarConf) {
        let s = guitar.size
        NSGraphicsContext.saveGraphicsState()
        let t = NSAffineTransform()
        t.translateX(by: size * 0.63, yBy: size * 0.60)
        t.rotate(byDegrees: 20)
        t.translateX(by: -s.width / 2, yBy: -s.height / 2)
        t.concat()
        guitar.draw(in: NSRect(x: 0, y: 0, width: s.width, height: s.height))
        NSGraphicsContext.restoreGraphicsState()
    }

    // Stars for rock effect
    let starConf = NSImage.SymbolConfiguration(pointSize: 70, weight: .bold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    let starPositions: [(CGFloat, CGFloat)] = [
        (size * 0.18, size * 0.72),
        (size * 0.82, size * 0.20),
        (size * 0.12, size * 0.52),
    ]
    if let star = NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(starConf) {
        for (px, py) in starPositions {
            let s = star.size
            star.draw(in: NSRect(x: px - s.width/2, y: py - s.height/2,
                                 width: s.width, height: s.height))
        }
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

let fm = FileManager.default

if let data = createIcon(dark: false) {
    let path = "\(iconDir)/AppIcon-Light.png"
    fm.createFile(atPath: path, contents: data)
    print("✓ \(path)")
} else {
    print("✗ light icon failed")
}

if let data = createIcon(dark: true) {
    let path = "\(iconDir)/AppIcon-Dark.png"
    fm.createFile(atPath: path, contents: data)
    print("✓ \(path)")
} else {
    print("✗ dark icon failed")
}
