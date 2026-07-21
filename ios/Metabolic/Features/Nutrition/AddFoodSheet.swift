import SwiftUI
import MetabolicCore

/// Add-food flow presented from a meal section's "+" button: search / manual entry / AI
/// photo, switched by a segmented control. Also the entry point for the hand-portion
/// estimator, available from every tab via the header toolbar.
struct AddFoodSheet: View {
    let mealType: MealType

    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .search
    @State private var manualPrefillName: String = ""
    @State private var showHandGuide = false

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
                    case .search:
                        FoodSearchView(mealType: mealType) { typedName in
                            manualPrefillName = typedName
                            withAnimation(.easeInOut(duration: 0.2)) {
                                mode = .manual
                            }
                        }
                    case .manual:
                        ManualFoodEntryView(mealType: mealType, prefillName: manualPrefillName)
                    case .photo:
                        MealPhotoView(mealType: mealType)
                    }
                }
            }
            .background(MTBackground())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.tap()
                        showHandGuide = true
                    } label: {
                        Label("Hand portions", systemImage: "hand.raised.fill")
                            .symbolEffect(.pulse)
                            .phaseAnimator([false, true]) { content, breathe in
                                content.scaleEffect(breathe ? 1.1 : 1.0)
                            } animation: { _ in
                                .easeInOut(duration: 1.1)
                            }
                    }
                    .foregroundStyle(MTTheme.accentText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(MTTheme.textPrimary)
                }
            }
            .sheet(isPresented: $showHandGuide) {
                HandPortionGuide(mealType: mealType)
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
