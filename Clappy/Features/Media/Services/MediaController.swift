import AppKit
import Combine
import Foundation

final class MediaController: ObservableObject {
    @Published private(set) var nowPlaying: NowPlayingInfo? = nil
    @Published private(set) var isToolInstalled: Bool = false
    @Published private(set) var adapterPath: String? = nil

    private var process: Process?
    private var monitorTask: Task<Void, Never>?
    private var restartCount = 0
    private let maxRestarts = 3

    private static let candidatePaths = [
        "/opt/homebrew/bin/media-control",   // Apple Silicon
        "/usr/local/bin/media-control"        // Intel
    ]

    init() {
        detectAdapter()
        if let path = adapterPath {
            startListening(path: path)
        }
    }

    deinit {
        stopListening()
    }

    // MARK: - Public Controls

    func togglePlayPause() { sendCommand("toggle-play-pause") }
    func nextTrack()       { sendCommand("next-track") }
    func previousTrack()   { sendCommand("previous-track") }

    func recheckInstallation() {
        detectAdapter()
        if let path = adapterPath, process == nil {
            restartCount = 0
            startListening(path: path)
        }
    }

    func stopListening() {
        monitorTask?.cancel()
        monitorTask = nil
        if let proc = process, proc.isRunning {
            proc.terminate()
        }
        process = nil
    }

    // MARK: - Private

    private func detectAdapter() {
        let found = Self.candidatePaths.first {
            FileManager.default.isExecutableFile(atPath: $0)
        }
        adapterPath = found
        isToolInstalled = found != nil
    }

    private func startListening(path: String) {
        stopListening()

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = ["stream", "--no-diff"]

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()

        proc.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.restartCount < self.maxRestarts else { return }
                guard self.process == nil else { return }
                self.restartCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    guard let self, let path = self.adapterPath else { return }
                    self.startListening(path: path)
                }
            }
        }

        do {
            try proc.run()
        } catch {
            print("[MediaController] Failed to launch media-control: \(error)")
            return
        }
        self.process = proc

        monitorTask = Task { [weak self] in
            let handle = pipe.fileHandleForReading
            do {
                for try await line in handle.bytes.lines {
                    guard !Task.isCancelled else { break }
                    await MainActor.run {
                        self?.handleEvent(line)
                    }
                }
            } catch {
                // Stream ended — terminationHandler will restart if needed
            }
        }
    }

    // MARK: - JSON Parsing
    // Stream format: {"type":"data","diff":bool,"payload":{...}}
    // Payload keys: title, artist, album, duration, elapsedTime, playing, playbackRate, artworkData, timestamp

    private func handleEvent(_ line: String) {
        guard
            let data = line.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let type = json["type"] as? String,
            type == "data",
            let payload = json["payload"] as? [String: Any]
        else { return }

        // Empty payload means no media
        guard let title = payload["title"] as? String, !title.isEmpty else {
            nowPlaying = nil
            return
        }

        let artwork: NSImage? = (payload["artworkData"] as? String)
            .flatMap { Data(base64Encoded: $0) }
            .flatMap { NSImage(data: $0) }

        let rate = payload["playbackRate"] as? Double ?? 0
        let playing = payload["playing"] as? Bool ?? (rate > 0)

        var info = NowPlayingInfo()
        info.title = title
        info.artist = payload["artist"] as? String ?? ""
        info.album = payload["album"] as? String ?? ""
        info.artwork = artwork
        info.duration = payload["duration"] as? Double ?? 0
        info.elapsed = payload["elapsedTime"] as? Double ?? 0
        info.playbackRate = rate
        info.isPlaying = playing
        info.lastUpdated = Date()

        nowPlaying = info
    }

    private func sendCommand(_ cmd: String) {
        guard let path = adapterPath else { return }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = [cmd]
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        try? proc.run()
    }
}
