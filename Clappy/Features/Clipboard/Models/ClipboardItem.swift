import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String?
    var imageData: Data?
    let timestamp: Date

    init(id: UUID = UUID(), text: String? = nil, imageData: Data? = nil, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.imageData = imageData
        self.timestamp = timestamp
    }

    var displayText: String {
        if let text, !text.isEmpty {
            return text
        }
        if imageData != nil {
            return "[Image]"
        }
        return "[Empty]"
    }

    var preview: String {
        let full = displayText
        if full.count > 80 {
            return String(full.prefix(80)) + "…"
        }
        return full
    }
}
