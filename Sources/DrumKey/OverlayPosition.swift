import Foundation

/// Store a fraction of the available travel area so placement survives changes
/// to screen resolution, menu bar height and display arrangement.
struct OverlayPosition: Codable, Equatable, Sendable {
    private let horizontalFraction: Double
    private let verticalFraction: Double

    init(origin: CGPoint, windowSize: CGSize, visibleFrame: CGRect) {
        let width = max(0, visibleFrame.width - windowSize.width)
        let height = max(0, visibleFrame.height - windowSize.height)
        horizontalFraction = Self.bounded(width > 0 ? (origin.x - visibleFrame.minX) / width : 0)
        verticalFraction = Self.bounded(height > 0 ? (visibleFrame.maxY - windowSize.height - origin.y) / height : 0)
    }

    func origin(windowSize: CGSize, visibleFrame: CGRect) -> CGPoint {
        CGPoint(
            x: visibleFrame.minX + max(0, visibleFrame.width - windowSize.width) * Self.bounded(horizontalFraction),
            y: visibleFrame.maxY - windowSize.height - max(0, visibleFrame.height - windowSize.height) * Self.bounded(verticalFraction)
        )
    }

    private static func bounded(_ value: Double) -> Double {
        value.isFinite ? min(1, max(0, value)) : 0
    }
}
