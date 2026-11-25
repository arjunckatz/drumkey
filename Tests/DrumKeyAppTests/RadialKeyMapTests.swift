import Foundation
import DrumKeyCore
import Testing
@testable import DrumKey

struct RadialKeyMapTests {
    @Test func everyHitHasMatchedLeftAndRightResponses() {
        for key in DrumKey.allCases {
            for degree in stride(from: 0, through: 180, by: 3) {
                let angle = Double(degree) * .pi / 180
                let right = RadialKeyMap.sample(at: angle)
                let left = RadialKeyMap.sample(at: -angle)
                let levels = [key: 0.7]
                #expect(abs(right.level(in: levels) - left.level(in: levels)) < 0.000001)
                #expect(abs(right.x + left.x) < 0.000001)
                #expect(abs(right.y - left.y) < 0.000001)
            }
        }
    }

    @Test func bassOccupiesBroadUpperArcsAndAccentsOccupyTheLowerEdge() {
        func distribution(_ key: DrumKey) -> (centerY: Double, coverage: Int) {
            let responses = RadialKeyMap.halo.map { ($0.y, $0.level(in: [key: 1])) }
            let total = responses.reduce(0) { $0 + $1.1 }
            return (responses.reduce(0) { $0 + $1.0 * $1.1 } / total,
                    responses.filter { $0.1 > 0.5 }.count)
        }
        let bassD = distribution(.d)
        let bassF = distribution(.f)
        let snare = distribution(.j)
        let tom = distribution(.k)
        let accent = distribution(.l)
        #expect(bassD.centerY < -0.6 && bassF.centerY < -0.3)
        #expect(abs(snare.centerY) < 0.1)
        #expect(tom.centerY > 0.4 && accent.centerY > 0.8)
        #expect(bassD.coverage > accent.coverage && bassF.coverage > accent.coverage)
        #expect(Set(RadialKeyMap.orbits.map(\.primaryKey)) == Set([.d, .f, .j, .k, .l]))
    }

    @Test func mixedHitsStayBoundedAndSpaceAccentsTheWholeRim() {
        let allKeys = Dictionary(uniqueKeysWithValues: DrumKey.allCases.map { ($0, 1.0) })
        for sample in RadialKeyMap.halo + RadialKeyMap.spectrum + RadialKeyMap.orbits {
            #expect(sample.level(in: [:]) == 0)
            #expect((0...1).contains(sample.level(in: allKeys)))
            #expect(abs(sample.level(in: [.space: 1]) - 0.55) < 0.000001)
        }
    }
}
