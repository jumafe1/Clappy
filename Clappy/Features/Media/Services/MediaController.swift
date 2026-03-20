import AppKit
import Combine
import Foundation

final class MediaController: ObservableObject {
    @Published private(set) var nowPlaying = NowPlayingInfo()

    // MARK: - MediaRemote Function Types
    private typealias MRNowPlayingInfoGetterBlock = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias MRSendCommandBlock = @convention(c) (UInt32, UnsafeRawPointer?) -> Bool
    private typealias MRRegisterNotificationsBlock = @convention(c) (DispatchQueue) -> Void

    // MARK: - MediaRemote Functions
    private var mrGetNowPlayingInfo: MRNowPlayingInfoGetterBlock?
    private var mrSendCommand: MRSendCommandBlock?
    private var mrRegisterNotifications: MRRegisterNotificationsBlock?

    // MARK: - Active Sources (Fix 7)
    @Published private(set) var activeSourceCount: Int = 1
    private var activeSources = Set<String>()

    // MARK: - State
    private var pollTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var isLoaded = false

    // MARK: - MediaRemote Commands
    private enum Command: UInt32 {
        case togglePlayPause = 2
        case nextTrack = 4
        case previousTrack = 5
    }

    init() {
        loadMediaRemote()
        if isLoaded {
            registerNotifications()
            startPolling()
            fetchNowPlayingInfo()
        }
    }

    deinit {
        pollTimer?.invalidate()
    }

    // MARK: - Public Controls

    func togglePlayPause() {
        sendCommand(.togglePlayPause)
    }

    func nextTrack() {
        sendCommand(.nextTrack)
    }

    func previousTrack() {
        sendCommand(.previousTrack)
    }

    // MARK: - Private

    private func loadMediaRemote() {
        let path = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, URL(fileURLWithPath: path) as CFURL) else {
            return
        }

        mrGetNowPlayingInfo = loadFunction(bundle: bundle, name: "MRMediaRemoteGetNowPlayingInfo")
        mrSendCommand = loadFunction(bundle: bundle, name: "MRMediaRemoteSendCommand")
        mrRegisterNotifications = loadFunction(bundle: bundle, name: "MRMediaRemoteRegisterForNowPlayingNotifications")

        isLoaded = mrGetNowPlayingInfo != nil
    }

    private func loadFunction<T>(bundle: CFBundle, name: String) -> T? {
        guard let pointer = CFBundleGetFunctionPointerForName(bundle, name as CFString) else {
            return nil
        }
        return unsafeBitCast(pointer, to: T.self)
    }

    private func registerNotifications() {
        mrRegisterNotifications?(DispatchQueue.main)

        // MediaRemote posts to DistributedNotificationCenter, not NotificationCenter.default
        DistributedNotificationCenter.default().publisher(
            for: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification")
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.fetchNowPlayingInfo()
        }
        .store(in: &cancellables)

        DistributedNotificationCenter.default().publisher(
            for: NSNotification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification")
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.fetchNowPlayingInfo()
        }
        .store(in: &cancellables)

        // App-specific distributed notifications
        DistributedNotificationCenter.default().publisher(
            for: NSNotification.Name("com.apple.Music.playerInfo")
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .sink { [weak self] notification in
            self?.handleAppNotification(notification, appName: "Music")
        }
        .store(in: &cancellables)

        DistributedNotificationCenter.default().publisher(
            for: NSNotification.Name("com.spotify.client.PlaybackStateChanged")
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .sink { [weak self] notification in
            self?.handleAppNotification(notification, appName: "Spotify")
        }
        .store(in: &cancellables)
    }

    private func handleAppNotification(_ notification: Notification, appName: String) {
        // Track active sources based on play/pause state
        let playerState = notification.userInfo?["Player State"] as? String
            ?? notification.userInfo?["playbackState"] as? String
            ?? ""

        if playerState.lowercased().contains("play") {
            activeSources.insert(appName)
        } else if playerState.lowercased().contains("pause") || playerState.lowercased().contains("stop") {
            activeSources.remove(appName)
        }
        activeSourceCount = max(1, activeSources.count)

        fetchNowPlayingInfo()
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            // Adaptive polling: skip if we already have content
            if !self.nowPlaying.hasContent {
                self.fetchNowPlayingInfo()
            }
        }
    }

    private func fetchNowPlayingInfo() {
        mrGetNowPlayingInfo?(DispatchQueue.main) { [weak self] info in
            guard let self else { return }

            var newInfo = NowPlayingInfo()
            newInfo.title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
            newInfo.artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
            newInfo.album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
            newInfo.duration = info["kMRMediaRemoteNowPlayingInfoDuration"] as? TimeInterval ?? 0
            newInfo.elapsed = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? TimeInterval ?? 0
            newInfo.isPlaying = (info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0) > 0

            if let artworkData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                newInfo.artwork = NSImage(data: artworkData)
            }

            self.nowPlaying = newInfo
        }
    }

    private func sendCommand(_ command: Command) {
        _ = mrSendCommand?(command.rawValue, nil)
        // Refresh state after a short delay to pick up the change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.fetchNowPlayingInfo()
        }
    }
}
