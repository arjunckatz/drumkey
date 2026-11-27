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

    @Test func bassFormsSideJawsAndDiagonalHornsWithSeparateCrowns() {
        func response(_ key: DrumKey, _ degrees: Double) -> Double {
            RadialKeyMap.sample(at: degrees * .pi / 180).level(in: [key: 1])
        }
        #expect(response(.d, 90) == 1 && response(.d, 270) == 1)
        #expect(response(.d, 0) == 0)
        #expect(response(.f, 45) == 1 && response(.f, 225) == 1)
        #expect(response(.f, 90) == 0)
        #expect(response(.j, 0) == 1 && response(.j, 180) == 0)
        #expect(response(.k, 180) == 1 && response(.k, 0) == 0)
        #expect(response(.l, 15) > 0.7 && response(.l, 0) == 0)
        #expect(response(.d, 90) > response(.d, 87) && response(.d, 90) > response(.d, 93))
    }

    @Test func mixedHitsStayBoundedAndSpaceDoesNotInflateUnrelatedRegions() {
        let allKeys = Dictionary(uniqueKeysWithValues: DrumKey.allCases.map { ($0, 1.0) })
        for sample in RadialKeyMap.halo + RadialKeyMap.spectrum + RadialKeyMap.orbits {
            #expect(sample.level(in: [:]) == 0)
            #expect((0...1).contains(sample.level(in: allKeys)))
            #expect(sample.level(in: [.space: 1]) == 0)
        }
    }
}
