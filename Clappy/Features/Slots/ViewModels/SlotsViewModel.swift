import Combine
import Foundation

final class SlotsViewModel: ObservableObject {
    @Published var enabledSlots: [SlotConfig] = []

    private let slotConfiguration: SlotConfiguration
    private var cancellables = Set<AnyCancellable>()

    init(slotConfiguration: SlotConfiguration) {
        self.slotConfiguration = slotConfiguration

        slotConfiguration.$slots
            .map { $0.filter(\.isEnabled).sorted { $0.order < $1.order } }
            .receive(on: DispatchQueue.main)
            .assign(to: &$enabledSlots)
    }
}
