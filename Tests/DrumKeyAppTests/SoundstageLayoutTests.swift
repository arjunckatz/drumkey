import AppKit
import DrumKeyCore
import Testing
@testable import DrumKey

struct SoundstageLayoutTests {
    private let bounds = NSRect(x: 0, y: 0, width: 192, height: 252)

    @Test func insertsOneAccentBarAfterEachColoredTriplet() {
        let artifacts = SoundstageLayout(bounds: bounds).artifacts
        #expect(artifacts.count == 16)
        for group in 0..<4 {
            let start = group * 4
            #expect(artifacts[start].key == artifacts[start + 1].key)
            #expect(artifacts[start].key == artifacts[start + 2].key)
            #expect(artifacts[start].key != .l)
            #expect(artifacts[start + 3].key == .l)
        }
    }

    @Test func projectedBlocksAndRipplesShareTheSameCenter() {
        let stage = SoundstageLayout(bounds: bounds)
        let centers = stage.artifacts.map { artifact in
            let rect = artifact.baseRect
            let projected = rect.union(rect.offsetBy(dx: SoundstageLayout.depth.x, dy: SoundstageLayout.depth.y))
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

    @Test func higherPeakRiseFitsBelowTheHeader() {
        for artifact in SoundstageLayout(bounds: bounds).artifacts {
            let rest = artifact.frontRect(intensity: 0, reduceMotion: false)
            let peak = artifact.frontRect(intensity: 1, reduceMotion: false)
            let projected = peak.union(peak.offsetBy(dx: SoundstageLayout.depth.x, dy: SoundstageLayout.depth.y))
            #expect(rest.minY - peak.minY > 10)
            #expect(projected.minY >= 66)
            #expect(bounds.insetBy(dx: 8, dy: 8).contains(projected))
        }
    }

    @Test func reducedMotionKeepsTheBarsStationary() {
        for artifact in SoundstageLayout(bounds: bounds).artifacts {
            #expect(artifact.frontRect(intensity: 1, reduceMotion: true) == artifact.baseRect)
        }
    }

    @Test func physicalLKeyMapsToTheAccentBars() {
        #expect(DrumKey(macKeyCode: 37) == .l)
    }
}
