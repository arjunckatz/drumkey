import AppKit
import DrumKeyCore
import Testing
@testable import DrumKey

struct SoundstageLayoutTests {
    private let bounds = NSRect(x: 0, y: 0, width: 192, height: 252)

    @Test func alternatesBassAndPercussionWithWideCardinalAccents() {
        let stage = SoundstageLayout(bounds: bounds)
        let artifacts = stage.artifacts
        #expect(artifacts.count == 16)
        let bass = artifacts.filter { $0.isBass }.sorted { $0.center.y < $1.center.y }
        let percussion = artifacts.filter { $0.key == .j || $0.key == .k }.sorted { $0.center.y < $1.center.y }
        #expect(bass.map(\.key) == [.d, .f, .d, .f, .d, .f])
        #expect(percussion.map(\.key) == [.j, .k, .j, .k, .j, .k])
        #expect(bass.allSatisfy { $0.center.x < stage.center.x })
        #expect(percussion.allSatisfy { $0.center.x > stage.center.x })
        let accents = artifacts.filter { $0.key == .l }
        #expect(accents.count == 4)
        for accent in accents {
            #expect(abs(accent.center.x - stage.center.x) < 0.0001 || abs(accent.center.y - stage.center.y) < 0.0001)
            #expect(accent.width > (bass.map(\.width).max() ?? 0))
        }
    }

    @Test(arguments: OverlayScale.allCases) func projectedBlocksAndRimsShareTheSameCenter(scale: OverlayScale) {
        let size = scale.size(fitting: CGSize(width: 2000, height: 2000))
        let stage = SoundstageLayout(bounds: NSRect(origin: .zero, size: size))
        let centers = stage.artifacts.map { artifact in
            let rect = artifact.baseRect
            let projected = rect.union(rect.offsetBy(dx: artifact.depth.x, dy: artifact.depth.y))
            #expect(abs(projected.midX - artifact.center.x) < 0.0001)
            #expect(abs(projected.midY - artifact.center.y) < 0.0001)
            return NSPoint(x: projected.midX, y: projected.midY)
        }
        let averageX = centers.map(\.x).reduce(0, +) / CGFloat(centers.count)
        let averageY = centers.map(\.y).reduce(0, +) / CGFloat(centers.count)
        #expect(abs(averageX - stage.center.x) < 0.0001)
        #expect(abs(averageY - stage.center.y) < 0.0001)
        let ring = stage.ringRect(radius: 64)
        #expect(ring.midX == stage.center.x && ring.midY == stage.center.y)
        #expect(SoundstageLayout.depth.x < 0)
    }

    @Test(arguments: OverlayScale.allCases) func growingTopsKeepTheirBasesFixedAndStayBelowTheHeader(scale: OverlayScale) {
        let size = scale.size(fitting: CGSize(width: 2000, height: 2000))
        let scaledBounds = NSRect(origin: .zero, size: size)
        for artifact in SoundstageLayout(bounds: scaledBounds).artifacts {
            let rest = artifact.frontRect(intensity: 0, reduceMotion: false)
            let peak = artifact.frontRect(intensity: 1, reduceMotion: false)
            let projected = peak.union(peak.offsetBy(dx: artifact.depth.x, dy: artifact.depth.y))
            #expect(peak.height > rest.height)
            for energy in [0.2, 0.6, 1.0] {
                let growing = artifact.frontRect(intensity: energy, reduceMotion: false)
                #expect(abs(growing.maxY - rest.maxY) < 0.0001)
                #expect(growing.minX == rest.minX && growing.width == rest.width)
            }
            #expect(projected.minY >= 66)
            #expect(scaledBounds.insetBy(dx: 8, dy: 8).contains(projected))
        }
    }

    @Test func reducedMotionKeepsTheBarsStationary() {
        for artifact in SoundstageLayout(bounds: bounds).artifacts {
            #expect(artifact.frontRect(intensity: 1, reduceMotion: true) == artifact.baseRect)
        }
    }

    @Test(arguments: OverlayScale.allCases) func expandedRadialPeaksLeaveRoomForGlowAndLabels(scale: OverlayScale) {
        let size = scale.size(fitting: CGSize(width: 2000, height: 2000))
        let stage = SoundstageLayout(bounds: NSRect(origin: .zero, size: size))
        let radius = stage.maximumRadialRadius + 5 * stage.scale
        let illuminatedBounds = NSRect(x: stage.center.x - radius, y: stage.center.y - radius,
                                      width: radius * 2, height: radius * 2)
        #expect(illuminatedBounds.minY >= 66 - 0.0001)
        #expect(stage.bounds.contains(illuminatedBounds))
        #expect(stage.maximumRadialRadius / stage.scale > 79)
    }

    @Test func physicalLKeyMapsToTheAccentBars() {
        #expect(DrumKey(macKeyCode: 37) == .l)
    }

    @Test(arguments: OverlayScale.allCases) func circleTowersKeepTheirBasesAndPeaksInsideThePanel(scale: OverlayScale) {
        let size = scale.size(fitting: CGSize(width: 2000, height: 2000))
        let stage = SoundstageLayout(bounds: NSRect(origin: .zero, size: size))
        #expect(stage.towerArtifacts.count == 18)
        for tower in stage.towerArtifacts {
            let travel: CGFloat = tower.isBass ? 36 : (tower.key == .l ? 44 : 26)
            let rest = tower.baseRect
            let peak = tower.frontRect(intensity: 1, reduceMotion: false, maximumExtension: travel)
            let projected = peak.union(peak.offsetBy(dx: tower.depth.x, dy: tower.depth.y))
            #expect(abs(peak.maxY - rest.maxY) < 0.0001)
            #expect(projected.minY >= 66)
            #expect(stage.bounds.insetBy(dx: 8, dy: 8).contains(projected))
            if tower.key == .d { #expect(tower.center.x < stage.center.x) }
            if tower.key == .f { #expect(tower.center.x > stage.center.x) }
        }
    }
}
