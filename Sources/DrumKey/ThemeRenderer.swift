import AppKit
import DrumKeyCore

/// Original native drawings sharing the same key energy, scale and palette.
/// Project references and the visual vocabulary are recorded in THEMES.md.
@MainActor
struct ThemeRenderer {
    let layout: SoundstageLayout
    let levels: [DrumKey: Double]
    let palette: VisualizerPalette
    let reduceMotion: Bool

    private var scale: CGFloat { layout.scale }
    private var center: NSPoint { layout.center }
    private var radialLimit: CGFloat { scale > 0 ? layout.maximumRadialRadius / scale : 0 }
    private var linearKeys: [DrumKey] { EQKeyMap.linear }

    func draw(_ theme: VisualizerTheme) {
        switch theme {
        case .glassCircle: break
        case .pulseHalo: drawHalo()
        case .radialSpectrum: drawRadialSpectrum()
        case .linearEQ: drawLinearEQ()
        case .mirrorWave: drawMirrorWave()
        case .orbitDots: drawOrbitDots()
        case .ledMatrix: drawLEDMatrix()
        case .circleTowers: drawCircleTowers()
        case .razorBloom: drawRazorBloom()
        case .silkRibbons: drawSilkRibbons()
        case .hexArray: drawHexArray()
        }
        drawSpaceAccent(theme)
    }

    private func energy(_ key: DrumKey) -> Double { levels[key] ?? 0 }

    private func linearLevel(at fraction: Double) -> Double {
        let keys = linearKeys
        let location = fraction * Double(keys.count - 1)
        let lower = min(keys.count - 1, max(0, Int(location)))
        let upper = min(keys.count - 1, lower + 1)
        let blend = location - floor(location)
        let low = energy(keys[lower]) * (EQKeyMap.isBass(keys[lower]) ? 1 : 0.62)
        let high = energy(keys[upper]) * (EQKeyMap.isBass(keys[upper]) ? 1 : 0.62)
        return min(1, low * (1 - blend) + high * blend)
    }

    private func radialPoint(_ sample: RadialKeyMap.Sample, radius: CGFloat) -> NSPoint {
        NSPoint(x: center.x + sample.x * radius, y: center.y + sample.y * radius)
    }

    private func glowStroke(_ path: NSBezierPath, tint: NSColor, width: CGFloat, energy: Double, punch: Bool = false) {
        tint.withAlphaComponent(punch ? 0.10 + energy * 0.16 : 0.07 + energy * 0.08).setStroke()
        path.lineWidth = width * 3.5
        path.stroke()
        tint.withAlphaComponent(punch ? 0.44 + energy * 0.50 : 0.38 + energy * 0.48).setStroke()
        path.lineWidth = width
        path.stroke()
    }

    private func drawHalo() {
        let activity = levels.values.max() ?? 0
        let travel = max(0, min(36, radialLimit - 49))
        let points = RadialKeyMap.halo.map { sample in
            let response = sample.level(in: levels)
            let radius = (49 + (reduceMotion ? 0 : response * travel)) * scale
            return radialPoint(sample, radius: radius)
        }
        let outline = polygon(points)
        outline.lineJoinStyle = .miter
        outline.miterLimit = 3
        let band = NSBezierPath()
        band.append(outline)
        band.append(NSBezierPath(ovalIn: layout.ringRect(radius: 44)))
        band.windingRule = .evenOdd
        NSGraphicsContext.saveGraphicsState()
        band.addClip()
        NSGraphicsContext.current?.cgContext.setAlpha(0.16 + activity * 0.22)
        palette.radialGradient?.draw(from: NSPoint(x: center.x, y: center.y - 64 * scale),
                                     to: NSPoint(x: center.x, y: center.y + 64 * scale),
                                     options: [.drawsBeforeStartingLocation, .drawsAfterEndingLocation])
        NSGraphicsContext.restoreGraphicsState()
        NSColor.white.withAlphaComponent(0.10 + activity * 0.16).setStroke()
        outline.lineWidth = 8.4 * scale
        outline.stroke()
        // Composite the colored segments together before applying opacity so
        // their overlapping caps don't create bright dots along the rim.
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext.current?.cgContext
        context?.setAlpha(0.44 + activity * 0.50)
        context?.beginTransparencyLayer(auxiliaryInfo: nil)
        for index in points.indices {
            let segment = polyline([points[index], points[(index + 1) % points.count]])
            palette.haloColors[index].setStroke()
            segment.lineWidth = 2.4 * scale
            segment.lineCapStyle = .square
            segment.stroke()
        }
        context?.endTransparencyLayer()
        NSGraphicsContext.restoreGraphicsState()
        NSColor.white.withAlphaComponent(0.20).setStroke()
        outline.lineWidth = 0.55 * scale
        outline.stroke()
        let inner = NSBezierPath(ovalIn: layout.ringRect(radius: 44))
        palette.color(for: .space).withAlphaComponent(0.28 + activity * 0.25).setStroke()
        inner.lineWidth = 0.8 * scale
        inner.stroke()
    }

    private func drawRadialSpectrum() {
        let rim = NSBezierPath(ovalIn: layout.ringRect(radius: 38))
        NSColor.labelColor.withAlphaComponent(0.10).setStroke()
        rim.lineWidth = 0.7 * scale
        rim.stroke()
        let travel = max(0, min(41, radialLimit - 44))
        for (index, sample) in RadialKeyMap.spectrum.enumerated() {
            let value = sample.level(in: levels)
            let extent = (reduceMotion ? 7 : 4 + value * travel) * scale
            let root = radialPoint(sample, radius: 40 * scale)
            let shoulder = radialPoint(sample, radius: 40 * scale + max(0, extent - 5 * scale))
            let tip = radialPoint(sample, radius: 40 * scale + extent)
            let halfWidth = (1.15 + (reduceMotion ? 0 : value * 0.5)) * scale
            let tangent = NSPoint(x: -sample.y * halfWidth, y: sample.x * halfWidth)
            let stem = polygon([root + tangent, shoulder + tangent, tip, shoulder - tangent, root - tangent])
            drawCrystal(stem, tint: palette.radialColors[index], intensity: value)
        }
    }

    private func drawLinearEQ() {
        let width = 148 * scale
        let left = center.x - width / 2
        let baseline = center.y + 51 * scale
        for line in 0..<4 {
            let grid = NSBezierPath()
            grid.move(to: NSPoint(x: left, y: baseline - CGFloat(line) * 24 * scale))
            grid.line(to: NSPoint(x: left + width, y: baseline - CGFloat(line) * 24 * scale))
            NSColor.labelColor.withAlphaComponent(0.07).setStroke()
            grid.lineWidth = 0.5 * scale
            grid.stroke()
        }
        let spacing = width / CGFloat(linearKeys.count)
        for (index, key) in linearKeys.enumerated() {
            let value = energy(key)
            let peak = EQKeyMap.peakHeight(for: key)
            let height = (reduceMotion ? (EQKeyMap.isBass(key) ? 45 : 28) : 7 + value * (peak - 7)) * scale
            let rect = NSRect(x: left + CGFloat(index) * spacing + 1.3 * scale,
                              y: baseline - height, width: spacing - 2.6 * scale, height: height)
            let bar = NSBezierPath(roundedRect: rect, xRadius: 1.8 * scale, yRadius: 1.8 * scale)
            let tint = palette.color(for: key)
            NSGradient(starting: tint.withAlphaComponent(0.55 + value * 0.35),
                       ending: tint.withAlphaComponent(0.15 + value * 0.20))?.draw(in: bar, angle: 90)
            let cap = NSBezierPath()
            cap.move(to: NSPoint(x: rect.minX, y: rect.minY))
            cap.line(to: NSPoint(x: rect.maxX, y: rect.minY))
            tint.withAlphaComponent(0.40 + value * 0.5).setStroke()
            cap.lineWidth = 1.1 * scale
            cap.stroke()
        }
    }

    private func drawMirrorWave() {
        let width = 150 * scale
        let left = center.x - width / 2
        var upper: [NSPoint] = []
        var lower: [NSPoint] = []
        for index in 0...96 {
            let fraction = Double(index) / 96
            let response = linearLevel(at: fraction)
            let carrier = 0.45 + 0.55 * abs(sin(fraction * 14 * .pi))
            let height = (reduceMotion ? 10 : 2.5 + response * carrier * 40) * scale
            let x = left + fraction * width
            upper.append(NSPoint(x: x, y: center.y - height))
            lower.append(NSPoint(x: x, y: center.y + height))
        }
        let body = polygon(upper + lower.reversed())
        fillSpectrum(body, alpha: 0.20)
        let topLine = polyline(upper)
        let bottomLine = polyline(lower)
        glowStroke(topLine, tint: palette.color(for: .f), width: 1.4 * scale, energy: levels.values.max() ?? 0)
        glowStroke(bottomLine, tint: palette.color(for: .k), width: 1.4 * scale, energy: levels.values.max() ?? 0)
        let axis = polyline([NSPoint(x: left, y: center.y), NSPoint(x: left + width, y: center.y)])
        NSColor.labelColor.withAlphaComponent(0.12).setStroke()
        axis.lineWidth = 0.6 * scale
        axis.stroke()
    }

    private func drawOrbitDots() {
        for radius: CGFloat in [31, 49, 68] {
            let orbit = NSBezierPath(ovalIn: layout.ringRect(radius: radius))
            palette.color(for: .l).withAlphaComponent(0.13).setStroke()
            orbit.lineWidth = 0.65 * scale
            orbit.stroke()
        }
        let nodes = RadialKeyMap.orbits
        let points = nodes.map { sample -> (NSPoint, CGFloat, Double) in
            let value = sample.level(in: levels)
            let isBass = sample.primaryKey == .d || sample.primaryKey == .f
            let isAccent = sample.primaryKey == .l
            let diameter = (isBass ? 7.5 : (isAccent ? 4.5 : 6)) + (reduceMotion ? 0 : value * (isAccent ? 10 : 14))
            let travel = max(0, min(24, radialLimit - 55 - diameter * 0.7))
            let radius = (55 + (reduceMotion ? 0 : value * travel)) * scale
            let position = radialPoint(sample, radius: radius)
            return (position, diameter * scale, value)
        }
        for (index, sample) in nodes.enumerated() {
            let (position, diameter, value) = points[index]
            let next = points[(index + 1) % nodes.count].0
            let tint = palette.orbitColors[index]
            let link = polyline([position, next])
            tint.withAlphaComponent(0.06 + value * 0.18).setStroke()
            link.lineWidth = 0.55 * scale
            link.stroke()
            let stem = polyline([radialPoint(sample, radius: 55 * scale), position])
            tint.withAlphaComponent(0.28 + value * 0.42).setStroke()
            stem.lineWidth = 1.2 * scale
            stem.lineCapStyle = .round
            stem.stroke()
            let tangent = NSPoint(x: -sample.y * diameter / 2, y: sample.x * diameter / 2)
            let outward = NSPoint(x: sample.x * diameter * 0.7, y: sample.y * diameter * 0.7)
            let inward = NSPoint(x: sample.x * diameter * 0.45, y: sample.y * diameter * 0.45)
            let disc = polygon([position + outward, position + tangent, position - inward, position - tangent])
            tint.withAlphaComponent(0.12 + value * 0.24).setStroke()
            disc.lineWidth = 5 * scale
            disc.stroke()
            let highlight = tint.blended(withFraction: 0.65, of: .white) ?? tint
            NSGradient(starting: highlight.withAlphaComponent(0.65 + value * 0.3),
                       ending: tint.withAlphaComponent(0.4 + value * 0.4))?.draw(in: disc, angle: 100)
            NSColor.white.withAlphaComponent(0.65).setStroke()
            disc.lineWidth = 0.7 * scale
            disc.stroke()
        }
    }

    private func drawLEDMatrix() {
        let width = 148 * scale
        let left = center.x - width / 2
        let bottom = center.y + 44 * scale
        let spacing = width / CGFloat(EQKeyMap.led.count)
        for (column, key) in EQKeyMap.led.enumerated() {
            let value = energy(key)
            let rows = EQKeyMap.ledRows(for: key)
            let litRows = 1 + Int(value * Double(rows - 1))
            for row in 0..<rows {
                let cell = NSBezierPath(roundedRect: NSRect(
                    x: left + CGFloat(column) * spacing + 1.3 * scale,
                    y: bottom - CGFloat(row + 1) * 6 * scale,
                    width: spacing - 2.6 * scale, height: 4 * scale
                ), xRadius: 0.8 * scale, yRadius: 0.8 * scale)
                let lit = row < litRows
                let alpha = lit ? 0.45 + value * 0.45 : 0.055
                palette.ledColors[row].withAlphaComponent(reduceMotion ? 0.08 + value * 0.65 : alpha).setFill()
                cell.fill()
            }
        }
    }

    private func drawCircleTowers() {
        let floorCenter = NSPoint(x: center.x, y: center.y + 17 * scale)
        for radius: CGFloat in [34, 50, 67] {
            let floor = NSBezierPath(ovalIn: NSRect(x: floorCenter.x - radius * scale,
                y: floorCenter.y - radius * 0.64 * scale, width: radius * 2 * scale, height: radius * 1.28 * scale))
            palette.color(for: .l).withAlphaComponent(0.11).setStroke()
            floor.lineWidth = 0.65 * scale
            floor.stroke()
        }
        for artifact in layout.towerArtifacts.sorted(by: { $0.baseRect.maxY < $1.baseRect.maxY }) {
            let value = energy(artifact.key)
            let extensionHeight: CGFloat = artifact.isBass ? 36 : (artifact.key == .l ? 44 : 26)
            let rect = artifact.frontRect(intensity: value, reduceMotion: reduceMotion, maximumExtension: extensionHeight)
            let depth = artifact.depth
            let offset = NSPoint(x: depth.x, y: depth.y)
            let topLeft = NSPoint(x: rect.minX, y: rect.minY)
            let topRight = NSPoint(x: rect.maxX, y: rect.minY)
            let bottomLeft = NSPoint(x: rect.minX, y: rect.maxY)
            let front = NSBezierPath(roundedRect: rect, xRadius: 1.6 * scale, yRadius: 1.6 * scale)
            let top = polygon([topLeft, topLeft + offset, topRight + offset, topRight])
            let side = polygon([topLeft, topLeft + offset, bottomLeft + offset, bottomLeft])
            let tint = palette.color(for: artifact.key)
            let pale = tint.blended(withFraction: 0.52, of: .white) ?? tint
            tint.withAlphaComponent(0.10 + value * 0.12).setFill()
            NSBezierPath(ovalIn: NSRect(x: rect.minX - 2 * scale, y: rect.maxY - scale,
                                       width: rect.width + 4 * scale, height: 4 * scale)).fill()
            NSGradient(starting: tint.withAlphaComponent(0.37 + value * 0.25),
                       ending: tint.withAlphaComponent(0.15 + value * 0.20))?.draw(in: side, angle: 180)
            NSGradient(starting: pale.withAlphaComponent(0.64 + value * 0.24),
                       ending: tint.withAlphaComponent(0.29 + value * 0.36))?.draw(in: front, angle: 90)
            NSGradient(starting: NSColor.white.withAlphaComponent(0.82),
                       ending: pale.withAlphaComponent(0.65))?.draw(in: top, angle: 60)
            NSColor.white.withAlphaComponent(0.48 + value * 0.24).setStroke()
            for face in [front, side, top] {
                face.lineWidth = (artifact.isBass ? 0.95 : 0.65) * scale
                face.stroke()
            }
            let reflection = polyline([
                NSPoint(x: rect.maxX - 2.3 * scale, y: rect.minY + 3 * scale),
                NSPoint(x: rect.maxX - 2.3 * scale, y: rect.maxY - 2 * scale)
            ])
            NSColor.white.withAlphaComponent(0.40 + value * 0.35).setStroke()
            reflection.lineWidth = 1.1 * scale
            reflection.stroke()
        }
    }

    private func drawRazorBloom() {
        for (index, sample) in RadialKeyMap.blades.enumerated() {
            let value = sample.level(in: levels)
            let travel = max(0, min(45, radialLimit - 37))
            let tipRadius = (37 + (reduceMotion ? 0 : value * travel)) * scale
            let root = radialPoint(sample, radius: 29 * scale)
            let tip = radialPoint(sample, radius: tipRadius)
            let shoulder = radialPoint(sample, radius: (29 * scale + tipRadius) / 2)
            let tangent = NSPoint(x: -sample.y * 3.5 * scale, y: sample.x * 3.5 * scale)
            let blade = polygon([root + tangent, shoulder + tangent, tip, shoulder - tangent, root - tangent])
            drawCrystal(blade, tint: palette.bladeColors[index], intensity: value)
            let facet = polygon([root, root + tangent, tip])
            NSColor.white.withAlphaComponent(0.11 + value * 0.16).setFill()
            facet.fill()
        }
        let core = NSBezierPath(ovalIn: layout.ringRect(radius: 25))
        NSColor.labelColor.withAlphaComponent(0.12).setStroke()
        core.lineWidth = 0.6 * scale
        core.stroke()
    }

    private func drawSilkRibbons() {
        let keys: [DrumKey] = [.d, .f, .j, .k, .l]
        for (row, key) in keys.enumerated() {
            let value = energy(key)
            let baseline = center.y + (CGFloat(row) * 18 - 36) * scale
            let amplitude = (reduceMotion ? 3 : 2 + value * 12) * scale
            let thickness = (3 + (reduceMotion ? 0 : value * 3)) * scale
            var upper: [NSPoint] = []
            var lower: [NSPoint] = []
            for index in 0...64 {
                let fraction = Double(index) / 64
                let envelope = sin(fraction * .pi)
                let wave = sin(fraction * 2 * .pi + Double(row) * 0.8) * envelope * amplitude
                let x = center.x + (fraction - 0.5) * 148 * scale
                upper.append(NSPoint(x: x, y: baseline + wave - thickness))
                lower.append(NSPoint(x: x, y: baseline + wave + thickness))
            }
            let ribbon = polygon(upper + lower.reversed())
            let tint = palette.color(for: key)
            NSGradient(starting: tint.withAlphaComponent(0.17 + value * 0.28),
                       ending: tint.withAlphaComponent(0.42 + value * 0.42))?.draw(in: ribbon, angle: 0)
            glowStroke(polyline(upper), tint: tint, width: 0.9 * scale, energy: value)
            NSColor.white.withAlphaComponent(0.25 + value * 0.20).setStroke()
            let highlight = polyline(lower)
            highlight.lineWidth = 0.5 * scale
            highlight.stroke()
        }
    }

    private func drawHexArray() {
        for r in -2...2 {
            for q in -2...2 where abs(q + r) <= 2 {
                let distance = max(abs(q), abs(r), abs(q + r))
                let x = Double(q) + Double(r) / 2
                let key: DrumKey
                if distance == 0 || (q == 0 && abs(r) == 1) { key = .d }
                else if r == 0 { key = .f }
                else if abs(r) == 2 { key = .l }
                else { key = x < 0 ? .j : .k }
                let value = energy(key)
                let position = NSPoint(x: center.x + x * sqrt(3) * 16 * scale,
                                       y: center.y + Double(r) * 24 * scale)
                let radius = 15.2 * scale * (reduceMotion ? 0.86 : 0.84 + value * 0.16)
                let hex = polygon((0..<6).map { index in
                    let angle = Double(index) * .pi / 3
                    return NSPoint(x: position.x + sin(angle) * radius, y: position.y - cos(angle) * radius)
                })
                drawCrystal(hex, tint: palette.color(for: key), intensity: value)
                let facet = polygon([position,
                    NSPoint(x: position.x, y: position.y - radius),
                    NSPoint(x: position.x + sqrt(3) * radius / 2, y: position.y - radius / 2)])
                NSColor.white.withAlphaComponent(0.17 + value * 0.12).setFill()
                facet.fill()
            }
        }
    }

    private func drawCrystal(_ path: NSBezierPath, tint: NSColor, intensity: Double) {
        path.lineJoinStyle = .miter
        path.miterLimit = 2
        tint.withAlphaComponent(0.07 + intensity * 0.10).setStroke()
        path.lineWidth = 3 * scale
        path.stroke()
        let pale = tint.blended(withFraction: 0.50, of: .white) ?? tint
        NSGradient(starting: pale.withAlphaComponent(0.50 + intensity * 0.34),
                   ending: tint.withAlphaComponent(0.24 + intensity * 0.48))?.draw(in: path, angle: 100)
        tint.withAlphaComponent(0.45 + intensity * 0.40).setStroke()
        path.lineWidth = 0.65 * scale
        path.stroke()
    }

    private func drawSpaceAccent(_ theme: VisualizerTheme) {
        let value = energy(.space)
        guard value > 0 else { return }
        let path: NSBezierPath
        if theme == .circleTowers {
            path = NSBezierPath(ovalIn: NSRect(x: center.x - 50 * scale, y: center.y - 15 * scale,
                                             width: 100 * scale, height: 64 * scale))
        } else if theme.usesRadialKeyMap {
            path = NSBezierPath(ovalIn: layout.ringRect(radius: theme == .razorBloom ? 25 : 34))
        } else {
            path = polyline([NSPoint(x: center.x - 72 * scale, y: center.y + 54 * scale),
                             NSPoint(x: center.x + 72 * scale, y: center.y + 54 * scale)])
        }
        palette.color(for: .space).withAlphaComponent(0.6 * value).setStroke()
        path.lineWidth = 1.3 * scale
        path.stroke()
    }

    private func fillSpectrum(_ path: NSBezierPath, alpha: Double) {
        NSGraphicsContext.saveGraphicsState()
        path.addClip()
        NSGraphicsContext.current?.cgContext.setAlpha(alpha)
        palette.spectrum?.draw(from: NSPoint(x: center.x - 75 * scale, y: center.y + 75 * scale),
                               to: NSPoint(x: center.x + 75 * scale, y: center.y - 75 * scale), options: [])
        NSGraphicsContext.restoreGraphicsState()
    }

    private func polyline(_ points: [NSPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        if let first = points.first {
            path.move(to: first)
            for point in points.dropFirst() { path.line(to: point) }
        }
        path.lineJoinStyle = .round
        return path
    }

    private func polygon(_ points: [NSPoint]) -> NSBezierPath {
        let path = polyline(points)
        path.close()
        return path
    }

    private func smoothClosedPath(_ points: [NSPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        guard let first = points.first, points.count >= 4 else { return path }
        path.move(to: first)
        for index in points.indices {
            let p0 = points[(index + points.count - 1) % points.count]
            let p1 = points[index]
            let p2 = points[(index + 1) % points.count]
            let p3 = points[(index + 2) % points.count]
            path.curve(to: p2,
                       controlPoint1: NSPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                       controlPoint2: NSPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6))
        }
        path.close()
        return path
    }

    private func smoothSegment(_ points: [NSPoint], at index: Int) -> NSBezierPath {
        let p0 = points[(index + points.count - 1) % points.count]
        let p1 = points[index]
        let p2 = points[(index + 1) % points.count]
        let p3 = points[(index + 2) % points.count]
        let path = NSBezierPath()
        path.move(to: p1)
        path.curve(to: p2,
                   controlPoint1: NSPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                   controlPoint2: NSPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6))
        return path
    }
}

private extension NSPoint {
    static func + (lhs: NSPoint, rhs: NSPoint) -> NSPoint { NSPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func - (lhs: NSPoint, rhs: NSPoint) -> NSPoint { NSPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
}
