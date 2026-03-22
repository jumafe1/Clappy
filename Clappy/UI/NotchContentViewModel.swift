import Combine
import Foundation

final class NotchContentViewModel: ObservableObject {
    @Published var isExpanded: Bool = false
    @Published var contentHeight: CGFloat = AnimationConstants.expandedHeight

    // MARK: - Tab State (persisted)

    private static let tabKey = "clappy.lastActiveTab"
    private var cancellables = Set<AnyCancellable>()

    @Published var activeTab: ClappyTab = {
        guard let raw = UserDefaults.standard.string(forKey: tabKey),
              let tab = ClappyTab(rawValue: raw) else { return .media }
        return tab
    }()

    init() {
        $activeTab
            .dropFirst()
            .sink { tab in
                UserDefaults.standard.set(tab.rawValue, forKey: Self.tabKey)
            }
            .store(in: &cancellables)
    }
}
