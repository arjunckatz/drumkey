import Foundation

enum OverlayScale: Double, CaseIterable {
    case one = 1
    case onePointFive = 1.5
    case two = 2
    case three = 3

    static let baseSize = CGSize(width: 192, height: 252)

    var label: String {
        switch self {
        case .one: "1×"
        case .onePointFive: "1.5×"
        case .two: "2×"
        case .three: "3×"
        }
    }

    func size(fitting available: CGSize) -> CGSize {
        let fit = min(available.width / Self.baseSize.width, available.height / Self.baseSize.height)
        let scale = max(0.1, min(rawValue, fit))
        return CGSize(width: Self.baseSize.width * scale, height: Self.baseSize.height * scale)
    }
}
