import Combine
import Foundation

final class MediaViewModel: ObservableObject {
    @Published private(set) var nowPlaying = NowPlayingInfo()
    @Published private(set) var sourceCount: Int = 1

    private let mediaController: MediaController
    private var cancellables = Set<AnyCancellable>()

    init(mediaController: MediaController) {
        self.mediaController = mediaController

        mediaController.$nowPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: &$nowPlaying)

        mediaController.$activeSourceCount
            .receive(on: DispatchQueue.main)
            .assign(to: &$sourceCount)
    }

    func togglePlayPause() {
        mediaController.togglePlayPause()
    }

    func nextTrack() {
        mediaController.nextTrack()
    }

    func previousTrack() {
        mediaController.previousTrack()
    }
}
