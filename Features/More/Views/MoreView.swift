import SwiftUI

struct MoreView: View {
    @State private var path: [MoreDestination] = []

    enum MoreDestination: Hashable {
        case ssh, notebook, scene, miniapp, tools, settings, community, runHistory
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 大标题
                    Text("更多")
                        .font(.system(size: 28, weight: .bold))
                        .tracking(-0.56)
                        .foregroundColor(Theme.Colors.fg)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 4)

                    // 工具卡片网格
                    sectionTitle("开发工具")
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        toolCard("arrow.right.to.line", "SSH 终端", "3 台服务器", .ssh)
                        toolCard("doc.richtext", "Notebook", ".ipynb 编辑器", .notebook)
                        toolCard("rect.drawing", "Scene", "图形 & 动画", .scene)
                        toolCard("ipad.landscape", "MiniApp", "用 Python 做 App", .miniapp)
                        toolCard("wrench.screwdriver", "工具集", "JSON/QR/Base64", .tools)
                        toolCard("gearshape", "设置", "皮肤 · 订阅 · 环境", .settings)
                    }
                    .padding(.horizontal, 16)

                    // 保留的原有功能入口
                    sectionTitle("扩展功能")
                    settingsGroup {
                        navRow("person.3.fill", Theme.Colors.accentDim, Theme.Colors.accent, "社区", "代码分享 · 教程", .community)
                        Rectangle().fill(Theme.Colors.border).frame(height: 0.5).padding(.leading, 52)
                        navRow("clock.arrow.circlepath", Theme.Colors.success.opacity(0.2), Theme.Colors.success, "运行历史", "查看历史执行记录", .runHistory)
                    }

                    // 状态区
                    sectionTitle("状态")
                    settingsGroup {
                        infoRow("chevron.left.forwardslash.chevron.right", Theme.Colors.accentDim, Theme.Colors.accent, "Python 版本", "3.13.1")
                        Rectangle().fill(Theme.Colors.border).frame(height: 0.5).padding(.leading, 52)
                        infoRow("shippingbox.fill", Theme.Colors.success.opacity(0.2), Theme.Colors.success, "已安装包", "42 个")
                        Rectangle().fill(Theme.Colors.border).frame(height: 0.5).padding(.leading, 52)
                        infoRow("internaldrive", Theme.Colors.warn.opacity(0.2), Theme.Colors.warn, "储存空间", "156 MB")
                    }

                    VStack(spacing: 4) {
                        Text("PythonIDE · v2.0")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.muted2)
                        HStack(spacing: 16) {
                            Text("隐私政策")
                            Text("用户协议")
                            Text("帮助")
                        }
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.muted2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Theme.Colors.background)
            .navigationBarHidden(true)
            .navigationDestination(for: MoreDestination.self) { dest in
                destinationView(dest)
            }
        }
    }

    @ViewBuilder
    private func destinationView(_ dest: MoreDestination) -> some View {
        switch dest {
        case .ssh: SSHView()
        case .notebook: NotebookView()
        case .scene: SceneView()
        case .miniapp: MiniAppView()
        case .tools: ToolsView()
        case .settings: SettingsView()
        case .community: CommunityView()
        case .runHistory: RunHistoryView()
        }
    }

    // MARK: - 组件

    @ViewBuilder
    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(0.4)
            .foregroundColor(Theme.Colors.muted)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 6)
    }

    @ViewBuilder
    private func settingsGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
            .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func toolCard(_ icon: String, _ label: String, _ count: String, _ dest: MoreDestination) -> some View {
        NavigationLink(value: dest) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .light))
                    .foregroundColor(Theme.Colors.accent)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.fg)
                Text(count)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.muted2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.pressable)
    }

    @ViewBuilder
    private func navRow(_ icon: String, _ iconBg: Color, _ iconColor: Color, _ label: String, _ sub: String, _ dest: MoreDestination) -> some View {
        NavigationLink(value: dest) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(iconBg)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 15))
                        .foregroundColor(Theme.Colors.fg)
                    Text(sub)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.muted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.muted2)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
        }
        .buttonStyle(.pressable)
    }

    @ViewBuilder
    private func infoRow(_ icon: String, _ iconBg: Color, _ iconColor: Color, _ label: String, _ value: String) -> some View {
        Button {
            showToast("\(label): \(value)")
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(iconBg)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                .frame(width: 28, height: 28)

                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.fg)

                Spacer()

                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.muted)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.muted2)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
        }
        .buttonStyle(.pressable)
    }
}

#Preview {
    MoreView()
}
