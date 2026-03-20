import Combine
import Foundation

final class MediaViewModel: ObservableObject {
    @Published private(set) var nowPlaying: NowPlayingInfo? = nil
    @Published private(set) var isToolInstalled: Bool = false

    private let mediaController: MediaController
    private var cancellables = Set<AnyCancellable>()

    var progressFraction: Double {
        nowPlaying?.progress ?? 0
    }

    init(mediaController: MediaController) {
        self.mediaController = mediaController

        mediaController.$nowPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: &$nowPlaying)

        mediaController.$isToolInstalled
            .receive(on: DispatchQueue.main)
            .assign(to: &$isToolInstalled)
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

    func recheckInstallation() {
        mediaController.recheckInstallation()
    }
}
