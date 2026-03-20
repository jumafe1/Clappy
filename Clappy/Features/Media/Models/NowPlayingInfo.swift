import AppKit
import Foundation

struct NowPlayingInfo: Equatable {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var artwork: NSImage?
    var duration: TimeInterval = 0
    var elapsed: TimeInterval = 0
    var isPlaying: Bool = false

    var hasContent: Bool {
        !title.isEmpty
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(elapsed / duration, 1.0)
    }

    static func == (lhs: NowPlayingInfo, rhs: NowPlayingInfo) -> Bool {
        lhs.title == rhs.title
            && lhs.artist == rhs.artist
            && lhs.album == rhs.album
            && lhs.duration == rhs.duration
            && lhs.elapsed == rhs.elapsed
            && lhs.isPlaying == rhs.isPlaying
    }
}
