import SwiftUI

enum AnimationConstants {
    // MARK: - Spring Animation
    static let springResponse: Double = 0.35
    static let springDamping: Double = 0.72
    static var spring: Animation {
        .spring(response: springResponse, dampingFraction: springDamping)
    }

    // MARK: - Collapsed Size (matches notch area)
    static let collapsedWidth: CGFloat = 179
    static let collapsedHeight: CGFloat = 32

    // MARK: - Expanded Size
    static let expandedWidth: CGFloat = 400
    static let expandedHeight: CGFloat = 280

    // MARK: - Corner Radius
    static let cornerRadius: CGFloat = 16

    // MARK: - Padding
    static let contentPadding: CGFloat = 12

    // MARK: - Dynamic Panel Heights
    static let maxPanelHeight: CGFloat = 216
    static let mediaPlayerHeight: CGFloat = 120
    static let clipboardHeaderHeight: CGFloat = 32
    static let clipboardRowHeight: CGFloat = 44
    static let clipboardEmptyStateHeight: CGFloat = 40
    static let maxClipboardRows: Int = 3
    // Total vertical padding consumed by expandedContent (.padding(contentPadding) + .padding(.top, collapsedHeight - 8))
    static let panelVerticalPadding: CGFloat = contentPadding * 2 + (collapsedHeight - 8)

    // MARK: - Compact Header Layout
    static let headerRowHeight: CGFloat = 28
    static let headerSeparatorHeight: CGFloat = 1
    static let headerBottomGap: CGFloat = 6
    static let tabIconSize: CGFloat = 12
    static let tabIconPadding: CGFloat = 5
    static let tabIconSpacing: CGFloat = 4
    static let tabPillCornerRadius: CGFloat = 6
    static let headerLabelOpacity: Double = 0.40
    static let tabActiveOpacity: Double = 1.0
    static let tabInactiveOpacity: Double = 0.35
    static let headerDividerOpacity: Double = 0.12
}
