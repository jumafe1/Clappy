import Foundation

final class UserDefaultsClipboardRepository: ClipboardRepositoryProtocol {
    private let key = "clappy.clipboard.items"
    private let maxItems = 20
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [ClipboardItem] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([ClipboardItem].self, from: data)) ?? []
    }

    func save(_ items: [ClipboardItem]) {
        let trimmed = Array(items.prefix(maxItems))
        if let data = try? JSONEncoder().encode(trimmed) {
            defaults.set(data, forKey: key)
        }
    }

    func delete(_ item: ClipboardItem) {
        var items = load()
        items.removeAll { $0.id == item.id }
        save(items)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
