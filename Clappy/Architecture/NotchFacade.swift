import Foundation

final class NotchFacade {
    let mediaController: MediaController
    let clipboardManager: ClipboardManager
    let slotConfiguration: SlotConfiguration

    init(
        mediaController: MediaController,
        clipboardManager: ClipboardManager,
        slotConfiguration: SlotConfiguration
    ) {
        self.mediaController = mediaController
        self.clipboardManager = clipboardManager
        self.slotConfiguration = slotConfiguration
    }
}
