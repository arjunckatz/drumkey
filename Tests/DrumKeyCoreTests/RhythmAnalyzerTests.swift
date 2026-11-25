import Testing
@testable import DrumKeyCore

struct RhythmAnalyzerTests {
    @Test
    func estimatesTempoFromQuarterNoteTaps() {
        var analyzer = RhythmAnalyzer()

        for index in 0..<8 {
            analyzer.register(
                DrumHit(key: .d, timestamp: Double(index) * 0.5)
            )
        }

        #expect(analyzer.snapshot.bpm == 120)
    }

    @Test
    func foldsSubdivisionTapsIntoAPlausibleBeat() {
        var analyzer = RhythmAnalyzer()

        for index in 0..<12 {
            analyzer.register(
                DrumHit(key: .j, timestamp: Double(index) * 0.125)
            )
        }

        #expect(analyzer.snapshot.bpm == 120)
    }

    @Test func unevenTapsAverageToATempoWithinFifteenSeconds() {
        var analyzer = RhythmAnalyzer()
        let offsets = [0.0, 0.04, -0.05, 0.03, -0.025, 0.05, -0.015, -0.035]
        for index in 0..<28 {
            let timestamp = Double(index) * 0.5 + offsets[index % offsets.count]
            analyzer.register(DrumHit(key: index.isMultiple(of: 2) ? .d : .j, timestamp: timestamp))
            if timestamp >= 10 {
                #expect(abs((analyzer.snapshot.bpm ?? 0) - 120) < 4)
            }
        }
    }

    @Test func irregularTappingStillProducesAnUncertainAverageAfterWarmup() {
        var analyzer = RhythmAnalyzer()
        let intervals = [0.34, 0.62, 0.43, 0.75, 0.39, 0.57, 0.82, 0.46, 0.69, 0.36]
        var timestamp = 0.0
        analyzer.register(DrumHit(key: .d, timestamp: timestamp))
        for index in 0..<28 {
            timestamp += intervals[index % intervals.count]
            analyzer.register(DrumHit(key: .f, timestamp: timestamp))
            if timestamp >= 10 {
                #expect(analyzer.snapshot.bpm != nil)
                #expect((60...200).contains(analyzer.snapshot.bpm ?? 0))
                #expect(analyzer.snapshot.tempoConfidence < 0.70)
            }
        }
    }

    @Test func mixedSubdivisionsAndMissedBeatsKeepTheirAveragePulse() {
        var analyzer = RhythmAnalyzer()
        let intervals = [0.25, 0.25, 0.5, 0.25, 0.75, 0.5, 1.0, 0.5]
        let offsets = [0.0, 0.015, -0.02, 0.01]
        var timestamp = 0.0
        analyzer.register(DrumHit(key: .d, timestamp: timestamp))
        for index in 0..<36 {
            timestamp += intervals[index % intervals.count]
            let hitTime = timestamp + offsets[index % offsets.count]
            analyzer.register(DrumHit(key: .j, timestamp: hitTime))
            analyzer.register(DrumHit(key: .k, timestamp: hitTime + 0.008))
        }
        #expect(abs((analyzer.snapshot.bpm ?? 0) - 120) < 3)
    }

    @Test func twelveSecondAverageAdaptsToANewTempo() {
        var analyzer = RhythmAnalyzer()
        for index in 0..<30 {
            analyzer.register(DrumHit(key: .d, timestamp: Double(index) * 0.5))
        }
        #expect(analyzer.snapshot.bpm == 120)
        for index in 0..<26 {
            analyzer.register(DrumHit(key: .d, timestamp: 15 + Double(index) * 0.6))
        }
        #expect(abs((analyzer.snapshot.bpm ?? 0) - 100) < 1)
    }

    @Test func jitterAtTheTempoBoundariesDoesNotForceAnOctaveJump() {
        for bpm in [60.0, 200.0] {
            var analyzer = RhythmAnalyzer()
            let interval = 60 / bpm
            let offsets = [0.0, 0.035, -0.025, 0.02, -0.015]
            for index in 0..<Int(15 / interval) {
                let timestamp = Double(index) * interval + offsets[index % offsets.count]
                analyzer.register(DrumHit(key: .d, timestamp: timestamp))
            }
            #expect(abs((analyzer.snapshot.bpm ?? 0) - bpm) < 4, "Target BPM: \(bpm), actual: \(String(describing: analyzer.snapshot.bpm))")
        }
    }

    @Test func uncertainEarlyTapsKeepTheLastBpmVisible() {
        var analyzer = RhythmAnalyzer()
        for index in 0..<8 {
            analyzer.register(DrumHit(key: .d, timestamp: Double(index) * 0.5))
        }
        for timestamp in [3.83, 4.51, 4.94, 5.69, 6.08] {
            analyzer.register(DrumHit(key: .j, timestamp: timestamp))
            #expect(analyzer.snapshot.bpm != nil)
        }
    }

    @Test
    func resetsHistoryAfterAnIdleGap() {
        var analyzer = RhythmAnalyzer(idleResetInterval: 3)

        for index in 0..<5 {
            analyzer.register(
                DrumHit(key: .space, timestamp: Double(index) * 0.5)
            )
        }
        analyzer.register(DrumHit(key: .space, timestamp: 10))

        #expect(analyzer.snapshot.hitCount == 1)
        #expect(analyzer.snapshot.bpm == nil)
    }

    @Test
    func showsTentativeMeterWhileEvidenceIsStillGrowing() {
        var analyzer = RhythmAnalyzer()

        for index in 0..<12 {
            analyzer.register(
                DrumHit(key: index.isMultiple(of: 4) ? .space : .d, timestamp: Double(index) * 0.5)
            )
        }

        #expect(analyzer.snapshot.meter?.signature == "4/4")
        #expect((analyzer.snapshot.meter?.confidence ?? 1) < 0.8)
    }

    @Test
    func recognizesAStrongFourBeatKeyPattern() {
        var analyzer = RhythmAnalyzer()
        let pattern: [DrumKey] = [.space, .d, .f, .j]

        for index in 0..<32 {
            analyzer.register(
                DrumHit(
                    key: pattern[index % pattern.count],
                    timestamp: Double(index) * 0.5
                )
            )
        }

        #expect(analyzer.snapshot.meter?.signature == "4/4")
        #expect(analyzer.snapshot.meter?.confidence ?? 0 >= 0.72)
    }

    @Test func spaceAccentsRevealThreeAndFourBeatBars() {
        for beatsPerBar in [3, 4] {
            var analyzer = RhythmAnalyzer()
            for beat in 0..<(beatsPerBar * 5) {
                let timestamp = Double(beat) * 0.5
                analyzer.register(DrumHit(key: .d, timestamp: timestamp))
                if beat.isMultiple(of: beatsPerBar) {
                    analyzer.register(DrumHit(key: .space, timestamp: timestamp + 0.005))
                }
            }
            #expect(abs((analyzer.snapshot.bpm ?? 0) - 120) < 1)
            #expect(analyzer.snapshot.meter?.signature == "\(beatsPerBar)/4")
        }
    }

    @Test func steadyUnaccentedPulseHasAmbiguousMeter() {
        var analyzer = RhythmAnalyzer()
        for index in 0..<48 {
            analyzer.register(DrumHit(key: .d, timestamp: Double(index) * 0.5))
        }
        #expect(analyzer.snapshot.bpm == 120)
        #expect(analyzer.snapshot.meter?.signature == "4/4")
        #expect((analyzer.snapshot.meter?.confidence ?? 1) < 0.5)
    }

    @Test func chordsDoNotDoubleTheTempo() {
        var analyzer = RhythmAnalyzer()
        for index in 0..<16 {
            analyzer.register(DrumHit(key: .d, timestamp: Double(index) * 0.5))
            analyzer.register(DrumHit(key: .k, timestamp: Double(index) * 0.5 + 0.008))
        }
        #expect(abs((analyzer.snapshot.bpm ?? 0) - 120) < 1)
    }

    @Test func idleExpirationClearsStaleEstimatesWithoutAnotherTap() {
        var analyzer = RhythmAnalyzer()
        for index in 0..<8 {
            analyzer.register(DrumHit(key: .f, timestamp: Double(index) * 0.5))
        }
        let expired = analyzer.expire(at: 35)
        #expect(expired)
        #expect(analyzer.snapshot == .empty)
    }

    @Test func invalidAndOutOfOrderTimestampsDoNotCorruptHistory() {
        var analyzer = RhythmAnalyzer()
        analyzer.register(DrumHit(key: .d, timestamp: 1))
        for timestamp in [Double.nan, .infinity, -1, 0.5] {
            analyzer.register(DrumHit(key: .d, timestamp: timestamp))
        }
        #expect(analyzer.snapshot.hitCount == 1)
        #expect(analyzer.snapshot.bpm == nil)
    }

    @Test func showsBaselineMeterBeforeTempoCanBeEstimated() {
        var analyzer = RhythmAnalyzer()
        #expect(analyzer.snapshot.meter == .initial)
        analyzer.register(DrumHit(key: .d, timestamp: 1))
        #expect(analyzer.snapshot.meter?.signature == "4/4")
        #expect(analyzer.snapshot.meter?.confidence == 0)
    }

    @Test func repeatedBarsIncreaseConfidenceOverTime() {
        var analyzer = RhythmAnalyzer()
        let pattern: [DrumKey] = [.space, .d, .j]
        for index in 0..<9 {
            analyzer.register(DrumHit(key: pattern[index % 3], timestamp: Double(index) * 0.5))
        }
        let earlyConfidence = analyzer.snapshot.meter?.confidence ?? 0
        for index in 9..<96 {
            analyzer.register(DrumHit(key: pattern[index % 3], timestamp: Double(index) * 0.5))
        }
        #expect(analyzer.snapshot.meter?.signature == "3/4")
        #expect((analyzer.snapshot.meter?.confidence ?? 0) > earlyConfidence + 0.3)
    }

    @Test func shortPausesPreserveTheLearnedPattern() {
        var analyzer = RhythmAnalyzer()
        for index in 0..<12 {
            analyzer.register(DrumHit(key: .d, timestamp: Double(index) * 0.5))
        }
        let expired = analyzer.expire(at: 12)
        #expect(!expired)
        analyzer.register(DrumHit(key: .f, timestamp: 12))
        #expect(analyzer.snapshot.hitCount == 13)
    }

    @Test func extendedTappingRetainsMoreThanTheOldHistoryLimit() {
        var analyzer = RhythmAnalyzer()
        let pattern: [DrumKey] = [.space, .d, .f, .j]
        for index in 0..<320 {
            analyzer.register(DrumHit(key: pattern[index % 4], timestamp: Double(index) * 0.5))
        }
        #expect(analyzer.snapshot.hitCount == 320)
        #expect(analyzer.snapshot.meter?.signature == "4/4")
        #expect((analyzer.snapshot.meter?.confidence ?? 0) > 0.8)
    }

    @Test func sustainedNewEvidenceCanChangeTheInitialMeter() {
        var analyzer = RhythmAnalyzer()
        let fourBeatPattern: [DrumKey] = [.space, .d, .f, .j]
        for index in 0..<32 {
            analyzer.register(DrumHit(key: fourBeatPattern[index % 4], timestamp: Double(index) * 0.5))
        }
        #expect(analyzer.snapshot.meter?.signature == "4/4")
        let threeBeatPattern: [DrumKey] = [.space, .d, .j]
        for index in 0..<192 {
            analyzer.register(DrumHit(key: threeBeatPattern[index % 3], timestamp: 16 + Double(index) * 0.5))
        }
        #expect(analyzer.snapshot.meter?.signature == "3/4")
    }

    @Test func manualVisualAccentsDoNotChangeTheRhythmEstimate() {
        var analyzer = RhythmAnalyzer()
        for index in 0..<16 {
            analyzer.register(DrumHit(key: .d, timestamp: Double(index) * 0.5))
        }
        let original = analyzer.snapshot
        for index in 0..<8 {
            analyzer.register(DrumHit(key: .l, timestamp: 8 + Double(index) * 0.12))
        }
        #expect(analyzer.snapshot == original)
    }
}
