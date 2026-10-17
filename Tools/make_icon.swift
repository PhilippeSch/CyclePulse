// Generates the app icon at 1024×1024 in the three appearances iOS asks for.
//
//   swift Tools/make_icon.swift light  out.png   full colour on warm birch
//   swift Tools/make_icon.swift dark   out.png   same artwork, transparent ground
//   swift Tools/make_icon.swift tinted out.png   greyscale, transparent ground
//
// watchOS and the iOS light appearance use `light`. The dark and tinted
// variants deliberately omit the background: iOS composites its own behind
// them, and a baked-in background is what makes a tinted icon look wrong.
//
// The ground is warm birch rather than the dark slate it used to be. watchOS
// masks the icon into a circle and draws it on a black home screen, and a
// near-black ground made it read as loose artwork floating in the void rather
// than as a circle — which is what App Review rejected under guideline 4. The
// iPhone uses the same light ground so both icons are one icon.
//
// The artwork is a round ring around a heart: rounds and rest, and the pulse
// through them.

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum Appearance: String {
    case light, dark, tinted

    var drawsBackground: Bool { self == .light }
    var isGreyscale: Bool { self == .tinted }
    /// True when the artwork sits on the light ground and has to be darkened
    /// rather than lifted to keep its contrast. The dark and tinted variants
    /// are composited onto a dark ground by iOS, so they are not.
    var isLightGround: Bool { self == .light }
}

let arguments = CommandLine.arguments
guard arguments.count >= 3, let appearance = Appearance(rawValue: arguments[1]) else {
    FileHandle.standardError.write(Data("usage: make_icon.swift <light|dark|tinted> <output.png>\n".utf8))
    exit(1)
}
let outputPath = arguments[2]

let size = 1024
let cs = CGColorSpaceCreateDeviceRGB()

guard let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("no ctx") }

/// Colours collapse to their luminance in the tinted appearance, so the
/// artwork still reads once iOS replaces the hue with the user's tint.
func rgb(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> CGColor {
    if appearance.isGreyscale {
        let luma = (0.2126 * CGFloat(r) + 0.7152 * CGFloat(g) + 0.0722 * CGFloat(b)) / 255
        return CGColor(colorSpace: cs, components: [luma, luma, luma, a])!
    }
    return CGColor(colorSpace: cs, components: [CGFloat(r)/255, CGFloat(g)/255, CGFloat(b)/255, a])!
}

let W = CGFloat(size)

// Work in top-left origin coordinates, like the layout was designed.
ctx.translateBy(x: 0, y: W)
ctx.scaleBy(x: 1, y: -1)

// ---------- background ----------
// Warm birch, light enough that watchOS's circular mask stays visible against
// the black home screen.
if appearance.drawsBackground {
    ctx.saveGState()
    let bgColors = [rgb(255, 243, 223), rgb(246, 222, 186), rgb(232, 197, 145)] as CFArray
    let bg = CGGradient(colorsSpace: cs, colors: bgColors, locations: [0, 0.55, 1])!
    ctx.drawLinearGradient(
        bg,
        start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: W),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
    ctx.restoreGState()
}

// ---------- round ring ----------
// One lap of a round: a long orange arc for the round itself and a short teal
// one for the rest, in the app's two phase colours. Thick strokes with round
// caps, so the silhouette survives being scaled down to a watch home screen.
let centre = CGPoint(x: W*0.5, y: W*0.5)
let ringRadius = W*0.315
let ringWidth = W*0.088

// The bright end of each colour is what a dark ground needs and a light one
// cannot carry, so `light` gets a deeper pair, and the dark and tinted
// variants — which iOS composites onto its own dark ground — the bright one.
let roundColour = appearance.isLightGround ? rgb(226, 92, 24) : rgb(255, 146, 54)
let restColour = appearance.isLightGround ? rgb(22, 134, 140) : rgb(64, 200, 196)
let trackColour = appearance.isLightGround ? rgb(120, 80, 40, 0.14) : rgb(255, 255, 255, 0.14)

func arc(from start: CGFloat, to end: CGFloat, colour: CGColor) {
    // Angles in degrees, clockwise from twelve o'clock.
    let p = CGMutablePath()
    p.addArc(
        center: centre, radius: ringRadius,
        startAngle: (start - 90) * .pi / 180, endAngle: (end - 90) * .pi / 180,
        clockwise: false
    )
    ctx.saveGState()
    ctx.setLineWidth(ringWidth)
    ctx.setLineCap(.round)
    ctx.setStrokeColor(colour)
    ctx.addPath(p)
    ctx.strokePath()
    ctx.restoreGState()
}

arc(from: 0, to: 360, colour: trackColour)
arc(from: 8, to: 244, colour: roundColour)
arc(from: 272, to: 334, colour: restColour)

// ---------- heart ----------
// The pulse the app tracks through every round.
func heartPath(centre c: CGPoint, width w: CGFloat) -> CGPath {
    let h = w * 0.92
    let p = CGMutablePath()
    p.move(to: CGPoint(x: c.x, y: c.y + h*0.46))
    p.addCurve(
        to: CGPoint(x: c.x - w*0.5, y: c.y - h*0.12),
        control1: CGPoint(x: c.x - w*0.16, y: c.y + h*0.30),
        control2: CGPoint(x: c.x - w*0.5, y: c.y + h*0.14)
    )
    p.addCurve(
        to: CGPoint(x: c.x, y: c.y - h*0.26),
        control1: CGPoint(x: c.x - w*0.5, y: c.y - h*0.50),
        control2: CGPoint(x: c.x - w*0.06, y: c.y - h*0.56)
    )
    p.addCurve(
        to: CGPoint(x: c.x + w*0.5, y: c.y - h*0.12),
        control1: CGPoint(x: c.x + w*0.06, y: c.y - h*0.56),
        control2: CGPoint(x: c.x + w*0.5, y: c.y - h*0.50)
    )
    p.addCurve(
        to: CGPoint(x: c.x, y: c.y + h*0.46),
        control1: CGPoint(x: c.x + w*0.5, y: c.y + h*0.14),
        control2: CGPoint(x: c.x + w*0.16, y: c.y + h*0.30)
    )
    p.closeSubpath()
    return p
}

let heartWidth = W*0.30
let heartCentre = CGPoint(x: W*0.5, y: W*0.515)
ctx.saveGState()
ctx.addPath(heartPath(centre: heartCentre, width: heartWidth))
ctx.clip()
let heartColours = appearance.isLightGround
    ? [rgb(178, 28, 34), rgb(232, 60, 56)]
    : [rgb(236, 64, 60), rgb(255, 118, 104)]
let heartG = CGGradient(colorsSpace: cs, colors: heartColours as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(
    heartG,
    start: CGPoint(x: 0, y: heartCentre.y + heartWidth*0.45),
    end: CGPoint(x: 0, y: heartCentre.y - heartWidth*0.45),
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
)
ctx.restoreGState()

guard let image = ctx.makeImage() else { fatalError("no image") }
let out = URL(fileURLWithPath: outputPath)
guard let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("no dest")
}
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(appearance.rawValue) -> \(out.path)")
