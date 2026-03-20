import Foundation

protocol ClipboardRepositoryProtocol {
    func load() -> [ClipboardItem]
    func save(_ items: [ClipboardItem])
    func delete(_ item: ClipboardItem)
    func clear()
}
