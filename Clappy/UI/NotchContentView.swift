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

    /// Panel height = fixed chrome (padding + compact header) + active tab content height.
    private var computedContentHeight: CGFloat {
        let chrome = AnimationConstants.panelVerticalPadding
            + AnimationConstants.headerRowHeight
            + AnimationConstants.headerSeparatorHeight
            + AnimationConstants.headerBottomGap

        let enabledTypes = Set(slotsViewModel.enabledSlots.map { $0.type })
        let contentH: CGFloat

        switch viewModel.activeTab {
        case .media:
            let mediaEnabled = enabledTypes.contains(.media)
            let mediaVisible = mediaEnabled
                && (!mediaViewModel.isToolInstalled || mediaViewModel.nowPlaying != nil)
            contentH = mediaVisible ? AnimationConstants.mediaPlayerHeight : 0

        case .clipboard:
            let clipEnabled = enabledTypes.contains(.clipboard)
            if clipEnabled {
                if clipboardViewModel.items.isEmpty {
                    contentH = AnimationConstants.clipboardEmptyStateHeight
                } else {
                    let rows = min(clipboardViewModel.items.count, AnimationConstants.maxClipboardRows)
                    contentH = AnimationConstants.clipboardHeaderHeight
                        + CGFloat(rows) * AnimationConstants.clipboardRowHeight
                }
            } else {
                contentH = 0
            }
        }

        return min(chrome + contentH, AnimationConstants.maxPanelHeight)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Compact header: "Clappy" label + tab icons + thin separator
            CompactHeaderView(activeTab: $viewModel.activeTab)
                .padding(.bottom, AnimationConstants.headerBottomGap)

            // Active tab content
            Group {
                switch viewModel.activeTab {
                case .media:
                    MediaPlayerView(viewModel: mediaViewModel)
                case .clipboard:
                    ClipboardView(viewModel: clipboardViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(AnimationConstants.contentPadding)
        .padding(.top, AnimationConstants.collapsedHeight - 8)
    }
}
