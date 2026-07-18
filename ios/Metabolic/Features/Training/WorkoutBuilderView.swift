import SwiftUI
import SwiftData
import MetabolicCore

/// Create or edit a user-built workout: name it, add library exercises, tune sets / reps or
/// duration / rest per exercise, reorder or remove, then save. Saved workouts live in SwiftData
/// and run through the same `SessionPlayerView` as generated plans.
struct WorkoutBuilderView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// When editing an existing workout; nil when creating a new one.
    var editing: CustomWorkout?

    @State private var name: String
    @State private var items: [CustomWorkoutItem]
    @State private var showExercisePicker = false
    @State private var level: BuilderLevel = .intermediate

    init(editing: CustomWorkout? = nil) {
        self.editing = editing
        _name = State(initialValue: editing?.name ?? "")
        _items = State(initialValue: editing?.items ?? [])
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !items.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    nameField
                    levelSection

                    if items.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, _ in
                            itemCard(index)
                        }
                    }

                    addButton
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .background(MTBackground().ignoresSafeArea())
            .navigationTitle(editing == nil ? "New Workout" : "Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MTTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(canSave ? MTTheme.accentText : MTTheme.textTertiary)
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerSheet { exercise in
                    items.append(CustomWorkoutItem(exercise: exercise))
                }
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WORKOUT NAME")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(MTTheme.textTertiary)
            TextField("e.g. Monday Push", text: $name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(MTTheme.textPrimary)
                .padding(14)
                .background(MTTheme.surface2, in: RoundedRectangle(cornerRadius: MTTheme.controlRadius))
        }
    }

    /// Preset that rescales every exercise's sets and volume from its library default —
    /// fine-tune any single exercise below afterwards.
    private var levelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LEVEL PRESET")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(MTTheme.textTertiary)
            Picker("Level", selection: $level) {
                ForEach(BuilderLevel.allCases, id: \.self) { lvl in
                    Text(lvl.displayName).tag(lvl)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: level) { _, newValue in
                Haptics.tap()
                for index in items.indices {
                    apply(newValue, to: &items[index])
                }
            }
            Text("Applies to every exercise — fine-tune each one below.")
                .font(.system(size: 12))
                .foregroundStyle(MTTheme.textTertiary)
        }
    }

    private func apply(_ level: BuilderLevel, to item: inout CustomWorkoutItem) {
        guard let exercise = ExerciseLibrary.exercise(id: item.exerciseID) else { return }
        item.sets = level.sets
        switch exercise.kind {
        case .reps(let base):
            item.reps = max(1, Int((Double(base) * level.volumeScale).rounded()))
        case .timed(let base):
            item.seconds = max(5, Int((Double(base) * level.volumeScale).rounded()))
        }
    }

    private var emptyState: some View {
        MTEmptyState(symbol: "dumbbell.fill", title: "No exercises yet",
                     message: "Add exercises from the library to build your session.")
    }

    private func itemCard(_ index: Int) -> some View {
        let item = items[index]
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(exerciseName(item.exerciseID))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MTTheme.textPrimary)
                Spacer(minLength: 0)
                Button {
                    Haptics.tap()
                    items.remove(at: index)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(MTTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                miniStepper("Sets", value: $items[index].sets, range: 1...8)
                if item.isTimed {
                    miniStepper("Sec", value: $items[index].seconds, range: 5...300, step: 5)
                } else {
                    miniStepper("Reps", value: $items[index].reps, range: 1...50)
                }
                miniStepper("Rest", value: $items[index].restSeconds, range: 0...180, step: 5)
                if usesEquipment(item.exerciseID) {
                    miniStepper(loadUnit.capitalized, value: loadBinding(index), range: 0...500, step: 5)
                }
            }
        }
        .padding(14)
        .background(MTTheme.surface, in: RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous)
                .stroke(MTTheme.stroke, lineWidth: 1))
    }

    private func miniStepper(_ label: String, value: Binding<Int>, range: ClosedRange<Int>,
                             step: Int = 1) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MTTheme.textTertiary)
            HStack(spacing: 10) {
                stepButton("minus") {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - step)
                }
                Text("\(value.wrappedValue)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MTTheme.textPrimary)
                    .frame(minWidth: 26)
                stepButton("plus") {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + step)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(MTTheme.accentText)
                .frame(width: 30, height: 30)
                .background(MTTheme.voltDim, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var addButton: some View {
        Button {
            Haptics.tap()
            showExercisePicker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                Text("Add exercise")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(MTTheme.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous)
                    .stroke(MTTheme.stroke, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
        }
        .buttonStyle(.plain)
    }

    private func exerciseName(_ id: String) -> String {
        ExerciseLibrary.exercise(id: id)?.name ?? id
    }

    // MARK: - Load (equipment exercises)

    private var loadUnit: String {
        appState.unitSystem == .imperial ? "lb" : "kg"
    }

    private func usesEquipment(_ id: String) -> Bool {
        guard let exercise = ExerciseLibrary.exercise(id: id) else { return false }
        return !exercise.equipment.contains(.none)
    }

    /// Whole-number load in the user's display unit, stored as kg on the item (0 clears it).
    private func loadBinding(_ index: Int) -> Binding<Int> {
        Binding(
            get: {
                let kg = items[index].loadKg ?? 0
                let display = appState.unitSystem == .imperial ? Units.pounds(fromKg: kg) : kg
                return Int(display.rounded())
            },
            set: { newValue in
                guard newValue > 0 else {
                    items[index].loadKg = nil
                    return
                }
                let value = Double(newValue)
                items[index].loadKg = appState.unitSystem == .imperial
                    ? Units.kg(fromPounds: value) : value
            }
        )
    }

    private func save() {
        guard canSave else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let editing {
            editing.name = trimmed
            editing.items = items
        } else {
            modelContext.insert(CustomWorkout(name: trimmed, items: items))
        }
        Haptics.success()
        dismiss()
    }
}

/// Difficulty preset for the whole workout: sets count + volume scale from library defaults.
private enum BuilderLevel: String, CaseIterable {
    case beginner, intermediate, advanced

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Inter"
        case .advanced: return "Advanced"
        }
    }

    var sets: Int {
        switch self {
        case .beginner: return 2
        case .intermediate: return 3
        case .advanced: return 4
        }
    }

    var volumeScale: Double {
        switch self {
        case .beginner: return 0.7
        case .intermediate: return 1.0
        case .advanced: return 1.3
        }
    }
}

/// Searchable library list for adding an exercise to a custom workout.
private struct ExercisePickerSheet: View {
    let onPick: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [Exercise] {
        let all = ExerciseLibrary.all
        guard !search.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(MTTheme.textTertiary)
                        TextField("Search exercises", text: $search)
                            .font(.system(size: 16))
                            .foregroundStyle(MTTheme.textPrimary)
                    }
                    .padding(12)
                    .background(MTTheme.surface2, in: RoundedRectangle(cornerRadius: MTTheme.controlRadius))

                    ForEach(filtered) { exercise in
                        Button {
                            Haptics.tap()
                            onPick(exercise)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous)
                                        .fill(MTTheme.voltDim)
                                    ExerciseAnimationView(exercise: exercise)
                                        .padding(6)
                                }
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(MTTheme.textPrimary)
                                    if let primary = exercise.muscleGroups.first {
                                        Text(primary.displayName)
                                            .font(.system(size: 12))
                                            .foregroundStyle(MTTheme.textSecondary)
                                    }
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(MTTheme.accentText)
                            }
                            .padding(10)
                            .background(MTTheme.surface, in: RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .background(MTBackground().ignoresSafeArea())
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MTTheme.accentText)
                }
            }
        }
    }
}
