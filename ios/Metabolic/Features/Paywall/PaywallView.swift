import SwiftUI
import StoreKit
import MetabolicCore

/// Three-tier paywall (Free / Plus / Pro) with monthly-yearly billing toggle,
/// driven by StoreKit 2 through `SubscriptionManager`.
struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var yearly = true
    @State private var purchasingID: String?

    private enum ProductIDs {
        static let plusMonthly = "com.metabolicstudio.metabolic.plus.monthly"
        static let plusYearly = "com.metabolicstudio.metabolic.plus.yearly"
        static let proMonthly = "com.metabolicstudio.metabolic.pro.monthly"
        static let proYearly = "com.metabolicstudio.metabolic.pro.yearly"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero
                billingToggle
                tierCard(
                    tier: .free, badge: nil, price: "Free", period: "forever",
                    features: ["Manual food & water logging", "Daily workout plan",
                               "3 barcode scans a day", "Apple Health sync"])
                tierCard(
                    tier: .plus, badge: "POPULAR",
                    price: displayPrice(for: yearly ? ProductIDs.plusYearly : ProductIDs.plusMonthly,
                                        fallback: yearly ? "$39.99" : "$4.99"),
                    period: yearly ? "per year" : "per month",
                    features: ["AI photo analysis — 30/month", "Unlimited product scans",
                               "Full exercise library", "Customizable dashboard"])
                tierCard(
                    tier: .pro, badge: nil,
                    price: displayPrice(for: yearly ? ProductIDs.proYearly : ProductIDs.proMonthly,
                                        fallback: yearly ? "$79.99" : "$9.99"),
                    period: yearly ? "per year" : "per month",
                    features: ["Unlimited AI photo analysis", "Adaptive training plans",
                               "CSV data export", "Everything in Plus"])
                restoreAndLegal
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(MTTheme.bg.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MTTheme.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(MTTheme.surface2, in: Circle())
            }
            .padding(16)
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                MTRing(progress: 0.9, lineWidth: 6).frame(width: 116, height: 116).opacity(0.25)
                MTRing(progress: 0.72, lineWidth: 7).frame(width: 88, height: 88).opacity(0.55)
                MTRing(progress: 0.55, lineWidth: 8).frame(width: 60, height: 60)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(MTTheme.volt)
            }
            Text("Metabolic+")
                .font(MTTheme.numberFont(size: 34))
                .foregroundStyle(MTTheme.textPrimary)
            Text("Unlock the full engine.")
                .font(.system(size: 15))
                .foregroundStyle(MTTheme.textSecondary)
        }
        .padding(.top, 12)
    }

    private var billingToggle: some View {
        HStack(spacing: 4) {
            billingOption("Monthly", isSelected: !yearly) { yearly = false }
            billingOption("Yearly", isSelected: yearly, badge: "SAVE 33%") { yearly = true }
        }
        .padding(4)
        .background(MTTheme.surface2, in: Capsule())
    }

    private func billingOption(_ label: String, isSelected: Bool, badge: String? = nil,
                               action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { action() }
        } label: {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.black : MTTheme.textSecondary)
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(isSelected ? MTTheme.volt : Color.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.black : MTTheme.volt, in: Capsule())
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(isSelected ? MTTheme.volt : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func tierCard(tier: SubscriptionTier, badge: String?, price: String,
                          period: String, features: [String]) -> some View {
        MTCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(tier.displayName)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(MTTheme.textPrimary)
                    if let badge {
                        Text(badge)
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(0.5)
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(MTTheme.volt, in: Capsule())
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(price)
                            .font(MTTheme.numberFont(size: 22))
                            .foregroundStyle(MTTheme.textPrimary)
                        Text(period)
                            .font(.system(size: 11))
                            .foregroundStyle(MTTheme.textTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(MTTheme.volt)
                            Text(feature)
                                .font(.system(size: 14))
                                .foregroundStyle(MTTheme.textSecondary)
                        }
                    }
                }

                purchaseControl(for: tier)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay(
            RoundedRectangle(cornerRadius: MTTheme.cardRadius)
                .stroke(badge != nil ? MTTheme.volt : Color.clear, lineWidth: 1.5))
    }

    @ViewBuilder
    private func purchaseControl(for tier: SubscriptionTier) -> some View {
        if subscriptionManager.tier == tier {
            MTChip(text: "Current plan", systemImage: "checkmark.circle.fill", isActive: true)
        } else if tier == .free {
            EmptyView()
        } else {
            let productID = productID(for: tier)
            let unavailable = !subscriptionManager.hasProducts

            VStack(spacing: 6) {
                MTPrimaryButton(
                    title: purchasingID == productID ? "Processing…" : "Get \(tier.displayName)") {
                    purchase(productID)
                }
                .disabled(purchasingID != nil || unavailable)
                .opacity(unavailable ? 0.5 : 1)

                if unavailable {
                    Text("Unavailable — check StoreKit configuration")
                        .font(.system(size: 11))
                        .foregroundStyle(MTTheme.textTertiary)
                }
            }
        }
    }

    private var restoreAndLegal: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await subscriptionManager.restore()
                    Haptics.success()
                }
            } label: {
                Text("Restore purchases")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MTTheme.volt)
            }
            Text("Subscriptions auto-renew until cancelled in App Store settings. Prices shown in your local currency at checkout.")
                .font(.system(size: 11))
                .foregroundStyle(MTTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
    }

    private func productID(for tier: SubscriptionTier) -> String {
        switch tier {
        case .pro: return yearly ? ProductIDs.proYearly : ProductIDs.proMonthly
        default: return yearly ? ProductIDs.plusYearly : ProductIDs.plusMonthly
        }
    }

    private func displayPrice(for productID: String, fallback: String) -> String {
        subscriptionManager.product(id: productID)?.displayPrice ?? fallback
    }

    private func purchase(_ productID: String) {
        purchasingID = productID
        Task {
            defer { purchasingID = nil }
            do {
                try await subscriptionManager.purchase(productID: productID)
                if subscriptionManager.tier != .free {
                    Haptics.success()
                    dismiss()
                }
            } catch {
                Haptics.warning()
            }
        }
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionManager())
}
