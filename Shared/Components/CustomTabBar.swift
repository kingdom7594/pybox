import SwiftUI

/// 自定义底部 Tab Bar — 对齐原型 .tab-bar
/// 5 项：文件/编辑/终端/AI/更多；图标 24pt、标签 10pt、active=accent、inactive=muted2
struct CustomTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    var bottomInset: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ContentView.Tab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 4 + bottomInset)
        .background(Theme.Colors.tabBarBg)
        .overlay(
            Rectangle()
                .fill(Theme.Colors.border)
                .frame(height: 1),
            alignment: .top
        )
    }

    @ViewBuilder
    private func tabButton(_ tab: ContentView.Tab) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { selectedTab = tab }
        } label: {
            VStack(spacing: 1) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: .light))
                    .frame(width: 24, height: 24)
                    .foregroundColor(selectedTab == tab ? Theme.Colors.accent : Theme.Colors.muted2)
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
                    .tracking(0.2)
                    .foregroundColor(selectedTab == tab ? Theme.Colors.accent : Theme.Colors.muted2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.pressable)
    }
}
