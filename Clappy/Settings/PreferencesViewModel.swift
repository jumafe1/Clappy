import Combine
import Foundation

final class PreferencesViewModel: ObservableObject {
    @Published var triggerMode: NotchHoverMonitor.TriggerMode {
        didSet {
            hoverMonitor?.triggerMode = triggerMode
            UserDefaults.standard.set(triggerMode.rawValue, forKey: triggerModeKey)
        }
    }
    @Published var slots: [SlotConfig]

    private let slotConfiguration: SlotConfiguration
    private weak var hoverMonitor: NotchHoverMonitor?
    private let triggerModeKey = "clappy.triggerMode"
    private var cancellables = Set<AnyCancellable>()

    init(slotConfiguration: SlotConfiguration, hoverMonitor: NotchHoverMonitor?) {
        self.slotConfiguration = slotConfiguration
        self.hoverMonitor = hoverMonitor
        self.slots = slotConfiguration.slots

        // Load saved trigger mode
        if let saved = UserDefaults.standard.string(forKey: triggerModeKey),
           let mode = NotchHoverMonitor.TriggerMode(rawValue: saved) {
            self.triggerMode = mode
            hoverMonitor?.triggerMode = mode
        } else {
            self.triggerMode = .hover
        }

        slotConfiguration.$slots
            .receive(on: DispatchQueue.main)
            .assign(to: &$slots)
    }

    func moveSlot(from source: IndexSet, to destination: Int) {
        slotConfiguration.moveSlot(from: source, to: destination)
    }

    func toggleSlot(_ slot: SlotConfig) {
        slotConfiguration.toggleSlot(slot)
    }
}
