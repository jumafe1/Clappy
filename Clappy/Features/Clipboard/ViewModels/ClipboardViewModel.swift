import Combine
import Foundation

final class ClipboardViewModel: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    private let clipboardManager: ClipboardManager
    private var cancellables = Set<AnyCancellable>()

    init(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager

        clipboardManager.$items
            .receive(on: DispatchQueue.main)
            .assign(to: &$items)
    }

    func recopy(_ item: ClipboardItem) {
        clipboardManager.recopy(item)
    }

    func delete(_ item: ClipboardItem) {
        clipboardManager.deleteItem(item)
    }

    func clearAll() {
        clipboardManager.clearAll()
    }
}
