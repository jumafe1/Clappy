import Combine
import Foundation

final class SlotConfiguration: ObservableObject {
    @Published var slots: [SlotConfig]

    private let key = "clappy.slots.config"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: key),
           let saved = try? JSONDecoder().decode([SlotConfig].self, from: data) {
            self.slots = saved
        } else {
            // Default slot order
            self.slots = [
                SlotConfig(type: .media, isEnabled: true, order: 0),
                SlotConfig(type: .clipboard, isEnabled: true, order: 1),
            ]
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(slots) {
            defaults.set(data, forKey: key)
        }
    }

    func moveSlot(from source: IndexSet, to destination: Int) {
        slots.move(fromOffsets: source, toOffset: destination)
        reindex()
        save()
    }

    func toggleSlot(_ slot: SlotConfig) {
        guard let index = slots.firstIndex(where: { $0.type == slot.type }) else { return }
        slots[index].isEnabled.toggle()
        save()
    }

    var enabledSlots: [SlotConfig] {
        slots.filter(\.isEnabled).sorted { $0.order < $1.order }
    }

    private func reindex() {
        for i in slots.indices {
            slots[i].order = i
        }
    }
}
