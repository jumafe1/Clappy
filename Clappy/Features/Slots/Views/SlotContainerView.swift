import SwiftUI

struct SlotContainerView: View {
    @ObservedObject var slotsViewModel: SlotsViewModel
    @ObservedObject var mediaViewModel: MediaViewModel
    @ObservedObject var clipboardViewModel: ClipboardViewModel

    var body: some View {
        VStack(spacing: 8) {
            ForEach(slotsViewModel.enabledSlots) { slot in
                slotView(for: slot.type)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: mediaViewModel.nowPlaying.hasContent)
    }

    @ViewBuilder
    private func slotView(for type: SlotType) -> some View {
        switch type {
        case .media:
            if mediaViewModel.nowPlaying.hasContent {
                MediaPlayerView(viewModel: mediaViewModel)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        case .clipboard:
            ClipboardView(viewModel: clipboardViewModel)
        }
    }
}
