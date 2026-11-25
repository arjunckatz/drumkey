import AppKit
import DrumKeyCore

struct SoundstageLayout {
    static let depth = NSPoint(x: -4, y: -5)
    private static let diameter: CGFloat = 152 * 1.10
    let bounds: NSRect

    var center: NSPoint {
        NSPoint(x: bounds.midX, y: 72 + Self.diameter / 2)
    }

    func ringRect(radius: CGFloat) -> NSRect {
        NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }

    var artifacts: [GlassArtifact] {
        let regions: [DrumKey] = [.j, .d, .f, .k]
        return (0..<16).map { index in
            let position = index % 4
            let key = position == 3 ? DrumKey.l : regions[index / 4]
            let angle = -7 * Double.pi / 8 + Double(index) * Double.pi / 8
            // Keep the mirrored projection, with accents on the cardinal axes:
            // D/F occupy the left semicircle and J/K occupy the right.
            let point = NSPoint(x: center.x - cos(angle) * 55, y: center.y + sin(angle) * 55)
            return GlassArtifact(key: key, center: point, variation: position == 3 ? 1 : position)
        }
    }
}

struct GlassArtifact {
    let key: DrumKey
    let center: NSPoint
    let variation: Int

    var isBass: Bool { key == .d || key == .f }
    var baseHeight: CGFloat { 13 + CGFloat(variation) * 4 }
    var width: CGFloat {
        if key == .l { return 7.5 }
        let standardWidth = 10 + CGFloat(variation) * 1.5
        return isBass ? standardWidth * 1.35 : standardWidth
    }

    /// Center the complete projected object on the ring. The top face and the
    /// front face both contribute to its visible bounds.
    var baseRect: NSRect {
        let depth = SoundstageLayout.depth
        return NSRect(
            x: center.x - width / 2 - depth.x / 2,
            y: center.y - baseHeight / 2 - depth.y / 2,
            width: width, height: baseHeight
        )
    }

    var footprint: NSPoint {
        NSPoint(x: center.x, y: center.y + baseHeight / 2)
    }

    func frontRect(intensity: Double, reduceMotion: Bool) -> NSRect {
        let attack = reduceMotion ? 0 : pow(max(0, min(1, intensity)), 1.7)
        let travel = attack * 12
        let extensionHeight = attack * 7
        let extensionWidth = isBass ? width * attack * 0.20 : 0
        var rect = baseRect
        rect.origin.x -= extensionWidth / 2
        rect.size.width += extensionWidth
        rect.origin.y -= travel + extensionHeight
        rect.size.height += extensionHeight
        return rect
    }
}
