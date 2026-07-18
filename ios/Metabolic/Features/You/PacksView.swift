import SwiftUI
import StoreKit

/// Expansion-pack storefront: Yoga / Pilates / HIIT / Kickboxing as one-time unlocks
/// (non-consumable IAP). Owned packs download their clips from Apple's On-Demand Resource
/// hosting automatically; content lands in app updates and unlocks instantly for owners.
struct PacksView: View {
    @State private var store = PackStore.shared
    @State private var purchasingID: String?
    @State private var purchaseError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(ExpansionPack.all) { pack in
                    packCard(pack)
                }

                Button {
                    Haptics.tap()
                    Task { await store.restorePurchases() }
                } label: {
                    Text("Restore purchases")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MTTheme.accentText)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)

                Text("Packs are one-time purchases. New exercises for owned packs arrive in app updates and unlock automatically — demos download in the background after purchase.")
                    .font(.system(size: 12))
                    .foregroundStyle(MTTheme.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(MTBackground().ignoresSafeArea())
        .navigationTitle("Expansion Packs")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Purchase failed",
            isPresented: Binding(
                get: { purchaseError != nil },
                set: { if !$0 { purchaseError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseError ?? "Unknown error.")
        }
    }

    private func packCard(_ pack: ExpansionPack) -> some View {
        let owned = store.isPurchased(pack)
        return MTCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(MTTheme.voltDim).frame(width: 52, height: 52)
                    Image(systemName: pack.symbol)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(MTTheme.accentText)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(pack.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text(pack.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(MTTheme.textSecondary)
                    Text("\(pack.exerciseIDs.count) exercises")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MTTheme.textTertiary)
                }

                Spacer(minLength: 8)

                if owned {
                    MTChip(text: "Owned", systemImage: "checkmark", isActive: true)
                } else {
                    Button {
                        buy(pack)
                    } label: {
                        Text(purchasingID == pack.productID ? "…" : priceText(pack))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(MTTheme.volt, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(purchasingID != nil)
                }
            }
        }
    }

    private func priceText(_ pack: ExpansionPack) -> String {
        store.product(for: pack)?.displayPrice ?? "Buy"
    }

    private func buy(_ pack: ExpansionPack) {
        Haptics.tap()
        purchasingID = pack.productID
        Task {
            do {
                try await store.purchase(pack)
                if store.isPurchased(pack) { Haptics.success() }
            } catch {
                Haptics.warning()
                purchaseError = error.localizedDescription
            }
            purchasingID = nil
        }
    }
}

#Preview {
    NavigationStack { PacksView() }
}
