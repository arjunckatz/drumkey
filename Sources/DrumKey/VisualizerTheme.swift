import Foundation

enum VisualizerTheme: String, CaseIterable {
    case glassCircle, pulseHalo, radialSpectrum, linearEQ, mirrorWave, orbitDots, ledMatrix

    var label: String {
        switch self {
        case .glassCircle: "Glass Circle"
        case .pulseHalo: "Pulse Halo"
        case .radialSpectrum: "Radial Spectrum"
        case .linearEQ: "Linear EQ"
        case .mirrorWave: "Mirror Wave"
        case .orbitDots: "Orbit Dots"
        case .ledMatrix: "LED Matrix"
        }
    }

    var isCircular: Bool {
        switch self {
        case .glassCircle, .pulseHalo, .radialSpectrum, .orbitDots: true
        case .linearEQ, .mirrorWave, .ledMatrix: false
        }
    }

    var usesRadialKeyMap: Bool { isCircular && self != .glassCircle }
}
