import SwiftUI
import StoreKit

/// Paywall overlay — 对齐原型 .paywall-overlay
/// 在 AI 页用完免费次数时弹出，底部上滑卡片
struct PaywallView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var subscription = SubscriptionManager.shared
    @State private var selectedPlan: String = "monthly"
    @State private var isPurchasing = false

    var body: some View {
        if isPresented {
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.7)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                VStack(spacing: 0) {
                    // 图标
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.accent, Theme.Colors.accent2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .frame(width: 56, height: 56)
                    .padding(.top, 24)

                    Text("解锁 AI 助手")
                        .font(.system(size: 22, weight: .bold))
                        .tracking(-0.4)
                        .foregroundColor(Theme.Colors.fg)
                        .padding(.top, 16)

                    Text("免费次数已用完，订阅后无限使用 AI 编程助手")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.muted)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)

                    // 计划选择
                    HStack(spacing: 10) {
                        planCard("monthly", "月付", "¥25", "/月", "无限 AI 查询，随时取消", nil)
                        planCard("yearly", "年付", "¥198", "/年", "省 34%，约 ¥16.5/月", "最划算")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // 订阅按钮
                    Button {
                        purchase()
                    } label: {
                        HStack {
                            if isPurchasing {
                                ProgressView().tint(.black)
                            }
                            Text(isPurchasing ? "处理中..." : "订阅后继续使用")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isPurchasing ? Theme.Colors.accent2 : Theme.Colors.accent)
                        )
                    }
                    .buttonStyle(.pressable)
                    .disabled(isPurchasing)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // 底部链接
                    HStack(spacing: 16) {
                        Button("稍后再说") { dismiss() }
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.muted)
                        Button("恢复购买") {
                            Task { await subscription.restorePurchases() }
                        }
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.muted)
                    }
                    .padding(.top, 10)

                    Text("订阅自动续期，可随时在设置中取消。付款通过 App Store 处理。")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.muted2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        .padding(.bottom, 34)
                }
                .frame(maxWidth: 380)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Theme.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .zIndex(2000)
        }
    }

    private func dismiss() {
        withAnimation(Theme.Animation.sheet) { isPresented = false }
    }

    @ViewBuilder
    private func planCard(_ id: String, _ name: String, _ price: String, _ unit: String, _ desc: String, _ badge: String?) -> some View {
        Button {
            selectedPlan = id
        } label: {
            VStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.muted)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(price)
                        .font(.system(size: 26, weight: .bold))
                        .tracking(-0.4)
                        .foregroundColor(Theme.Colors.fg)
                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.muted)
                }
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.muted2)
                    .multilineTextAlignment(.center)
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.Colors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Theme.Colors.accentDim)
                        )
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedPlan == id ? Theme.Colors.surface : Theme.Colors.surface2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selectedPlan == id ? Theme.Colors.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.pressable)
    }

    private func purchase() {
        guard let product = selectedPlan == "monthly" ? subscription.monthlyProduct : subscription.yearlyProduct else {
            // 沙盒未配置产品，本地模拟
            dismiss()
            showToast("订阅成功！无限 AI 已解锁（本地测试）")
            NotificationCenter.default.post(name: .subscriptionActivated, object: nil)
            return
        }
        isPurchasing = true
        Task {
            await subscription.purchase(product)
            await MainActor.run {
                isPurchasing = false
                if subscription.isSubscribed {
                    dismiss()
                    showToast("订阅成功！无限 AI 已解锁")
                    NotificationCenter.default.post(name: .subscriptionActivated, object: nil)
                }
            }
        }
    }
}
