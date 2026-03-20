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
                        height: AnimationConstants.expandedHeight
                    )
                    .transition(.opacity)
            }
        }
        .frame(
            width: AnimationConstants.expandedWidth,
            height: AnimationConstants.expandedHeight,
            alignment: .top
        )
        .animation(AnimationConstants.spring, value: viewModel.isExpanded)
    }

    // MARK: - Computed Properties

    private var currentWidth: CGFloat {
        viewModel.isExpanded
            ? AnimationConstants.expandedWidth
            : AnimationConstants.collapsedWidth
    }

    private var currentHeight: CGFloat {
        viewModel.isExpanded
            ? AnimationConstants.expandedHeight
            : AnimationConstants.collapsedHeight
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
