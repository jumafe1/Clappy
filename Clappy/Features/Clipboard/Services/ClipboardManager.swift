import AppKit
import Combine
import Foundation

final class ClipboardManager: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    private let repository: ClipboardRepositoryProtocol
    private var pollTimer: Timer?
    private var lastChangeCount: Int

    init(repository: ClipboardRepositoryProtocol) {
        self.repository = repository
        self.lastChangeCount = NSPasteboard.general.changeCount
        self.items = repository.load()
        startPolling()
    }

    deinit {
        pollTimer?.invalidate()
    }

    // MARK: - Public

    func recopy(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if let text = item.text {
            pasteboard.setString(text, forType: .string)
        } else if let imageData = item.imageData {
            pasteboard.setData(imageData, forType: .tiff)
        }

        // Update change count so we don't re-capture our own paste
        lastChangeCount = pasteboard.changeCount
    }

    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        repository.save(items)
    }

    func clearAll() {
        items.removeAll()
        repository.clear()
    }

    // MARK: - Private

    private func startPolling() {
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Text
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            // Avoid duplicates
            if items.first?.text != text {
                let item = ClipboardItem(text: text)
                items.insert(item, at: 0)
                trimAndSave()
            }
            return
        }

        // Image
        if let imageData = pasteboard.data(forType: .tiff) {
            let downscaled = downscaleImageData(imageData)
            if items.first?.imageData != downscaled {
                let item = ClipboardItem(imageData: downscaled)
                items.insert(item, at: 0)
                trimAndSave()
            }
        }
    }

    private func trimAndSave() {
        if items.count > 20 {
            items = Array(items.prefix(20))
        }
        repository.save(items)
    }

    private func downscaleImageData(_ data: Data) -> Data {
        guard let image = NSImage(data: data) else { return data }
        let maxDimension: CGFloat = 256

        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return data }

        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = NSSize(width: size.width * scale, height: size.height * scale)

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()

        guard let tiffData = newImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
        else {
            return data
        }

        return jpegData
    }
}
