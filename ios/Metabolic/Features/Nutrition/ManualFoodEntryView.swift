import SwiftUI
import SwiftData
import MetabolicCore

/// Manual tab of `AddFoodSheet`: a clean form for logging a food that isn't in either
/// database — a large centered calorie field plus compact macro/gram fields.
struct ManualFoodEntryView: View {
    let mealType: MealType

    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitService.self) private var healthKit
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var carbsText = ""
    @State private var fatText = ""
    @State private var gramsText = ""
    @State private var showScaleSheet = false
    @FocusState private var nameFocused: Bool

    /// `prefillName` seeds the name field — used when `FoodSearchView` hands off a query
    /// that matched nothing in either database.
    init(mealType: MealType, prefillName: String = "") {
        self.mealType = mealType
        _name = State(initialValue: prefillName)
    }

    private var calories: Double? { Double(caloriesText) }
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (calories ?? 0) > 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                MTCard {
                    VStack(spacing: 16) {
                        TextField("Food name", text: $name)
                            .focused($nameFocused)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(MTTheme.textPrimary)

                        Divider().overlay(MTTheme.stroke)

                        VStack(spacing: 4) {
                            TextField("0", text: $caloriesText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(MTTheme.numberFont(size: 40))
                                .foregroundStyle(MTTheme.textPrimary)
                            Text("calories")
                                .font(.system(size: 13))
                                .foregroundStyle(MTTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                MTCard {
                    VStack(spacing: 14) {
                        macroField("Protein (g)", text: $proteinText, tint: MTTheme.protein)
                        macroField("Carbs (g)", text: $carbsText, tint: MTTheme.carbs)
                        macroField("Fat (g)", text: $fatText, tint: MTTheme.fat)
                        HStack(spacing: 10) {
                            macroField("Grams (optional)", text: $gramsText, tint: MTTheme.textTertiary)
                            Button {
                                Haptics.tap()
                                showScaleSheet = true
                            } label: {
                                Image(systemName: "scalemass.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(MTTheme.volt)
                                    .frame(width: 30, height: 30)
                                    .background(MTTheme.voltDim, in: RoundedRectangle(cornerRadius: 9))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                MTPrimaryButton(title: "Add to \(mealType.displayName)") {
                    save()
                }
                .disabled(!isValid)
                .opacity(isValid ? 1 : 0.4)
            }
            .padding(20)
        }
        .background(MTTheme.bg)
        .onAppear { nameFocused = true }
        .sheet(isPresented: $showScaleSheet) {
            SmartScaleSheet { grams in
                gramsText = String(Int(grams.rounded()))
            }
        }
    }

    private func macroField(_ label: String, text: Binding<String>, tint: Color) -> some View {
        HStack {
            Circle().fill(tint).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(MTTheme.textSecondary)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)
                .frame(width: 70)
        }
    }

    private func save() {
        guard let calories else { return }
        let entry = FoodEntry(
            date: .now, mealType: mealType, name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: nil, calories: calories,
            proteinG: Double(proteinText) ?? 0, carbsG: Double(carbsText) ?? 0, fatG: Double(fatText) ?? 0,
            grams: Double(gramsText), source: .manual
        )
        modelContext.insert(entry)
        Task { await healthKit.saveMeal(entry) }
        Haptics.success()
        dismiss()
    }
}

#Preview {
    ManualFoodEntryView(mealType: .snack)
        .environment(HealthKitService())
        .modelContainer(
            for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self],
            inMemory: true
        )
}
