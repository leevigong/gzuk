#!/usr/bin/env swift
//
// Regenerates the GZUK macOS app icon set.
// Renders the "그려 / 적어" wordmark with 그려 in accent red and 적어 in
// near-black, matching the in-app brand. Produces all sizes Xcode expects
// in the AppIcon asset catalog.
//
// Usage: swift scripts/make_app_icon.swift
//

import AppKit
import CoreText

let projectRoot = "~/dev/gzuk"
let fontPath    = "\(projectRoot)/GZUK/Resources/Fonts/GowunDodum-Regular.ttf"
let outputDir   = "\(projectRoot)/GZUK/Assets.xcassets/AppIcon.appiconset"

// Register Gowun Dodum so the script can use it via PostScript name.
CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: fontPath) as CFURL,
                                 .process, nil)

let accentRed = CGColor(red: 1.0,  green: 0.18, blue: 0.18, alpha: 1.0)
let inkColor  = CGColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.0)
let bgColor   = CGColor(red: 1.0,  green: 1.0,  blue: 1.0,  alpha: 1.0)

// (output filename, pixel dimensions)
let outputs: [(String, Int)] = [
    ("icon_16x16.png",       16),
    ("icon_16x16@2x.png",    32),
    ("icon_32x32.png",       32),
    ("icon_32x32@2x.png",    64),
    ("icon_128x128.png",    128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png",    256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png",    512),
    ("icon_512x512@2x.png", 1024),
]

func renderIcon(size: Int) -> NSBitmapImageRep {
    let s = CGFloat(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext

    // White rounded background — macOS app icon corner radius is ~22.4%
    // of the icon side per Apple's Human Interface Guidelines.
    let inset: CGFloat = s * 0.06   // small inset so the rounded square
                                    // doesn't kiss the bezel
    let bgRect = CGRect(x: inset, y: inset, width: s - inset*2, height: s - inset*2)
    let radius = bgRect.width * 0.22
    let path = CGPath(roundedRect: bgRect,
                      cornerWidth: radius, cornerHeight: radius,
                      transform: nil)
    cg.addPath(path); cg.setFillColor(bgColor); cg.fillPath()

    // Two stacked Korean lines: "그려" (red) on top, "적어" (ink) below.
    // Both use Gowun Dodum at the same font size.
    let fontSize = s * 0.30
    let font = NSFont(name: "GowunDodum-Regular", size: fontSize)
            ?? NSFont(name: "AppleSDGothicNeo-Regular", size: fontSize)
            ?? NSFont.systemFont(ofSize: fontSize)

    let topAttrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(cgColor: accentRed)!,
    ]
    let bottomAttrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(cgColor: inkColor)!,
    ]

    let topStr    = NSAttributedString(string: "그려", attributes: topAttrs)
    let bottomStr = NSAttributedString(string: "적어", attributes: bottomAttrs)

    // CoreText so we can position by the actual ink bounding box rather
    // than typographic ascent/descent (which include slack above and below
    // the visible glyphs and throw off optical centering).
    let topLine    = CTLineCreateWithAttributedString(topStr)
    let bottomLine = CTLineCreateWithAttributedString(bottomStr)
    let topImg     = CTLineGetImageBounds(topLine,    cg)
    let bottomImg  = CTLineGetImageBounds(bottomLine, cg)

    let lineGap: CGFloat = font.capHeight * 0.18  // small breathing space
    let stackHeight = topImg.height + bottomImg.height + lineGap

    // In Cartesian coords (y up): top of stack = bgRect.midY + stackHeight/2.
    let stackTopY = bgRect.midY + stackHeight / 2
    // For each line, ink top = baseline + img.maxY ⇒ baseline = top - img.maxY.
    let topBaselineY    = stackTopY - topImg.maxY
    let bottomBaselineY = stackTopY - topImg.height - lineGap - bottomImg.maxY

    // Horizontal: ink box is offset by img.minX from text origin, so subtract
    // that to make ink width sit centered on bgRect.midX.
    let topX    = bgRect.midX - topImg.width    / 2 - topImg.minX
    let bottomX = bgRect.midX - bottomImg.width / 2 - bottomImg.minX

    // Fake semi-bold "그려": draw with .fillStroke mode + stroke in the same
    // red, so each glyph picks up an outline that visually thickens it.
    // 0.012 of icon size gives a clearly visible semi-bold (0.007 was too
    // subtle at small render sizes like the App Store / Spotlight result).
    let strokeW = s * 0.012
    cg.setTextDrawingMode(.fillStroke)
    cg.setStrokeColor(accentRed)
    cg.setLineWidth(strokeW)
    cg.setLineJoin(.round)
    cg.textPosition = CGPoint(x: topX, y: topBaselineY)
    CTLineDraw(topLine, cg)

    // Reset for "적어" — fill only, no stroke (regular weight).
    cg.setTextDrawingMode(.fill)
    cg.textPosition = CGPoint(x: bottomX, y: bottomBaselineY)
    CTLineDraw(bottomLine, cg)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

for (filename, size) in outputs {
    let rep = renderIcon(size: size)
    guard let png = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write(Data("✗ failed to encode \(filename)\n".utf8))
        exit(1)
    }
    let url = URL(fileURLWithPath: "\(outputDir)/\(filename)")
    try! png.write(to: url)
    print("✓ \(filename) (\(size)px)")
}

print("\nDone. Run: xcodebuild -project GZUK.xcodeproj -scheme GZUK build")
