import DrumKeyCore
import Testing
@testable import DrumKey

struct EQKeyMapTests {
    @Test func bassColumnsStayOnTheLeftAndHaveTallerPeaksInBothLayouts() {
        for keys in [EQKeyMap.linear, EQKeyMap.led] {
            #expect(keys.prefix(keys.count / 2).allSatisfy(EQKeyMap.isBass))
            #expect(keys.suffix(keys.count / 2).allSatisfy { !EQKeyMap.isBass($0) })
            #expect(Set(keys) == Set([.d, .f, .j, .k, .l]))
        }
        for bass: DrumKey in [.d, .f] {
            for percussion: DrumKey in [.j, .k, .l] {
                #expect(EQKeyMap.peakHeight(for: bass) > EQKeyMap.peakHeight(for: percussion) * 1.5)
                #expect(EQKeyMap.ledRows(for: bass) > EQKeyMap.ledRows(for: percussion))
            }
        }
    }

    @Test func backgroundBassNeverLeaksRightAndRepeatedPercussionStaysLower() {
        for index in 0...100 {
            let position = Double(index) / 100
            if position >= 0.5 {
                #expect(EQKeyMap.backgroundResponse(for: .d, at: position) == 0)
                #expect(EQKeyMap.backgroundResponse(for: .f, at: position) == 0)
            } else {
                for key: DrumKey in [.j, .k, .l] {
                    #expect(EQKeyMap.backgroundResponse(for: key, at: position) == 0)
                }
            }
        }
        var eq = BackgroundEQ()
        for index in 0..<100 {
            for key: DrumKey in [.d, .f, .j, .k, .l] { eq.register(key: key, at: Double(index) * 0.01) }
        }
        let levels = eq.levels(at: 0.99)
        #expect((levels.prefix(20).max() ?? 0) > 0.94)
        #expect((levels.suffix(20).max() ?? 1) < 0.72)
    }
}
