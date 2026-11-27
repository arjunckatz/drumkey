import AppKit
import DrumKeyCore

enum VisualizerColorScheme: String, CaseIterable {
    case classic, aurora, sunset, neon, ocean, ember, gunmetal
    case ultraviolet, cyberpunk, acid, glacier, roseQuartz, copper, jade, monochrome

    var label: String { self == .roseQuartz ? "Rose Quartz" : rawValue.capitalized }

    @MainActor var palette: VisualizerPalette {
        let values: [UInt32]
        switch self {
        case .classic:
            return VisualizerPalette(
                colors: [.systemIndigo, .systemBlue, .systemOrange, .systemPink, .systemTeal, .systemMint],
                border: Self.color(0x213342),
                spectrum: [.systemGreen, .systemGreen, .systemYellow, .systemOrange, .systemRed],
                locations: [0, 0.55, 0.72, 0.84, 1]
            )
        case .aurora: values = [0x7868E6, 0x35BCD7, 0x3ECF9A, 0x8AD967, 0x7D9CF5, 0xD6FAEE]
        case .sunset: values = [0xEF6A5B, 0xFFAA5C, 0xE8609D, 0x9D78DB, 0xF6C55C, 0xFFE3C9]
        case .neon: values = [0x00D5E8, 0x9567F7, 0xA6D82D, 0xF45BA6, 0xF5D54D, 0xC6FFF8]
        case .ocean: values = [0x145C9E, 0x2586B8, 0x32B6C4, 0x75CEC8, 0xA0DCF1, 0xD9F5FF]
        case .ember: values = [0xB64C3C, 0xE17A32, 0xEF502E, 0xA9364F, 0xF2BA5D, 0xFFF0B8]
        case .gunmetal: values = [0x223B4A, 0x3A5E70, 0x527486, 0x7894A2, 0xA8BEC9, 0xD2E0E6]
        case .ultraviolet: values = [0x6324C9, 0x9A54F4, 0xDF4FDB, 0x6F70F8, 0xF48CCC, 0xEEDAFF]
        case .cyberpunk: values = [0xF52BAE, 0x793DDE, 0x00B9D1, 0xF1BE20, 0xFA5D37, 0xCAFFFA]
        case .acid: values = [0x7EB81D, 0xC1D919, 0x2CA76C, 0xD49B17, 0xE45238, 0xF2FFB9]
        case .glacier: values = [0x3D74A3, 0x7CB7D8, 0x91CCD3, 0xA9BEDD, 0xCAE5EB, 0xF1FCFF]
        case .roseQuartz: values = [0xB65A83, 0xDA91A7, 0x9B79BD, 0xCCB7D6, 0xD4A788, 0xFBE8E9]
        case .copper: values = [0x854B35, 0xC2784D, 0xBB955B, 0x5C8E84, 0xE0B77C, 0xF9E8D0]
        case .jade: values = [0x276B50, 0x4C9C72, 0x71BFA9, 0x5F8B9C, 0xB6C47A, 0xE9F4D4]
        case .monochrome: values = [0x354047, 0x626C73, 0x858E95, 0xA2A8AE, 0xCAD0D4, 0xF7FAFC]
        }
        let colors = values.map(Self.color)
        return VisualizerPalette(
            colors: colors,
            border: self == .gunmetal ? Self.color(0x213342) : (colors[4].blended(withFraction: 0.42, of: .black) ?? colors[4]),
            spectrum: [colors[0], colors[1], colors[2], colors[3], colors[5]],
            locations: [0, 0.30, 0.60, 0.84, 1]
        )
    }

    @MainActor private static func color(_ hex: UInt32) -> NSColor {
        NSColor(srgbRed: Double((hex >> 16) & 255) / 255,
                green: Double((hex >> 8) & 255) / 255,
                blue: Double(hex & 255) / 255, alpha: 1)
    }
}

@MainActor
struct VisualizerPalette {
    private let keyColors: [DrumKey: NSColor]
    let border: NSColor
    let spectrum: NSGradient?
    let ledColors: [NSColor]
    let haloColors: [NSColor]
    let radialColors: [NSColor]
    let orbitColors: [NSColor]
    let bladeColors: [NSColor]
    let radialGradient: NSGradient?

    init(colors: [NSColor], border: NSColor, spectrum: [NSColor], locations: [CGFloat]) {
        let keys: [DrumKey] = [.d, .f, .j, .k, .l, .space]
        keyColors = Dictionary(uniqueKeysWithValues: zip(keys, colors))
        self.border = border
        self.spectrum = locations.withUnsafeBufferPointer { points in
            NSGradient(colors: spectrum, atLocations: points.baseAddress, colorSpace: .sRGB)
        }
        let gradient = self.spectrum
        ledColors = (0..<16).map { gradient?.interpolatedColor(atLocation: CGFloat($0) / 15) ?? colors[0] }
        let keyColors = self.keyColors
        haloColors = Self.radialColors(for: RadialKeyMap.halo, keyColors: keyColors)
        radialColors = Self.radialColors(for: RadialKeyMap.spectrum, keyColors: keyColors)
        orbitColors = Self.radialColors(for: RadialKeyMap.orbits, keyColors: keyColors)
        bladeColors = Self.radialColors(for: RadialKeyMap.blades, keyColors: keyColors)
        let radialStops: [CGFloat] = [0, 0.18, 0.50, 0.82, 1]
        radialGradient = radialStops.withUnsafeBufferPointer { points in
            NSGradient(colors: [colors[2], colors[1], colors[0], colors[1], colors[3]],
                       atLocations: points.baseAddress, colorSpace: .sRGB)
        }
    }

    func color(for key: DrumKey) -> NSColor { keyColors[key] ?? .labelColor }

    private static func radialColors(for samples: [RadialKeyMap.Sample], keyColors: [DrumKey: NSColor]) -> [NSColor] {
        samples.map { sample in
            var tint: NSColor = .clear
            var accumulated = 0.0
            for influence in sample.influences where influence.weight > 0.0001 {
                let next = keyColors[influence.key] ?? .labelColor
                let fraction = influence.weight / (accumulated + influence.weight)
                tint = accumulated == 0 ? next : (tint.blended(withFraction: fraction, of: next) ?? next)
                accumulated += influence.weight
            }
            return tint
        }
    }
}
