import AppKit
import Combine
import SwiftUI

// MARK: - Shared State

final class MiniArtState: ObservableObject {
    @Published var artwork: NSImage? = nil
    @Published var isVisible: Bool = false
}

// MARK: - SwiftUI View

private struct MiniArtView: View {
    @ObservedObject var state: MiniArtState

    private let size: CGFloat = 28

    var body: some View {
        ZStack {
            if state.isVisible {
                artworkContent
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.isVisible)
    }

    @ViewBuilder
    private var artworkContent: some View {
        if let artwork = state.artwork {
            Image(nsImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.15))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                )
        }
    }
}

// MARK: - Controller

final class MiniAlbumArtController {

    private let artState = MiniArtState()
    private var panel: NSPanel?
    private var cancellables = Set<AnyCancellable>()
    private weak var notchWindowController: NotchWindowController?

    private let artworkDisplaySize: CGFloat = 28
    private let artworkRenderSize: CGFloat = 56  // 2× for Retina

    init(mediaViewModel: MediaViewModel, windowController: NotchWindowController) {
        self.notchWindowController = windowController
        setupPanel()
        observeMedia(mediaViewModel)
    }

    // MARK: - Panel Setup

    private func setupPanel() {
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: artworkDisplaySize, height: artworkDisplaySize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = false
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        p.isMovable = false
        p.ignoresMouseEvents = true

        let hostingView = NSHostingView(rootView: MiniArtView(state: artState))
        hostingView.frame = NSRect(x: 0, y: 0, width: artworkDisplaySize, height: artworkDisplaySize)
        p.contentView = hostingView

        panel = p
        reposition()
        p.orderFront(nil)
    }

    // MARK: - Observation

    private func observeMedia(_ vm: MediaViewModel) {
        vm.$nowPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                guard let self else { return }
                let playing = info?.isPlaying == true
                if playing, let artwork = info?.artwork {
                    self.artState.artwork = self.downscale(artwork, to: self.artworkRenderSize)
                } else if playing {
                    self.artState.artwork = nil  // playing but no artwork — show fallback icon
                }
                self.artState.isVisible = playing
            }
            .store(in: &cancellables)
    }

    // MARK: - Positioning

    private func reposition() {
        guard let panel,
              let screen = NSScreen.main,
              let notchController = notchWindowController else { return }

        let notchRect = notchController.notchTriggerRect
        let gap: CGFloat = 6
        let x = notchRect.minX - artworkDisplaySize - gap
        let y = screen.frame.maxY - artworkDisplaySize

        panel.setFrame(
            NSRect(x: x, y: y, width: artworkDisplaySize, height: artworkDisplaySize),
            display: true
        )
    }

    // MARK: - Downscale

    private func downscale(_ image: NSImage, to size: CGFloat) -> NSImage {
        let newSize = NSSize(width: size, height: size)
        let result = NSImage(size: newSize)
        result.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )
        result.unlockFocus()
        return result
    }
}
