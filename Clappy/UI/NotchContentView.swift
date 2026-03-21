import SwiftUI

struct NotchContentView: View {
    @ObservedObject var viewModel: NotchContentViewModel
    @ObservedObject var mediaViewModel: MediaViewModel
    @ObservedObject var clipboardViewModel: ClipboardViewModel
    @ObservedObject var slotsViewModel: SlotsViewModel

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            PanelBackground()
                .frame(
                    width: currentWidth,
                    height: currentHeight
                )

            // Content
            if viewModel.isExpanded {
                expandedContent
                    .frame(
                        width: AnimationConstants.expandedWidth,
                        height: currentHeight
                    )
                    .transition(.opacity)
            }
        }
        .frame(
            width: AnimationConstants.expandedWidth,
            height: currentHeight,
            alignment: .top
        )
        .animation(AnimationConstants.spring, value: viewModel.isExpanded)
        .animation(AnimationConstants.spring, value: currentHeight)
        .onAppear { viewModel.contentHeight = currentHeight }
        .onChange(of: currentHeight) { _, h in viewModel.contentHeight = h }
    }

    // MARK: - Computed Properties

    private var currentWidth: CGFloat {
        viewModel.isExpanded
            ? AnimationConstants.expandedWidth
            : AnimationConstants.collapsedWidth
    }

    private var currentHeight: CGFloat {
        viewModel.isExpanded ? computedContentHeight : AnimationConstants.collapsedHeight
    }

    /// Computes the panel height based on which slots are visible and how much content they have.
    private var computedContentHeight: CGFloat {
        let enabledTypes = Set(slotsViewModel.enabledSlots.map { $0.type })
        let mediaEnabled = enabledTypes.contains(.media)
        let clipboardEnabled = enabledTypes.contains(.clipboard)

        let mediaIsVisible = mediaEnabled && (!mediaViewModel.isToolInstalled || mediaViewModel.nowPlaying != nil)
        let clipboardHasItems = clipboardEnabled && !clipboardViewModel.items.isEmpty

        var height = AnimationConstants.panelVerticalPadding

        if mediaIsVisible {
            height += AnimationConstants.mediaPlayerHeight
        }

        if clipboardHasItems {
            height += AnimationConstants.clipboardHeaderHeight
            let rows = min(clipboardViewModel.items.count, AnimationConstants.maxClipboardRows)
            height += CGFloat(rows) * AnimationConstants.clipboardRowHeight
        }

        // If nothing is visible, keep the notch pill size
        if height <= AnimationConstants.panelVerticalPadding {
            return AnimationConstants.collapsedHeight
        }

        return min(height, AnimationConstants.maxPanelHeight)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        SlotContainerView(
            slotsViewModel: slotsViewModel,
            mediaViewModel: mediaViewModel,
            clipboardViewModel: clipboardViewModel
        )
        .padding(AnimationConstants.contentPadding)
        .padding(.top, AnimationConstants.collapsedHeight - 8)
    }
}
