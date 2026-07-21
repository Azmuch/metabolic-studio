import SwiftUI
import MetabolicCore

/// "How products are scored" — the transparency sheet behind the scanner's health score,
/// in the spirit of Yuka's methodology page but written for our two-layer system: the
/// standards-based health score (Nutri-Score nutrition + additive risk + organic) and the
/// separate goal-aware Fit For You layer.
struct ScoringInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MTSheetHeader(title: "Product scoring")

                Text("Every scanned product gets two independent reads: a health score anyone can compare, and a fit read that's personal to your goal.")
                    .font(.system(size: 14))
                    .foregroundStyle(MTTheme.textSecondary)

                sectionCard(
                    number: "1",
                    title: "Nutritional value — 60% of the score",
                    body: "Based on Nutri-Score, the science-backed nutrition label adopted across Europe. It weighs calories, sugar, saturated fat and sodium against protein, fiber and fruit & vegetable content, per 100 g or 100 ml.")

                sectionCard(
                    number: "2",
                    title: "Additives — 30% of the score",
                    body: "Each additive carries a risk level informed by public assessments from food-safety authorities (such as EFSA and IARC) and published research. One risky additive caps the whole score — good macros can't hide it.") {
                    VStack(spacing: 8) {
                        riskRow(color: MTTheme.danger, title: "High risk",
                                caption: "Caps the score at 49")
                        riskRow(color: MTTheme.warning, title: "Moderate risk",
                                caption: "Caps the score at 74")
                        riskRow(color: Color(red: 0.95, green: 0.83, blue: 0.3), title: "Limited risk",
                                caption: "Small penalty")
                        riskRow(color: MTTheme.success, title: "Risk-free",
                                caption: "No penalty")
                    }
                }

                sectionCard(
                    number: "3",
                    title: "Organic — 10% of the score",
                    body: "Products carrying an official organic certification get the final tenth, reflecting the avoidance of chemical pesticides.")

                sectionCard(
                    number: "★",
                    title: "Fit for you — separate from the score",
                    body: "The health score never bends to your profile, so it stays comparable with other apps. Instead, a second read judges the same product against your goal — protein density, energy density, sugar, fiber and sodium thresholds shift depending on whether you're cutting, building, or training for endurance.")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Nutrition data comes from OpenFoodFacts, the open collaborative food database (ODbL). The score is informational — an opinion computed from that data — and isn't medical or dietary advice.")
                        .font(.system(size: 12))
                        .italic()
                        .foregroundStyle(MTTheme.textTertiary)
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(MTBackground().ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func sectionCard(number: String, title: String, body bodyText: String,
                             @ViewBuilder extra: () -> some View = { EmptyView() }) -> some View {
        MTCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text(number)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(MTTheme.accentText)
                        .frame(width: 30, height: 30)
                        .background(MTTheme.voltDim, in: Circle())
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(MTTheme.textPrimary)
                }
                Text(bodyText)
                    .font(.system(size: 13))
                    .foregroundStyle(MTTheme.textSecondary)
                extra()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func riskRow(color: Color, title: String, caption: String) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)
            Spacer()
            Text(caption)
                .font(.system(size: 12))
                .foregroundStyle(MTTheme.textTertiary)
        }
        .padding(10)
        .background(MTTheme.surface2, in: RoundedRectangle(cornerRadius: MTTheme.controlRadius))
    }
}

#Preview {
    ScoringInfoView()
}
