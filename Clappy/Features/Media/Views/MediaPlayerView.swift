import SwiftUI

struct MediaPlayerView: View {
    @ObservedObject var viewModel: MediaViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Media")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }

            Group {
                if !viewModel.isToolInstalled {
                    notInstalledView
                } else if let info = viewModel.nowPlaying {
                    playerView(info: info)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    nothingPlayingView
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.nowPlaying != nil)
        }
    }

    // MARK: - Not Installed

    private var notInstalledView: some View {
        VStack(spacing: 8) {
            Text("Media detection requires media-control")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Text("brew install ungive/tap/media-control")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .cornerRadius(4)
                .textSelection(.enabled)

            Button(action: viewModel.recheckInstallation) {
                Text("Check Again")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
    }

    // MARK: - Nothing Playing

    private var nothingPlayingView: some View {
        Text("No media playing")
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.4))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
    }

    // MARK: - Player

    private func playerView(info: NowPlayingInfo) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            artworkView(artwork: info.artwork)
                .frame(width: 72, height: 72)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Spacer(minLength: 0)

                ScrollingTextView(text: info.title, font: .system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .accessibilityLabel("Track: \(info.title)")

                ScrollingTextView(text: artistAlbumText(info: info), font: .system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                    .accessibilityLabel("Artist: \(info.artist)")

                progressBar(fraction: info.progress)

                controlButtons(isPlaying: info.isPlaying)
            }
            .frame(maxHeight: .infinity)

            Spacer()
        }
        .frame(height: 72)
        .padding(8)
    }

    private func artistAlbumText(info: NowPlayingInfo) -> String {
        if !info.album.isEmpty {
            return "\(info.artist) – \(info.album)"
        }
        return info.artist
    }

    // MARK: - Artwork

    @ViewBuilder
    private func artworkView(artwork: NSImage?) -> some View {
        if let artwork {
            Image(nsImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .accessibilityLabel("Album artwork")
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.3))
                )
        }
    }

    // MARK: - Progress Bar

    private func progressBar(fraction: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 3)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.8))
                    .frame(
                        width: geometry.size.width * fraction,
                        height: 3
                    )
            }
        }
        .frame(height: 3)
        .accessibilityValue("\(Int(fraction * 100))% played")
    }

    // MARK: - Controls

    private func controlButtons(isPlaying: Bool) -> some View {
        HStack(spacing: 20) {
            Spacer()

            Button(action: viewModel.previousTrack) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous track")

            Button(action: viewModel.togglePlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? "Pause" : "Play")

            Button(action: viewModel.nextTrack) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next track")

            Spacer()
        }
    }
}
