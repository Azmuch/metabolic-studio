import SwiftUI
import StoreKit

/// StoreKit 2-backed subscription manager. Loads store products, listens for transaction
/// updates, and resolves the user's current entitlement into a `SubscriptionTier`.
@Observable
final class SubscriptionManager {
    static let plusMonthlyID = "com.metabolicstudio.metabolic.plus.monthly"
    static let plusYearlyID = "com.metabolicstudio.metabolic.plus.yearly"
    static let proMonthlyID = "com.metabolicstudio.metabolic.pro.monthly"
    static let proYearlyID = "com.metabolicstudio.metabolic.pro.yearly"

    private static let productIDs = [plusMonthlyID, plusYearlyID, proMonthlyID, proYearlyID]

    var tier: SubscriptionTier = .free
    var products: [Product] = []

    var hasProducts: Bool { !products.isEmpty }

    /// Loads store products and starts listening for transaction updates, then resolves
    /// the current entitlement tier. Safe to call once at app launch.
    func configure() async {
        if let fetched = try? await Product.products(for: Self.productIDs) {
            products = fetched.sorted { $0.price < $1.price }
        }

        Task {
            for await update in Transaction.updates {
                guard let transaction = try? self.checkVerified(update) else { continue }
                await transaction.finish()
                await self.refreshTier()
            }
        }

        await refreshTier()
    }

    /// Recomputes `tier` from `Transaction.currentEntitlements`. Pro wins over Plus if both
    /// are somehow present.
    func refreshTier() async {
        var resolved: SubscriptionTier = .free
        for await entitlement in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(entitlement) else { continue }
            if transaction.productID.contains(".pro.") {
                resolved = .pro
                break
            } else if transaction.productID.contains(".plus.") {
                resolved = .plus
            }
        }
        tier = resolved
    }

    func purchase(productID: String) async throws {
        guard let product = product(id: productID) else { return }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshTier()
        case .userCancelled, .pending:
            return
        @unknown default:
            return
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshTier()
    }

    func product(id: String) -> Product? {
        products.first { $0.id == id }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw VerificationError.failed
        case .verified(let safe):
            return safe
        }
    }

    private enum VerificationError: Error {
        case failed
    }
}
