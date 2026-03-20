import AppKit
import SwiftUI

final class NotchWindowController: NSWindowController {

    init<Content: View>(contentView: Content) {
        let panel = NotchPanel(
            contentRect: .zero,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(
            x: 0, y: 0,
            width: AnimationConstants.expandedWidth,
            height: AnimationConstants.expandedHeight
        )
        panel.contentView = hostingView

        super.init(window: panel)
        repositionPanel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    // MARK: - Positioning

    func repositionPanel() {
        guard let screen = NSScreen.main else { return }

        let notchRect = computeNotchRect(for: screen)
        let panelWidth = AnimationConstants.expandedWidth
        let panelHeight = AnimationConstants.expandedHeight

        // Center the panel on the notch horizontally
        let x = notchRect.midX - panelWidth / 2
        let y = screen.frame.maxY - panelHeight

        window?.setFrame(
            NSRect(x: x, y: y, width: panelWidth, height: panelHeight),
            display: true
        )
    }

    /// Compute the notch area using auxiliaryTopLeftArea and auxiliaryTopRightArea.
    /// The notch sits between the right edge of the left auxiliary area
    /// and the left edge of the right auxiliary area.
    private func computeNotchRect(for screen: NSScreen) -> NSRect {
        let safeAreaInsets = screen.safeAreaInsets

        if safeAreaInsets.top > 0,
           let leftArea = screen.auxiliaryTopLeftArea,
           let rightArea = screen.auxiliaryTopRightArea {
            // Notch is between the two auxiliary areas
            let notchX = leftArea.maxX
            let notchWidth = rightArea.minX - leftArea.maxX
            let notchY = screen.frame.maxY - safeAreaInsets.top
            let notchHeight = safeAreaInsets.top
            return NSRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight)
        }

        // Fallback for non-notch Macs: center top of screen
        let fallbackWidth: CGFloat = AnimationConstants.collapsedWidth
        let fallbackX = screen.frame.midX - fallbackWidth / 2
        let fallbackY = screen.frame.maxY
        return NSRect(x: fallbackX, y: fallbackY, width: fallbackWidth, height: 0)
    }

    /// Tight rect around the physical notch — used to trigger expansion from collapsed state.
    var notchTriggerRect: NSRect {
        guard let screen = NSScreen.main else { return .zero }
        let notchRect = computeNotchRect(for: screen)

        let expansionX: CGFloat = 5
        let expansionY: CGFloat = 2
        return notchRect.insetBy(dx: -expansionX, dy: -expansionY)
    }

    /// The full panel frame — used to detect when mouse leaves the expanded panel.
    var panelFrame: NSRect {
        window?.frame ?? .zero
    }
}
