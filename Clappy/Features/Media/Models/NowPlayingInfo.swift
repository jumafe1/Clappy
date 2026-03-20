import AppKit
import Foundation

struct NowPlayingInfo: Equatable {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var artwork: NSImage?
    var duration: TimeInterval = 0
    var elapsed: TimeInterval = 0
    var playbackRate: Double = 0
    var isPlaying: Bool = false
    var lastUpdated: Date = .distantPast

    var hasContent: Bool {
        !title.isEmpty
    }

    /// Live elapsed time computed from playback rate and last update timestamp.
    var currentElapsed: TimeInterval {
        let delta = Date().timeIntervalSince(lastUpdated) * playbackRate
        return min(elapsed + delta, max(duration, 0))
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(currentElapsed / duration, 1.0)
    }

    static func == (lhs: NowPlayingInfo, rhs: NowPlayingInfo) -> Bool {
        lhs.title == rhs.title
            && lhs.artist == rhs.artist
            && lhs.album == rhs.album
            && lhs.duration == rhs.duration
            && lhs.elapsed == rhs.elapsed
            && lhs.playbackRate == rhs.playbackRate
            && lhs.isPlaying == rhs.isPlaying
    }
}
