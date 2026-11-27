import Foundation

enum VisualizerTheme: String, CaseIterable {
    case glassCircle, pulseHalo, radialSpectrum, linearEQ, mirrorWave, orbitDots, ledMatrix
    case circleTowers, razorBloom, silkRibbons, hexArray

    var label: String {
        switch self {
        case .glassCircle: "Glass Circle"
        case .pulseHalo: "Pulse Halo"
        case .radialSpectrum: "Radial Spectrum"
        case .linearEQ: "Linear EQ"
        case .mirrorWave: "Mirror Wave"
        case .orbitDots: "Orbit Shards"
        case .ledMatrix: "LED Matrix"
        case .circleTowers: "Circle Towers"
        case .razorBloom: "Razor Bloom"
        case .silkRibbons: "Silk Ribbons"
        case .hexArray: "Hex Array"
        }
    }

    var isCircular: Bool {
        switch self {
        case .glassCircle, .pulseHalo, .radialSpectrum, .orbitDots, .circleTowers, .razorBloom: true
        case .linearEQ, .mirrorWave, .ledMatrix, .silkRibbons, .hexArray: false
        }
    }

    var usesRadialKeyMap: Bool {
        switch self {
        case .pulseHalo, .radialSpectrum, .orbitDots, .razorBloom: true
        default: false
        }
    }
}
