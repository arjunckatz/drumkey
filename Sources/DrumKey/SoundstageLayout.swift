import AppKit
import DrumKeyCore

struct SoundstageLayout {
    static let depth = NSPoint(x: -4, y: -5)
    static let keyOrder: [DrumKey] = [.j, .k, .j, .l, .d, .f, .d, .l, .f, .d, .f, .l, .k, .j, .k, .l]
    private static let diameter: CGFloat = 152 * 1.10
    let bounds: NSRect

    var scale: CGFloat {
        min(bounds.width / OverlayScale.baseSize.width, bounds.height / OverlayScale.baseSize.height)
    }

    var center: NSPoint {
        let extraHeight = max(0, bounds.height - 72 - 180 * scale)
        return NSPoint(x: bounds.midX, y: bounds.minY + 72 + extraHeight / 2 + Self.diameter * scale / 2)
    }

    /// Leave room for the bold radial glow and the fixed-size status labels.
    var maximumRadialRadius: CGFloat {
        let clearance = min(
            center.x - bounds.minX, bounds.maxX - center.x,
            center.y - bounds.minY - 66, bounds.maxY - center.y
        )
        return max(0, clearance - 5 * scale)
    }

    func ringRect(radius: CGFloat) -> NSRect {
        let scaledRadius = radius * scale
        return NSRect(x: center.x - scaledRadius, y: center.y - scaledRadius, width: scaledRadius * 2, height: scaledRadius * 2)
    }

    var artifacts: [GlassArtifact] {
        return (0..<16).map { index in
            let position = index % 4
            let key = Self.keyOrder[index]
            let angle = -7 * Double.pi / 8 + Double(index) * Double.pi / 8
            // Keep the mirrored projection, with accents on the cardinal axes:
            // D/F occupy the left semicircle and J/K occupy the right.
            let point = NSPoint(x: center.x - cos(angle) * 55 * scale, y: center.y + sin(angle) * 55 * scale)
            return GlassArtifact(key: key, center: point, variation: position == 3 ? 1 : position, scale: scale)
        }
    }

    var towerArtifacts: [GlassArtifact] {
        let keys: [DrumKey] = [.k, .k, .k, .k, .l, .f, .f, .f, .f, .d, .d, .d, .d, .l, .j, .j, .j, .j]
        return keys.enumerated().map { index, key in
            let angle = (10 + Double(index) * 20) * .pi / 180
            let point = NSPoint(x: center.x + sin(angle) * 62 * scale,
                                y: center.y + 17 * scale - cos(angle) * 40 * scale)
            return GlassArtifact(key: key, center: point, variation: index % 3, scale: scale)
        }
    }
}

struct GlassArtifact {
    let key: DrumKey
    let center: NSPoint
    let variation: Int
    let scale: CGFloat

    var isBass: Bool { key == .d || key == .f }
    var depth: NSPoint { NSPoint(x: SoundstageLayout.depth.x * scale, y: SoundstageLayout.depth.y * scale) }
    var baseHeight: CGFloat { (11 + CGFloat(variation) * 3) * scale }
    var width: CGFloat {
        if key == .l { return 19 * scale }
        let standardWidth = (10 + CGFloat(variation) * 1.5) * scale
        return isBass ? standardWidth * 1.35 : standardWidth
    }

    /// Center the complete projected object on the ring. The top face and the
    /// front face both contribute to its visible bounds.
    var baseRect: NSRect {
        return NSRect(
            x: center.x - width / 2 - depth.x / 2,
            y: center.y - baseHeight / 2 - depth.y / 2,
            width: width, height: baseHeight
        )
    }

    func frontRect(intensity: Double, reduceMotion: Bool, maximumExtension: CGFloat = 24) -> NSRect {
        let energy = reduceMotion ? 0 : max(0, min(1, intensity))
        let extensionHeight = energy * maximumExtension * scale
        var rect = baseRect
        rect.origin.y -= extensionHeight
        rect.size.height += extensionHeight
        return rect
    }
}
