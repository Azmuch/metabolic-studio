import SwiftUI
import MetabolicCore

/// Yuka-style product report: score gauge, factor breakdown, healthier alternatives.
struct ScanResultView: View {
    let product: ScannedProduct
    let score: ProductScore

    @Environment(\.dismiss) private var dismiss
    @State private var alternatives: [(ScannedProduct, ProductScore)] = []
    @State private var loadingAlternatives = true

    init(product: ScannedProduct, score: ProductScore) {
        self.product = product
        self.score = score
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                hero
                if !score.negatives.isEmpty {
                    factorSection(title: "Negatives", factors: score.negatives)
                }
                if !score.positives.isEmpty {
                    factorSection(title: "Positives", factors: score.positives)
                }
                alternativesSection
                footnote
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task { await loadAlternatives() }
    }

    private var ratingColor: Color {
        switch score.rating {
        case .excellent: return MTTheme.success
        case .good: return Color(red: 0.64, green: 0.84, blue: 0.36)
        case .poor: return MTTheme.warning
        case .bad: return MTTheme.danger
        }
    }

    private var hero: some View {
        MTCard {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    productImage(urlString: product.imageURLString, size: 88, corner: 20)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name)
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(MTTheme.textPrimary)
                            .lineLimit(3)
                        if let brand = product.brand {
                            Text(brand)
                                .font(.system(size: 13))
                                .foregroundStyle(MTTheme.textSecondary)
                        }
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 20) {
                    ZStack {
                        MTRing(progress: Double(score.value) / 100, lineWidth: 9, tint: ratingColor)
                            .frame(width: 84, height: 84)
                        Text("\(score.value)")
                            .font(MTTheme.numberFont(size: 28))
                            .foregroundStyle(MTTheme.textPrimary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(score.rating.displayName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(ratingColor, in: Capsule())
                        Text("Health score out of 100")
                            .font(.system(size: 12))
                            .foregroundStyle(MTTheme.textTertiary)
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func factorSection(title: String, factors: [ScoreFactor]) -> some View {
        MTCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                ForEach(factors) { factor in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill((factor.isPositive ? MTTheme.success : MTTheme.danger).opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: factor.symbolName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(factor.isPositive ? MTTheme.success : MTTheme.danger)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(factor.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(MTTheme.textPrimary)
                            Text(factor.detail)
                                .font(.system(size: 13))
                                .foregroundStyle(MTTheme.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var alternativesSection: some View {
        if loadingAlternatives || !alternatives.isEmpty {
            MTCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("HEALTHIER ALTERNATIVES")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(MTTheme.textTertiary)

                    if loadingAlternatives {
                        HStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(MTTheme.surface2)
                                    .frame(width: 96, height: 130)
                            }
                        }
                        .redacted(reason: .placeholder)
                    } else {
                        ScrollView(.horizontal) {
                            HStack(spacing: 12) {
                                ForEach(alternatives, id: \.0.barcode) { alternative, altScore in
                                    VStack(spacing: 8) {
                                        productImage(urlString: alternative.imageURLString, size: 64, corner: 14)
                                        Text(alternative.name)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(MTTheme.textPrimary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                        ScoreBadge(score: altScore.value, rating: altScore.rating)
                                    }
                                    .frame(width: 108)
                                    .padding(10)
                                    .background(MTTheme.surface2, in: RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var footnote: some View {
        Text("Scores blend nutrition (60%), additives (30%) and organic (10%). Not medical advice.")
            .font(.system(size: 11))
            .foregroundStyle(MTTheme.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    private func productImage(urlString: String?, size: CGFloat, corner: CGFloat) -> some View {
        AsyncImage(url: urlString.flatMap(URL.init(string:))) { phase in
            if case .success(let image) = phase {
                image.resizable().aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    MTTheme.surface2
                    Image(systemName: "cart.fill")
                        .font(.system(size: size * 0.3))
                        .foregroundStyle(MTTheme.textTertiary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: corner))
    }

    private func loadAlternatives() async {
        defer { loadingAlternatives = false }
        guard !product.categories.isEmpty else { return }
        if let found = try? await OpenFoodFactsClient()
            .alternatives(categories: product.categories, excludingBarcode: product.barcode) {
            alternatives = found.filter { $0.1.value > score.value }
        }
    }
}

#Preview {
    ScanResultView(
        product: ScannedProduct(barcode: "0001", name: "Dark Chocolate 85%", brand: "Cocoa Co.",
                                energyKcal: 590, sugarsG: 14, satFatG: 24, sodiumMg: 20,
                                fiberG: 11, proteinG: 8, additives: ["e322"]),
        score: ProductScoringEngine.score(
            ScannedProduct(barcode: "0001", name: "Dark Chocolate 85%",
                           energyKcal: 590, sugarsG: 14, satFatG: 24, sodiumMg: 20,
                           fiberG: 11, proteinG: 8, additives: ["e322"]))
    )
}
