import SwiftUI

struct MediaPlayerView: View {
    @ObservedObject var viewModel: MediaViewModel

    var body: some View {
        Group {
            if !viewModel.isToolInstalled {
                notInstalledView
            } else if let info = viewModel.nowPlaying {
                playerView(info: info)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            // When installed but nothing playing: show nothing
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.nowPlaying != nil)
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

    // MARK: - Player

    private func playerView(info: NowPlayingInfo) -> some View {
        HStack(spacing: 12) {
            artworkView(artwork: info.artwork)
                .frame(width: 80, height: 80)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                MarqueeText(text: info.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .accessibilityLabel("Track: \(info.title)")

                Text(artistAlbumText(info: info))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                    .accessibilityLabel("Artist: \(info.artist)")

                Spacer(minLength: 2)

                progressBar(fraction: info.progress)

                controlButtons(isPlaying: info.isPlaying)
            }
        }
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

// MARK: - Marquee Text

struct MarqueeText: View {
    let text: String
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let needsScroll = textWidth > geometry.size.width

            Text(text)
                .lineLimit(1)
                .fixedSize()
                .background(
                    GeometryReader { textGeometry in
                        Color.clear.onAppear {
                            textWidth = textGeometry.size.width
                            containerWidth = geometry.size.width
                        }
                    }
                )
                .offset(x: needsScroll ? offset : 0)
                .onAppear {
                    guard needsScroll else { return }
                    startAnimation()
                }
                .onChange(of: text) {
                    offset = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        startAnimation()
                    }
                }
        }
        .clipped()
        .frame(height: 16)
    }

    private func startAnimation() {
        guard textWidth > containerWidth else { return }
        let distance = textWidth - containerWidth
        withAnimation(
            .linear(duration: Double(distance) / 30)
            .delay(1)
            .repeatForever(autoreverses: true)
        ) {
            offset = -distance
        }
    }
}
