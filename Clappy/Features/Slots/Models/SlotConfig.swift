import Foundation

enum SlotType: String, Codable, CaseIterable, Identifiable {
    case media
    case clipboard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .media: return "Media Player"
        case .clipboard: return "Clipboard"
        }
    }
}

struct SlotConfig: Codable, Equatable, Identifiable {
    let type: SlotType
    var isEnabled: Bool
    var order: Int

    var id: String { type.rawValue }
}
