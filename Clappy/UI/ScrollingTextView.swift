import SwiftUI

/// A text view that scrolls horizontally on hover when the text is too long to fit.
/// Shows static text when content fits. Applies a right-edge fade mask when scrolling.
struct ScrollingTextView: View {
    let text: String
    let font: Font

    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width
            let needsScroll = textWidth > containerWidth

            Text(text)
                .font(font)
                .lineLimit(1)
                .fixedSize()
                .background(
                    GeometryReader { g in
                        Color.clear
                            .onAppear { textWidth = g.size.width }
                            .onChange(of: g.size.width) { _, w in textWidth = w }
                    }
                )
                .offset(x: offset)
                .frame(width: containerWidth, alignment: .leading)
                .clipped()
                .mask(alignment: .leading) {
                    if needsScroll {
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.8),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.black
                    }
                }
                .onHover { hovering in
                    if hovering && needsScroll {
                        let duration = Double(text.count) * 0.035
                        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                            offset = -(textWidth - containerWidth)
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            offset = 0
                        }
                    }
                }
                .onChange(of: text) { _, _ in
                    withAnimation(.easeOut(duration: 0.1)) { offset = 0 }
                }
        }
        .frame(height: 16)
    }
}
