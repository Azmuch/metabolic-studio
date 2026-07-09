import SwiftUI
import MetabolicCore

/// Add-food flow presented from a meal section's "+" button: search / manual entry / AI
/// photo, switched by a segmented control.
struct AddFoodSheet: View {
    let mealType: MealType

    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .search

    private enum Mode: String, CaseIterable {
        case search = "Search"
        case manual = "Manual"
        case photo = "Photo"
    }

    init(mealType: MealType) {
        self.mealType = mealType
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MTSheetHeader(title: "Add to \(mealType.displayName)")
                    .padding(.bottom, 12)

                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                Group {
                    switch mode {
                    case .search: FoodSearchView(mealType: mealType)
                    case .manual: ManualFoodEntryView(mealType: mealType)
                    case .photo: MealPhotoView(mealType: mealType)
                    }
                }
            }
            .background(MTTheme.bg)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(MTTheme.textPrimary)
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    AddFoodSheet(mealType: .lunch)
        .environment(AppState())
        .environment(SubscriptionManager())
        .environment(HealthKitService())
        .modelContainer(
            for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self, ScanRecord.self],
            inMemory: true
        )
}
