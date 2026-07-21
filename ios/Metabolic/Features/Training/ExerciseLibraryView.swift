import SwiftUI
import MetabolicCore

/// Full, searchable exercise library — search by name or muscle, filter to saved favorites, tap
/// through to detail.
struct ExerciseLibraryView: View {
    @Environment(AppState.self) private var appState

    @State private var search = ""
    @State private var favoritesOnly = false

    private var filtered: [Exercise] {
        var items = ExerciseLibrary.all
        if favoritesOnly {
            items = items.filter { appState.isFavorite($0.id) }
        }
        let query = search.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            items = items.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(query)
                    || exercise.muscleGroups.contains { $0.displayName.localizedCaseInsensitiveContains(query) }
            }
        }
        return items
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                searchField
                filterRow

                if filtered.isEmpty {
                    MTEmptyState(
                        symbol: favoritesOnly ? "heart" : "magnifyingglass",
                        title: favoritesOnly ? "No saved exercises" : "No matches",
                        message: favoritesOnly
                            ? "Tap the heart on any exercise to save it here."
                            : "Try a different search term.")
                        .padding(.top, 40)
                } else {
                    ForEach(filtered) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            row(exercise)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(MTBackground().ignoresSafeArea())
        .navigationTitle("Exercise Library")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(MTTheme.textTertiary)
            TextField("Search exercises or muscles", text: $search)
                .font(.system(size: 16))
                .foregroundStyle(MTTheme.textPrimary)
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(MTTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(MTTheme.surface2, in: RoundedRectangle(cornerRadius: MTTheme.controlRadius))
    }

    private var filterRow: some View {
        HStack(spacing: 8) {
            filterChip("All", active: !favoritesOnly) { favoritesOnly = false }
            filterChip("Saved", active: favoritesOnly) { favoritesOnly = true }
            Spacer()
            Text("\(filtered.count)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MTTheme.textTertiary)
        }
    }

    private func filterChip(_ text: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(active ? Color.black : MTTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(active ? MTTheme.volt : MTTheme.surface2, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func row(_ exercise: Exercise) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous)
                    .fill(MTTheme.voltDim)
                ExerciseAnimationView(exercise: exercise)
                    .padding(6)
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                Text(exercise.muscleGroups.map(\.displayName).joined(separator: " · "))
                    .font(.system(size: 12))
                    .foregroundStyle(MTTheme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if appState.isFavorite(exercise.id) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(MTTheme.accentText)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MTTheme.textTertiary)
        }
        .padding(10)
        .background(MTTheme.surface, in: RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous)
                .stroke(MTTheme.stroke, lineWidth: 1))
    }
}
