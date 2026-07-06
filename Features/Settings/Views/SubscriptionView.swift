import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @ObservedObject private var subscription = SubscriptionManager.shared
    @ObservedObject private var usage = UsageManager.shared
    @State private var selectedPlan: String = "monthly"
    @State private var isPurchasing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero
                VStack(spacing: 6) {
                    Text("AI 编程助手")
                        .font(.system(size: 30, weight: .bold))
                        .tracking(-0.4)
                        .foregroundColor(Theme.Colors.fg)
                    Text("无限次 AI 代码查询 · 智能调试 · 代码解释")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.muted)

                    // 计划选择
                    HStack(spacing: 3) {
                        planButton("monthly", "月付", "¥25/月")
                        planButton("yearly", "年付", "¥198/年")
                    }
                    .background(Theme.Colors.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // 价格
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(selectedPlan == "monthly" ? "¥25" : "¥198")
                            .font(.system(size: 44, weight: .bold))
                            .tracking(-0.6)
                            .foregroundColor(Theme.Colors.fg)
                        Text(selectedPlan == "monthly" ? "/月" : "/年")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.Colors.muted)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.accentDim, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // 功能列表
                VStack(alignment: .leading, spacing: 0) {
                    featureItem("无限 AI 查询", "不再受次数限制，随时随地提问编程问题")
                    featureItem("代码解释 & 调试", "逐行解释复杂代码，快速定位 Bug")
                    featureItem("性能优化建议", "AI 分析代码性能瓶颈，给出优化方案")
                    featureItem("多模型支持", "DeepSeek / GPT / Claude 自由切换")
                    featureItem("自定义提示词", "保存常用提示模板，一键调用")
                }
                .padding(.horizontal, 16)

                // CTA
                VStack(spacing: 10) {
                    if subscription.isSubscribed {
                        // 已订阅状态
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.Colors.success)
                            Text("你已订阅，无限 AI 已解锁")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.fg)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Theme.Colors.success.opacity(0.15))
                        )

                        Button {
                            Task { await subscription.restorePurchases() }
                        } label: {
                            Text("恢复购买")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Theme.Colors.fg)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Theme.Colors.surface2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Theme.Colors.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.pressable)
                    } else {
                        Button {
                            purchase()
                        } label: {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                        .tint(.black)
                                }
                                Text(isPurchasing ? "处理中..." : "开始订阅")
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

                        Button {
                            Task { await subscription.restorePurchases() }
                        } label: {
                            Text("恢复购买")
                                .font(.system(size: 15))
                                .foregroundColor(Theme.Colors.muted)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.pressable)
                    }

                    if let err = subscription.purchaseError {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.danger)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(16)

                // 条款
                Text("订阅自动续期，可随时取消。通过 App Store 处理付款。\n免费额度剩余 \(usage.remaining)/\(usage.maxFree) 次。")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.muted2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
        .background(Theme.Colors.background)
        .navigationTitle("AI 订阅")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Colors.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - 组件

    @ViewBuilder
    private func planButton(_ id: String, _ name: String, _ price: String) -> some View {
        Button {
            selectedPlan = id
        } label: {
            Text("\(name) · \(price)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(selectedPlan == id ? .black : Theme.Colors.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    selectedPlan == id ? Theme.Colors.accent : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.pressable)
    }

    @ViewBuilder
    private func featureItem(_ title: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.Colors.accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.fg)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.muted)
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .fill(Theme.Colors.border)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private func purchase() {
        guard let product = selectedPlan == "monthly" ? subscription.monthlyProduct : subscription.yearlyProduct else {
            // 没有从 StoreKit 加载到产品（沙盒未配置），用本地模拟订阅
            subscription.purchaseError = nil
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
                    showToast("订阅成功！无限 AI 已解锁")
                    NotificationCenter.default.post(name: .subscriptionActivated, object: nil)
                }
            }
        }
    }
}

extension Notification.Name {
    static let subscriptionActivated = Notification.Name("subscriptionActivated")
}

#Preview {
    NavigationStack {
        SubscriptionView()
    }
}
