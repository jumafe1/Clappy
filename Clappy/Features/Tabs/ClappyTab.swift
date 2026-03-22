import SwiftUI

// MARK: - Tab Model

enum ClappyTab: String {
    case media
    case clipboard
}

// MARK: - Compact Header View

struct CompactHeaderView: View {
    @Binding var activeTab: ClappyTab

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AnimationConstants.tabIconSpacing) {
                Text("Clappy")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(AnimationConstants.headerLabelOpacity))

                tabButton(.clipboard, systemImage: "doc.on.clipboard")
                tabButton(.media, systemImage: "music.note")

                Spacer()
            }
            .frame(height: AnimationConstants.headerRowHeight)

            Rectangle()
                .fill(Color.white.opacity(AnimationConstants.headerDividerOpacity))
                .frame(height: AnimationConstants.headerSeparatorHeight)
        }
    }

    private func tabButton(_ tab: ClappyTab, systemImage: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { activeTab = tab }
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: AnimationConstants.tabIconSize))
                .padding(AnimationConstants.tabIconPadding)
                .background(
                    activeTab == tab ? Color.white.opacity(0.15) : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: AnimationConstants.tabPillCornerRadius))
                .opacity(activeTab == tab ? AnimationConstants.tabActiveOpacity : AnimationConstants.tabInactiveOpacity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab == .media ? "Media tab" : "Clipboard tab")
    }
}
