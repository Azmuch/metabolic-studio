import Foundation
import StoreKit
import Observation

/// An expansion content pack sold as a **non-consumable IAP**. Clips ship as On-Demand Resources
/// tagged with `odrTag` (Apple-hosted asset packs — no server of ours): after purchase the app
/// requests the tag and the pack's clips resolve like bundled files. `exerciseIDs` are the clip
/// ids from `docs/EXERCISE-CATALOG-SEEDANCE.md`; library entries + clips arrive in app updates,
/// and gating keys off these ids automatically as they land.
struct ExpansionPack: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let productID: String
    let odrTag: String
    let exerciseIDs: Set<String>

    static let all: [ExpansionPack] = [
        ExpansionPack(
            id: "yoga", title: "Yoga", subtitle: "13 asanas, beginner to advanced",
            symbol: "figure.yoga",
            productID: "com.metabolicstudio.metabolic.pack.yoga", odrTag: "pack.yoga",
            exerciseIDs: ["mountainPose", "downwardDog", "bridgePose", "seatedForwardFold",
                          "warrior1", "warrior2", "warrior3", "trianglePose", "chairPose",
                          "treePose", "crowPose", "wheelPose", "dancerPose"]),
        ExpansionPack(
            id: "pilates", title: "Pilates", subtitle: "12 classic mat moves",
            symbol: "figure.pilates",
            productID: "com.metabolicstudio.metabolic.pack.pilates", odrTag: "pack.pilates",
            exerciseIDs: ["pilatesHundred", "pelvicCurl", "singleLegStretch", "legCircles",
                          "rollUp", "crissCross", "sawStretch", "swanDive", "sidekickSeries",
                          "teaser", "boomerang", "jackknife"]),
        ExpansionPack(
            id: "hiit", title: "HIIT", subtitle: "Signature interval moves + circuits",
            symbol: "bolt.heart.fill",
            productID: "com.metabolicstudio.metabolic.pack.hiit", odrTag: "pack.hiit",
            exerciseIDs: ["plankJack", "skaterJump", "squatThrust", "sprawl", "tuckJump",
                          "starJump"]),
        ExpansionPack(
            id: "kickboxing", title: "Kickboxing", subtitle: "Strikes, kicks and defense",
            symbol: "figure.kickboxing",
            productID: "com.metabolicstudio.metabolic.pack.kickboxing", odrTag: "pack.kickboxing",
            exerciseIDs: ["jab", "cross", "frontKick", "hook", "uppercut", "roundhouseKick",
                          "kneeStrike", "sideKick", "bobAndWeave", "spinningBackKick"]),
    ]

    static func pack(containing exerciseID: String) -> ExpansionPack? {
        all.first { $0.exerciseIDs.contains(exerciseID) }
    }
}

/// StoreKit 2 store for expansion packs (non-consumables) — loads products, purchases, restores,
/// and resolves ownership from `Transaction.currentEntitlements`. Separate from the subscription
/// manager: tiers gate app *features*; packs unlock *content*.
@MainActor
@Observable
final class PackStore {
    static let shared = PackStore()

    private(set) var products: [Product] = []
    private(set) var purchasedPackIDs: Set<String> = []

    private init() {
        Task { await configure() }
    }

    func configure() async {
        let ids = ExpansionPack.all.map(\.productID)
        if let fetched = try? await Product.products(for: ids) {
            products = fetched
        }
        await refreshOwnership()
        Task {
            for await update in Transaction.updates {
                if let transaction = try? update.payloadValue {
                    await transaction.finish()
                    await refreshOwnership()
                }
            }
        }
    }

    func refreshOwnership() async {
        var owned: Set<String> = []
        for await entitlement in Transaction.currentEntitlements {
            guard let transaction = try? entitlement.payloadValue,
                  transaction.productType == .nonConsumable else { continue }
            if let pack = ExpansionPack.all.first(where: { $0.productID == transaction.productID }) {
                owned.insert(pack.id)
            }
        }
        purchasedPackIDs = owned
    }

    func product(for pack: ExpansionPack) -> Product? {
        products.first { $0.id == pack.productID }
    }

    func isPurchased(_ pack: ExpansionPack) -> Bool {
        purchasedPackIDs.contains(pack.id)
    }

    /// Free (non-pack) exercises are always unlocked; pack exercises unlock with their pack.
    func isUnlocked(exerciseID: String) -> Bool {
        guard let pack = ExpansionPack.pack(containing: exerciseID) else { return true }
        return purchasedPackIDs.contains(pack.id)
    }

    /// The pack locking this exercise, or nil when it's free or already owned.
    func lockingPack(for exerciseID: String) -> ExpansionPack? {
        guard let pack = ExpansionPack.pack(containing: exerciseID),
              !purchasedPackIDs.contains(pack.id) else { return nil }
        return pack
    }

    func purchase(_ pack: ExpansionPack) async throws {
        guard let product = product(for: pack) else {
            throw SubscriptionError.productsUnavailable
        }
        let result = try await product.purchase()
        if case .success(let verification) = result,
           let transaction = try? verification.payloadValue {
            await transaction.finish()
            await refreshOwnership()
            // Start fetching the pack's Apple-hosted clips right away.
            ExerciseClipStore.shared.beginODRAccess(tag: pack.odrTag)
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshOwnership()
    }
}
