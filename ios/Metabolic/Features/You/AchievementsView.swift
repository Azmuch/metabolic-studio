import SwiftUI
import SwiftData

/// Trophy/badge wall in the You tab — earned badges light up in the accent color, locked ones stay
/// muted. Computed live from workout logs, streaks, and personal bests.
struct AchievementsView: View {
    @Query private var logs: [WorkoutLog]
    @Query private var personalBests: [PersonalBest]

    private var stats: AchievementStats {
        AchievementStats.compute(logs: logs, personalBests: personalBests)
    }

    private var earnedCount: Int {
        Achievement.all.filter { $0.isEarned(stats) }.count
    }

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Achievement.all) { achievement in
                        badge(achievement, earned: achievement.isEarned(stats))
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(MTBackground().ignoresSafeArea())
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        MTCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(MTTheme.voltDim).frame(width: 56, height: 56)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(MTTheme.accentText)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(earnedCount) of \(Achievement.all.count) unlocked")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text("Keep training to earn them all.")
                        .font(.system(size: 13))
                        .foregroundStyle(MTTheme.textSecondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func badge(_ achievement: Achievement, earned: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(earned ? MTTheme.voltDim : MTTheme.surface2)
                    .frame(width: 60, height: 60)
                Image(systemName: earned ? achievement.symbol : "lock.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(earned ? MTTheme.accentText : MTTheme.textTertiary)
            }
            Text(achievement.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(earned ? MTTheme.textPrimary : MTTheme.textSecondary)
                .multilineTextAlignment(.center)
            Text(achievement.detail)
                .font(.system(size: 11))
                .foregroundStyle(MTTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .background(MTTheme.surface, in: RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous)
                .stroke(earned ? MTTheme.volt.opacity(0.4) : MTTheme.stroke, lineWidth: 1))
        .opacity(earned ? 1 : 0.75)
    }
}

#Preview {
    NavigationStack { AchievementsView() }
        .modelContainer(for: [WorkoutLog.self, PersonalBest.self], inMemory: true)
}
