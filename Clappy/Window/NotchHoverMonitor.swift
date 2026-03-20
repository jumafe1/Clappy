import AppKit
import Combine

final class NotchHoverMonitor {
    enum TriggerMode: String, CaseIterable, Identifiable {
        case hover
        case click
        case both

        var id: String { rawValue }
    }

    // MARK: - Published State
    let isHovering = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Configuration
    var triggerMode: TriggerMode = .hover

    // MARK: - Private
    private weak var windowController: NotchWindowController?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isMouseInPanel = false

    init(windowController: NotchWindowController) {
        self.windowController = windowController
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        // Global monitor for mouse movement everywhere
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDown]
        ) { [weak self] event in
            self?.handleEvent(event)
        }

        // Local monitor for events within our own window
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .mouseEntered, .mouseExited, .leftMouseDown]
        ) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
    }

    private func stopMonitoring() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }

    private func handleEvent(_ event: NSEvent) {
        guard let windowController else { return }

        let mouseLocation = NSEvent.mouseLocation
        let triggerRect = windowController.notchTriggerRect
        let panelFrame = windowController.panelFrame
        let isInTrigger = triggerRect.contains(mouseLocation)
        let isInPanel = panelFrame.contains(mouseLocation)
        let isExpanded = isHovering.value

        switch triggerMode {
        case .hover:
            if !isExpanded {
                // Collapsed: only expand when mouse is right on the notch
                if isInTrigger {
                    isHovering.send(true)
                }
            } else {
                // Expanded: collapse when mouse leaves the full panel
                if !isInPanel {
                    isHovering.send(false)
                }
            }

        case .click:
            if event.type == .leftMouseDown {
                if isInTrigger && !isExpanded {
                    isHovering.send(true)
                } else if !isInPanel && isExpanded {
                    isHovering.send(false)
                }
            }

        case .both:
            if event.type == .leftMouseDown {
                if isInTrigger && !isExpanded {
                    isHovering.send(true)
                    return
                } else if !isInPanel && isExpanded {
                    isHovering.send(false)
                    return
                }
            }
            // Hover logic with two-rect approach
            if !isExpanded {
                if isInTrigger {
                    isHovering.send(true)
                }
            } else {
                if !isInPanel {
                    isHovering.send(false)
                }
            }
        }
    }
}
