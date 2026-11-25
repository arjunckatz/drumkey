import AppKit
import DrumKeyCore

@MainActor
final class OverlayView: NSView {
    static let preferredSize = NSSize(width: 192, height: 252)
    var onDragEnd: (() -> Void)?

    private var snapshot: RhythmSnapshot = .empty
    private var status: CaptureStatus = .permissionRequired
    private var pulseStartedAt: [DrumKey: TimeInterval] = [:]
    private var bassChordFlash = BassChordFlash()
    private var backgroundEQ = BackgroundEQ()
    private var eqOpacity = 0.08
    private let eqGradient = NSGradient(colorsAndLocations:
        (NSColor.systemGreen, 0), (.systemGreen, 0.55),
        (.systemYellow, 0.72), (.systemOrange, 0.84), (.systemRed, 0.94), (.systemRed, 1)
    )
    private var animationTimer: Timer?
    private let pulseDuration: TimeInterval = 0.36
    private let meterLabel = NSTextField(labelWithString: "≈4/4")
    private let tempoLabel = NSTextField(labelWithString: "Allow input")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        meterLabel.font = .monospacedSystemFont(ofSize: 22, weight: .medium)
        meterLabel.textColor = .labelColor
        meterLabel.alignment = .center
        meterLabel.frame = NSRect(x: 12, y: 13, width: 168, height: 29)
        tempoLabel.font = .systemFont(ofSize: 11, weight: .medium)
        tempoLabel.textColor = .secondaryLabelColor
        tempoLabel.alignment = .center
        tempoLabel.frame = NSRect(x: 12, y: 45, width: 168, height: 17)
        addSubview(meterLabel)
        addSubview(tempoLabel)
        meterLabel.setAccessibilityElement(false)
        tempoLabel.setAccessibilityElement(false)
        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
        updateAccessibility()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override var isFlipped: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard super.hitTest(point) != nil else { return nil }
        return self
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .openHand)
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        NSCursor.closedHand.push()
        defer { NSCursor.pop() }
        window.performDrag(with: event)
        onDragEnd?()
    }

    private var stage: SoundstageLayout { SoundstageLayout(bounds: bounds) }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawBackgroundEQ()
        drawSoundstage()
        drawBassChordBorder()
    }

    func register(hit: DrumHit, snapshot: RhythmSnapshot) {
        self.snapshot = snapshot
        let now = ProcessInfo.processInfo.systemUptime
        pulseStartedAt[hit.key] = now
        bassChordFlash.register(hit, deliveredAt: now)
        backgroundEQ.register(key: hit.key, at: now)
        updateStatusLabels()
        updateAccessibility()
        needsDisplay = true
        startAnimationTimer()
    }

    func setEQTransparency(_ value: Double) {
        let transparency = value.isFinite ? min(1, max(0, value)) : 0.92
        eqOpacity = 1 - transparency
        needsDisplay = true
        if eqOpacity > 0, backgroundEQ.isAnimating(at: ProcessInfo.processInfo.systemUptime) {
            startAnimationTimer()
        }
    }

    func update(snapshot: RhythmSnapshot) {
        self.snapshot = snapshot
        if snapshot.hitCount == 0 { clearPulses() }
        updateStatusLabels()
        updateAccessibility()
        needsDisplay = true
    }

    func setStatus(_ status: CaptureStatus) {
        self.status = status
        if status != .listening, status != .preview { clearPulses() }
        updateStatusLabels()
        updateAccessibility()
        needsDisplay = true
    }

    func clearPulses() {
        animationTimer?.invalidate()
        animationTimer = nil
        pulseStartedAt.removeAll()
        bassChordFlash.reset()
        backgroundEQ.reset()
        needsDisplay = true
    }

    private func startAnimationTimer() {
        guard animationTimer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.advancePulses() }
        }
        animationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func advancePulses() {
        let now = ProcessInfo.processInfo.systemUptime
        pulseStartedAt = pulseStartedAt.filter { now - $0.value < pulseDuration }
        needsDisplay = true
        let eqIsAnimating = eqOpacity > 0 && backgroundEQ.isAnimating(at: now)
        if pulseStartedAt.isEmpty, bassChordFlash.intensity(at: now) == 0, !eqIsAnimating {
            animationTimer?.invalidate()
            animationTimer = nil
        }
    }

    private func drawBackgroundEQ() {
        guard eqOpacity > 0 else { return }
        let levels = backgroundEQ.levels(at: ProcessInfo.processInfo.systemUptime)
        let area = bounds.insetBy(dx: 4, dy: 4)
        let spacing = area.width / CGFloat(levels.count)
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let stems = NSBezierPath()

        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 23, yRadius: 23).addClip()
        for (index, level) in levels.enumerated() {
            let visibleLevel = reduceMotion ? 0.32 + Double(index % 7) * 0.035 : level
            let height = area.height * visibleLevel
            let stem = NSBezierPath(roundedRect: NSRect(
                x: area.minX + (CGFloat(index) + 0.5) * spacing - 0.55,
                y: area.maxY - height, width: 1.1, height: height
            ), xRadius: 0.55, yRadius: 0.55)
            if reduceMotion {
                drawEQGradient(in: stem, area: area, opacity: eqOpacity * (0.15 + level * 0.85))
            } else {
                stems.append(stem)
            }
        }
        if !reduceMotion { drawEQGradient(in: stems, area: area, opacity: eqOpacity) }
        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawEQGradient(in path: NSBezierPath, area: NSRect, opacity: Double) {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current?.cgContext.setAlpha(opacity)
        path.addClip()
        // Anchor the colors to the entire HUD, so red appears only when a band
        // actually reaches the top rather than at the tip of every short stem.
        eqGradient?.draw(
            from: NSPoint(x: area.midX, y: area.maxY),
            to: NSPoint(x: area.midX, y: area.minY),
            options: [.drawsBeforeStartingLocation, .drawsAfterEndingLocation]
        )
        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawBassChordBorder() {
        var intensity = bassChordFlash.intensity(at: ProcessInfo.processInfo.systemUptime)
        guard intensity > 0 else { return }
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion { intensity *= 0.45 }

        let tint = NSColor.systemIndigo.blended(withFraction: 0.5, of: .systemBlue) ?? .systemBlue
        let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 4), xRadius: 20, yRadius: 20)
        tint.withAlphaComponent(0.16 * intensity).setStroke()
        border.lineWidth = 7
        border.stroke()
        tint.withAlphaComponent(0.95 * intensity).setStroke()
        border.lineWidth = 2.2
        border.stroke()

        let highlight = NSBezierPath(roundedRect: bounds.insetBy(dx: 5.5, dy: 5.5), xRadius: 18.5, yRadius: 18.5)
        NSColor.white.withAlphaComponent(0.65 * intensity).setStroke()
        highlight.lineWidth = 0.8
        highlight.stroke()
    }

    private func updateStatusLabels() {
        let meter = snapshot.meter ?? .initial
        meterLabel.stringValue = meter.confidence < 0.8 ? "≈\(meter.signature)" : meter.signature
        switch status {
        case .permissionRequired: tempoLabel.stringValue = "Allow input"
        case .unavailable: tempoLabel.stringValue = "Retry input"
        case .secureInput: tempoLabel.stringValue = "Secure input"
        case .paused: tempoLabel.stringValue = "Paused"
        case .listening, .preview:
            tempoLabel.stringValue = snapshot.bpm.map {
                let prefix = snapshot.tempoConfidence < 0.70 ? "≈" : ""
                return "\(prefix)\(Int($0.rounded())) BPM"
            }
                ?? (snapshot.hitCount == 0 ? status.rawValue : "Finding pulse")
        }
    }

    private func drawSoundstage() {
        let center = stage.center

        // Thin nested rims leave the middle open and give the glass columns a
        // shared circular stage. A Space accent lights the complete outer rim.
        for radius: CGFloat in [37, 54, 64] {
            let ringRect = stage.ringRect(radius: radius)
            let ring = NSBezierPath(ovalIn: ringRect)
            NSColor.labelColor.withAlphaComponent(0.07).setStroke()
            ring.lineWidth = 0.7
            ring.stroke()
            NSColor.white.withAlphaComponent(0.30).setStroke()
            let highlight = NSBezierPath(ovalIn: ringRect)
            highlight.lineWidth = 0.5
            highlight.stroke()
        }

        for key in DrumKey.allCases where pulseIntensity(for: key) > 0 {
            drawStageRipples(for: key)
        }

        drawBeatMarkers(around: center)

        for artifact in stage.artifacts.sorted(by: { $0.baseRect.maxY < $1.baseRect.maxY }) {
            drawGlassArtifact(artifact)
        }
    }

    private func drawStageRipples(for key: DrumKey) {
        let intensity = pulseIntensity(for: key)
        let tint = color(for: key)
        let isAccent = key == .space || key == .l
        let isBass = key == .d || key == .f
        let strength = isAccent ? 0.50 : (isBass ? 0.22 : 0.16)
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            tint.withAlphaComponent(strength * intensity).setStroke()
            let rim = NSBezierPath(ovalIn: stage.ringRect(radius: 64))
            rim.lineWidth = isBass ? 2 : 1.5
            rim.stroke()
            return
        }

        let progress = 1 - intensity
        let delays: [Double] = isAccent ? [0, 0.18, 0.36] : [0, 0.24]
        for delay in delays where progress >= delay {
            let wave = (progress - delay) / (1 - delay)
            let radius = 10 + wave * (isAccent ? 68 : 47)
            let ripple = NSBezierPath(ovalIn: stage.ringRect(radius: radius))
            tint.withAlphaComponent(strength * (1 - wave) * intensity).setStroke()
            ripple.lineWidth = (0.75 + (1 - wave) * 0.75) * (isBass ? 1.4 : 1)
            ripple.stroke()
        }
    }

    private func drawBeatMarkers(around center: NSPoint) {
        let beats = snapshot.meter?.beatsPerBar ?? 4
        for index in 0..<beats {
            let angle = -Double.pi / 2 + Double(index) * 2 * Double.pi / Double(beats)
            let point = NSPoint(x: center.x + cos(angle) * 37, y: center.y + sin(angle) * 37)
            let isCurrent = snapshot.beatInBar == index + 1
            let diameter: CGFloat = isCurrent ? 4 : 2.5
            NSColor.labelColor.withAlphaComponent(isCurrent ? 0.65 : 0.18).setFill()
            NSBezierPath(ovalIn: NSRect(
                x: point.x - diameter / 2, y: point.y - diameter / 2,
                width: diameter, height: diameter
            )).fill()
        }
    }

    private func drawGlassArtifact(_ artifact: GlassArtifact) {
        let key = artifact.key
        let isBass = artifact.isBass
        let intensity = pulseIntensity(for: key)
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let rect = artifact.frontRect(intensity: intensity, reduceMotion: reduceMotion)
        let depth = SoundstageLayout.depth
        let tint = color(for: key)
        let front = NSBezierPath(roundedRect: rect, xRadius: 2.5, yRadius: 2.5)
        let top = polygon([
            NSPoint(x: rect.minX, y: rect.minY),
            NSPoint(x: rect.minX + depth.x, y: rect.minY + depth.y),
            NSPoint(x: rect.maxX + depth.x, y: rect.minY + depth.y),
            NSPoint(x: rect.maxX, y: rect.minY)
        ])
        let side = polygon([
            NSPoint(x: rect.minX, y: rect.minY),
            NSPoint(x: rect.minX + depth.x, y: rect.minY + depth.y),
            NSPoint(x: rect.minX + depth.x, y: rect.maxY + depth.y),
            NSPoint(x: rect.minX, y: rect.maxY)
        ])

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.13 + intensity * 0.06)
        shadow.shadowBlurRadius = 3
        shadow.shadowOffset = NSSize(width: -1, height: -2)
        shadow.set()
        tint.withAlphaComponent(0.12 + intensity * 0.10).setFill()
        front.fill()
        NSGraphicsContext.restoreGraphicsState()

        let paleTint = tint.blended(withFraction: 0.55, of: .white) ?? tint
        let bassEmphasis = isBass ? 0.04 + intensity * 0.08 : 0
        NSGradient(
            starting: paleTint.withAlphaComponent(0.45 + intensity * 0.30 + bassEmphasis),
            ending: tint.withAlphaComponent(0.22 + intensity * 0.32 + bassEmphasis)
        )?.draw(in: front, angle: 90)
        NSGradient(
            starting: tint.withAlphaComponent(0.24 + intensity * 0.25),
            ending: tint.withAlphaComponent(0.10 + intensity * 0.18)
        )?.draw(in: side, angle: 180)
        NSGradient(
            starting: NSColor.white.withAlphaComponent(0.65),
            ending: paleTint.withAlphaComponent(0.45 + intensity * 0.30)
        )?.draw(in: top, angle: 70)

        for face in [front, side, top] {
            NSColor.white.withAlphaComponent(0.45 + intensity * 0.20).setStroke()
            face.lineWidth = isBass ? 1.05 : 0.55
            face.stroke()
        }

        let reflection = NSBezierPath()
        reflection.move(to: NSPoint(x: rect.maxX - 2, y: rect.minY + 3))
        reflection.line(to: NSPoint(x: rect.maxX - 2, y: rect.maxY - 3))
        NSColor.white.withAlphaComponent(0.34 + intensity * 0.25).setStroke()
        reflection.lineWidth = isBass ? 1.3 : 0.8
        reflection.stroke()

        if intensity > 0, !reduceMotion {
            let progress = 1 - intensity
            for delay in [0.0, 0.18, 0.36] where progress >= delay {
                let wave = (progress - delay) / (1 - delay)
                let diameter = 9 + wave * 26
                let foot = artifact.footprint
                let ripple = NSBezierPath(ovalIn: NSRect(
                    x: foot.x - diameter / 2, y: foot.y - diameter / 4,
                    width: diameter, height: diameter / 2
                ))
                tint.withAlphaComponent((1 - wave) * intensity * (isBass ? 0.55 : 0.40)).setStroke()
                ripple.lineWidth = isBass ? 1.6 : 0.9
                ripple.stroke()
            }
        }
    }

    private func polygon(_ points: [NSPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() { path.line(to: point) }
        path.close()
        path.lineJoinStyle = .round
        return path
    }

    private func pulseIntensity(for key: DrumKey) -> Double {
        guard let start = pulseStartedAt[key] else { return 0 }
        return max(0, 1 - (ProcessInfo.processInfo.systemUptime - start) / pulseDuration)
    }

    private func updateAccessibility() {
        let tempo = snapshot.bpm.map {
            let prefix = snapshot.tempoConfidence < 0.70 ? "Approximately " : ""
            return "\(prefix)\(Int($0.rounded())) beats per minute"
        } ?? "Finding tempo"
        let meter = snapshot.meter ?? .initial
        let qualification = meter.confidence < 0.8 ? "Tentative" : "Estimated"
        setAccessibilityLabel("DrumKey. \(status.rawValue). \(tempo). \(qualification) meter \(meter.signature).")
    }

    private func color(for key: DrumKey) -> NSColor {
        switch key {
        case .d: .systemIndigo
        case .f: .systemBlue
        case .j: .systemOrange
        case .k: .systemPink
        case .l: .systemTeal
        case .space: .systemMint
        }
    }
}
