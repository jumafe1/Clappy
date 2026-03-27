import SwiftUI

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ClipboardView: View {
    @ObservedObject var viewModel: ClipboardViewModel
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var containerHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Text("Clipboard")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if !viewModel.items.isEmpty {
                    Button(action: viewModel.clearAll) {
                        Text("Clear")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear clipboard history")
                }
            }

            // Items
            if viewModel.items.isEmpty {
                Text("No clipboard history")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                scrollableList
            }
        }
    }

    // MARK: - Scrollable List with Thin Indicator

    private var scrollableList: some View {
        GeometryReader { containerGeo in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 2) {
                    ForEach(viewModel.items) { item in
                        clipboardRow(item)
                    }
                }
                .background(
                    GeometryReader { contentGeo in
                        Color.clear
                            .preference(key: ScrollOffsetKey.self,
                                        value: contentGeo.frame(in: .named("clipScroll")).minY)
                            .preference(key: ContentHeightKey.self,
                                        value: contentGeo.size.height)
                    }
                )
            }
            .coordinateSpace(name: "clipScroll")
            .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
            .onPreferenceChange(ContentHeightKey.self) { contentHeight = $0 }
            .onAppear { containerHeight = containerGeo.size.height }
            .onChange(of: containerGeo.size.height) { _, newValue in containerHeight = newValue }
            .overlay(alignment: .trailing) {
                scrollIndicator
            }
        }
    }

    @ViewBuilder
    private var scrollIndicator: some View {
        if contentHeight > containerHeight, containerHeight > 0 {
            let scrollableRange = contentHeight - containerHeight
            let fraction = scrollableRange > 0 ? min(max(-scrollOffset / scrollableRange, 0), 1) : 0
            let indicatorHeight = max(containerHeight * (containerHeight / contentHeight), 20)
            let trackHeight = containerHeight - indicatorHeight
            let yOffset = trackHeight * fraction

            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white.opacity(0.3))
                .frame(width: 2, height: indicatorHeight)
                .offset(y: yOffset - (containerHeight - indicatorHeight) / 2)
        }
    }

    // MARK: - Row

    private func clipboardRow(_ item: ClipboardItem) -> some View {
        ClipboardRowView(item: item, viewModel: viewModel)
    }

    // MARK: - Image Thumbnail

    @ViewBuilder
    private func thumbnailView(data: Data) -> some View {
        if let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipped()
                .cornerRadius(4)
        } else {
            Image(systemName: "photo")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 32, height: 32)
        }
    }
}

// MARK: - Row View

private struct ClipboardRowView: View {
    let item: ClipboardItem
    let viewModel: ClipboardViewModel
    @State private var copied = false
    @State private var copyTask: Task<Void, Never>?

    var body: some View {
        Button(action: triggerCopy) {
            HStack(spacing: 8) {
                // Thumbnail or icon
                if let imageData = item.imageData {
                    thumbnailView(data: imageData)
                }

                // Preview text (skip for image-only items)
                if item.imageData == nil || item.text != nil {
                    Text(item.preview)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Spacer()
                }

                // Copy / checkmark indicator
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 9))
                    .foregroundColor(copied ? .green.opacity(0.9) : .white.opacity(0.5))
                    .animation(.easeInOut(duration: 0.15), value: copied)

                // Delete button
                Button(action: { viewModel.delete(item) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete clipboard item")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(copied ? Color.green.opacity(0.12) : Color.white.opacity(0.05))
            .cornerRadius(4)
            .animation(.easeInOut(duration: 0.15), value: copied)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Re-copy: \(item.preview)")
    }

    private func triggerCopy() {
        viewModel.recopy(item)
        copied = true
        copyTask?.cancel()
        copyTask = Task {
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            copied = false
        }
    }

    @ViewBuilder
    private func thumbnailView(data: Data) -> some View {
        if let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipped()
                .cornerRadius(4)
        } else {
            Image(systemName: "photo")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 32, height: 32)
        }
    }
}
