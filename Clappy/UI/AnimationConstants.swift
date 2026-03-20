import SwiftUI

enum AnimationConstants {
    // MARK: - Spring Animation
    static let springResponse: Double = 0.35
    static let springDamping: Double = 0.72
    static var spring: Animation {
        .spring(response: springResponse, dampingFraction: springDamping)
    }

    // MARK: - Collapsed Size (matches notch area)
    static let collapsedWidth: CGFloat = 200
    static let collapsedHeight: CGFloat = 32

    // MARK: - Expanded Size
    static let expandedWidth: CGFloat = 420
    static let expandedHeight: CGFloat = 280

    // MARK: - Corner Radius
    static let cornerRadius: CGFloat = 16

    // MARK: - Padding
    static let contentPadding: CGFloat = 12
}
