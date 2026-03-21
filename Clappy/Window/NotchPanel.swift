import AppKit

final class NotchPanel: NSPanel {

    /// Mirrors the expand/collapse state. When false (collapsed), the panel is fully
    /// transparent to mouse events so clicks pass through to apps beneath.
    var isExpanded: Bool = false {
        didSet { ignoresMouseEvents = !isExpanded }
    }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .statusBar + 1
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isMovable = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        acceptsMouseMovedEvents = true
        ignoresMouseEvents = true  // start collapsed — clicks pass through until expanded
    }
}
