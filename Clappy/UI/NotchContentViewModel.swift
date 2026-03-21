import Combine
import Foundation

final class NotchContentViewModel: ObservableObject {
    @Published var isExpanded: Bool = false
    @Published var contentHeight: CGFloat = AnimationConstants.expandedHeight
}
