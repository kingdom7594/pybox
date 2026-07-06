import SwiftUI
import StoreKit

/// AI 免费额度管理（UserDefaults 持久化，对齐原型 MAX_FREE=10）
@MainActor
final class UsageManager: ObservableObject {
    static let shared = UsageManager()

    private let key = "aiFreeCount"
    let maxFree = 10

    @Published private(set) var usedCount: Int

    private init() {
        usedCount = UserDefaults.standard.integer(forKey: key)
    }

    var remaining: Int { max(0, maxFree - usedCount) }

    var canUse: Bool { remaining > 0 || SubscriptionManager.shared.isSubscribed }

    /// 消耗一次（仅未订阅时计数）
    func consume() {
        guard !SubscriptionManager.shared.isSubscribed else { return }
        usedCount += 1
        UserDefaults.standard.set(usedCount, forKey: key)
    }

    /// 重置（订阅后调用，清零计数）
    func reset() {
        usedCount = 0
        UserDefaults.standard.set(0, forKey: key)
    }
}

/// StoreKit2 订阅管理 — 月付/年付自动续期订阅
@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // 产品 ID（需在 App Store Connect 用相同 ID 配置）
    static let monthlyID = "com.huang.pybox.ai.monthly"
    static let yearlyID = "com.huang.pybox.ai.yearly"

    @Published private(set) var isSubscribed: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published var purchaseError: String?

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts(); await updatePurchasedStatus() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - 加载商品

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: [
                Self.monthlyID, Self.yearlyID
            ])
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            NSLog("[Subscription] Failed to load products: \(error)")
        }
    }

    // MARK: - 购买

    func purchase(_ product: Product) async {
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedStatus()
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                purchaseError = "购买待处理，请稍后检查"
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
            NSLog("[Subscription] Purchase failed: \(error)")
        }
    }

    // MARK: - 恢复购买

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedStatus()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - 验证 + 状态更新

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified(_, let error):
            throw error
        }
    }

    private func updatePurchasedStatus() async {
        var purchased: Set<String> = []
        var hasActiveSub = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
                if transaction.productID == Self.monthlyID || transaction.productID == Self.yearlyID {
                    hasActiveSub = true
                }
            }
        }

        purchasedProductIDs = purchased
        let wasSubscribed = isSubscribed
        isSubscribed = hasActiveSub
        if hasActiveSub && !wasSubscribed {
            UsageManager.shared.reset()
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                if let transaction = try? self.checkVerified(result) {
                    await self.updatePurchasedStatus()
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - 便捷

    var monthlyProduct: Product? { products.first(where: { $0.id == Self.monthlyID }) }
    var yearlyProduct: Product? { products.first(where: { $0.id == Self.yearlyID }) }

    /// 订阅状态文案
    var statusText: String {
        isSubscribed ? "✓ 已订阅" : "未订阅"
    }
}
