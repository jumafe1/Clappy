import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Status Bar
    private var statusItem: NSStatusItem!

    // MARK: - Window Layer
    private var notchWindowController: NotchWindowController?
    private var hoverMonitor: NotchHoverMonitor?
    private var miniAlbumArtController: MiniAlbumArtController?

    // MARK: - View Models
    private let notchContentViewModel = NotchContentViewModel()

    // MARK: - Facade
    private var facade: NotchFacade?

    // MARK: - Subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupFacade()
        setupWindowLayer()
        setupHoverMonitor()
        observeScreenChanges()
    }

    func applicationWillTerminate(_ notification: Notification) {
        facade?.mediaController.stopListening()
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "rectangle.topthird.inset.filled",
                accessibilityDescription: "Clappy"
            )
        }

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
        )
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(title: "Quit Clappy", action: #selector(quitApp), keyEquivalent: "q")
        )
        statusItem.menu = menu
    }

    // MARK: - Facade

    private func setupFacade() {
        let mediaController = MediaController()
        let clipboardRepository = UserDefaultsClipboardRepository()
        let clipboardManager = ClipboardManager(repository: clipboardRepository)
        let slotConfiguration = SlotConfiguration()

        facade = NotchFacade(
            mediaController: mediaController,
            clipboardManager: clipboardManager,
            slotConfiguration: slotConfiguration
        )
    }

    // MARK: - Window Layer

    private func setupWindowLayer() {
        guard let facade = facade else { return }

        let mediaViewModel = MediaViewModel(mediaController: facade.mediaController)
        let clipboardViewModel = ClipboardViewModel(clipboardManager: facade.clipboardManager)
        let slotsViewModel = SlotsViewModel(slotConfiguration: facade.slotConfiguration)

        let contentView = NotchContentView(
            viewModel: notchContentViewModel,
            mediaViewModel: mediaViewModel,
            clipboardViewModel: clipboardViewModel,
            slotsViewModel: slotsViewModel
        )

        notchWindowController = NotchWindowController(contentView: contentView)
        notchWindowController?.showWindow(nil)

        if let controller = notchWindowController {
            miniAlbumArtController = MiniAlbumArtController(
                mediaViewModel: mediaViewModel,
                windowController: controller
            )
        }
    }

    // MARK: - Hover Monitor

    private func setupHoverMonitor() {
        guard let controller = notchWindowController else { return }

        hoverMonitor = NotchHoverMonitor(windowController: controller)
        hoverMonitor?.isHovering
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hovering in
                self?.notchContentViewModel.isExpanded = hovering
                (self?.notchWindowController?.window as? NotchPanel)?.isExpanded = hovering
            }
            .store(in: &cancellables)

        notchContentViewModel.$contentHeight
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height in
                self?.notchWindowController?.setContentHeight(height)
            }
            .store(in: &cancellables)
    }

    // MARK: - Screen Changes

    private func observeScreenChanges() {
        NotificationCenter.default.publisher(
            for: NSApplication.didChangeScreenParametersNotification
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.notchWindowController?.repositionPanel()
        }
        .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func openPreferences() {
        guard let facade = facade else { return }
        let preferencesViewModel = PreferencesViewModel(
            slotConfiguration: facade.slotConfiguration,
            hoverMonitor: hoverMonitor
        )
        let preferencesView = PreferencesView(viewModel: preferencesViewModel)
        let hostingController = NSHostingController(rootView: preferencesView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Clappy Preferences"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 400, height: 350))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
