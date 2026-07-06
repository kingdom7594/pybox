import SwiftUI

struct SettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var subscription = SubscriptionManager.shared
    @State private var showSubscription = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 大标题
                    Text("设置")
                        .font(.system(size: 28, weight: .bold))
                        .tracking(-0.56)
                    .foregroundColor(Theme.Colors.fg)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 4)

                    // 订阅区
                    settingsSection("订阅") {
                        settingsGroup {
                            settingsRow(
                                icon: "lightbulb.fill",
                                iconBg: Theme.Colors.accentDim,
                                iconColor: Theme.Colors.accent,
                                label: "AI 订阅",
                                value: subscription.statusText,
                                action: { showSubscription = true }
                            )
                        }
                    }

                    // 外观区
                    settingsSection("外观") {
                        // 浅色/深色 segmented control
                        HStack(spacing: 0) {
                            modeSegButton(.light, "浅色")
                            modeSegButton(.dark, "深色")
                        }
                        .background(Theme.Colors.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                        // 7 色板列表
                        settingsGroup {
                            ForEach(Array(ThemePalette.allCases.enumerated()), id: \.element.id) { idx, palette in
                                themeRow(palette)
                                if idx < ThemePalette.allCases.count - 1 {
                                    Rectangle()
                                        .fill(Theme.Colors.border)
                                        .frame(height: 0.5)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                    }

                    // 通用区
                    settingsSection("通用") {
                        settingsGroup {
                            settingsRow(
                                icon: "chevron.left.forwardslash.chevron.right",
                                iconBg: Theme.Colors.accentDim,
                                iconColor: Theme.Colors.accent,
                                label: "Python 版本",
                                value: "3.13.1",
                                action: { showToast("Python 3.13.1 已安装，共 42 个包") }
                            )
                            Rectangle().fill(Theme.Colors.border).frame(height: 0.5).padding(.leading, 52)
                            settingsRow(
                                icon: "shippingbox.fill",
                                iconBg: Theme.Colors.success.opacity(0.2),
                                iconColor: Theme.Colors.success,
                                label: "已安装包",
                                value: "42 个",
                                action: { showToast("已安装 42 个包：numpy, matplotlib, pandas 等") }
                            )
                            Rectangle().fill(Theme.Colors.border).frame(height: 0.5).padding(.leading, 52)
                            settingsRow(
                                icon: "internaldrive",
                                iconBg: Theme.Colors.warn.opacity(0.2),
                                iconColor: Theme.Colors.warn,
                                label: "储存空间",
                                value: "156 MB",
                                action: { showToast("项目共占用 156 MB 存储空间") }
                            )
                        }
                    }

                    // 底部
                    VStack(spacing: 4) {
                        Text("PythonIDE · v2.0")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.muted2)
                        HStack(spacing: 16) {
                            Text("隐私政策").foregroundColor(Theme.Colors.muted2)
                            Text("用户协议").foregroundColor(Theme.Colors.muted2)
                            Text("帮助").foregroundColor(Theme.Colors.muted2)
                        }
                        .font(.system(size: 10))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(isPresented: $showSubscription) {
                SubscriptionView()
            }
    }

    // MARK: - 组件

    @ViewBuilder
    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.4)
                .foregroundColor(Theme.Colors.muted)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 6)
            content()
        }
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
    private func settingsRow(icon: String, iconBg: Color, iconColor: Color, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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

    @ViewBuilder
    private func modeSegButton(_ mode: Theme.AppearanceMode, _ label: String) -> some View {
        Button {
            themeManager.setMode(mode)
            showToast("已切换到\(mode.displayName)模式")
        } label: {
            Text(label)
                .font(.system(size: 13, weight: themeManager.mode == mode ? .semibold : .medium))
                .foregroundColor(themeManager.mode == mode ? Theme.Colors.fg : Theme.Colors.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    themeManager.mode == mode ? Theme.Colors.surface : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.pressable)
    }

    @ViewBuilder
    private func themeRow(_ palette: ThemePalette) -> some View {
        Button {
            themeManager.setPalette(palette)
            showToast("色板: \(palette.displayName)")
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(palette.swatchColor)
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            themeManager.palette == palette ? Theme.Colors.fg : Color.clear,
                            lineWidth: 2
                        )
                    if themeManager.palette == palette {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 1) {
                    Text(palette.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.Colors.fg)
                    Text(palette.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.muted)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
        }
        .buttonStyle(.pressable)
    }
}

#Preview {
    SettingsView()
}
