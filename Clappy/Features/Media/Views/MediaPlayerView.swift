import SwiftUI

struct MediaPlayerView: View {
    @ObservedObject var viewModel: MediaViewModel

    private var isCompact: Bool { viewModel.sourceCount > 1 }

    var body: some View {
        Group {
            if isCompact {
                compactLayout
            } else {
                expandedLayout
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: viewModel.sourceCount)
    }

    // MARK: - Expanded Layout (single source)

    private var expandedLayout: some View {
        HStack(spacing: 12) {
            artworkView
                .frame(width: 80, height: 80)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                if viewModel.nowPlaying.hasContent {
                    MarqueeText(text: viewModel.nowPlaying.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .accessibilityLabel("Track: \(viewModel.nowPlaying.title)")

                    Text(viewModel.nowPlaying.artist)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                        .accessibilityLabel("Artist: \(viewModel.nowPlaying.artist)")
                } else {
                    Text("No media playing")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer(minLength: 2)

                progressBar

                expandedControls
            }
        }
        .padding(8)
    }

    // MARK: - Compact Layout (multiple sources)

    private var compactLayout: some View {
        HStack(spacing: 8) {
            artworkView
                .frame(width: 36, height: 36)
                .cornerRadius(4)

            Text(viewModel.nowPlaying.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            compactControls
        }
        .frame(height: 48)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Artwork

    @ViewBuilder
    private var artworkView: some View {
        if let artwork = viewModel.nowPlaying.artwork {
            Image(nsImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .accessibilityLabel("Album artwork")
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.3))
                )
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 3)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.8))
                    .frame(
                        width: geometry.size.width * viewModel.nowPlaying.progress,
                        height: 3
                    )
            }
        }
        .frame(height: 3)
        .accessibilityValue("\(Int(viewModel.nowPlaying.progress * 100))% played")
    }

    // MARK: - Expanded Controls (prev + play/pause + next)

    private var expandedControls: some View {
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
                Image(systemName: viewModel.nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.nowPlaying.isPlaying ? "Pause" : "Play")

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

    // MARK: - Compact Controls (play/pause + next only)

    private var compactControls: some View {
        HStack(spacing: 12) {
            Button(action: viewModel.togglePlayPause) {
                Image(systemName: viewModel.nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.nowPlaying.isPlaying ? "Pause" : "Play")

            Button(action: viewModel.nextTrack) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next track")
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
