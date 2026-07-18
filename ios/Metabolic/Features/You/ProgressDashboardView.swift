import SwiftUI
import SwiftData
import Charts
import MetabolicCore

/// Progress: the app's proof-of-work. Weekly training volume, session counts, body-weight
/// trend, and the personal-best board — all computed on-device from local logs. This screen
/// is the retention loop: it's where a user sees that the work is working.
struct ProgressDashboardView: View {
    @Environment(AppState.self) private var appState

    @Query(sort: \WorkoutLog.date) private var workouts: [WorkoutLog]
    @Query(sort: \WeightEntry.date) private var weights: [WeightEntry]
    @Query private var personalBests: [PersonalBest]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if workouts.isEmpty && weights.isEmpty {
                    emptyState
                } else {
                    statStrip
                    volumeCard
                    sessionsCard
                    weightCard
                    personalBestsCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .background(MTBackground().ignoresSafeArea())
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Aggregation

    private struct WeekPoint: Identifiable {
        let weekStart: Date
        let volumeKg: Double
        let sessions: Int
        let minutes: Int
        var id: Date { weekStart }
    }

    /// Last 12 calendar weeks that have any training, oldest first.
    private var weekPoints: [WeekPoint] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: workouts) { log in
            cal.dateInterval(of: .weekOfYear, for: log.date)?.start ?? cal.startOfDay(for: log.date)
        }
        return grouped
            .map { start, logs in
                WeekPoint(weekStart: start,
                          volumeKg: logs.reduce(0) { $0 + $1.totalVolumeKg },
                          sessions: logs.count,
                          minutes: logs.reduce(0) { $0 + $1.minutes })
            }
            .sorted { $0.weekStart < $1.weekStart }
            .suffix(12)
            .map { $0 }
    }

    private var thisWeek: WeekPoint? {
        guard let start = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start else {
            return nil
        }
        return weekPoints.first { $0.weekStart == start }
    }

    private var usesImperial: Bool { appState.unitSystem == .imperial }
    private var weightUnit: String { usesImperial ? "lb" : "kg" }

    private func displayWeight(_ kg: Double) -> Double {
        usesImperial ? Units.pounds(fromKg: kg) : kg
    }

    // MARK: - Sections

    private var emptyState: some View {
        MTCard {
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(MTTheme.accentText)
                Text("Your progress will live here")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MTTheme.textPrimary)
                Text("Finish a session or log a weight and the charts start drawing themselves.")
                    .font(.system(size: 13))
                    .foregroundStyle(MTTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private var statStrip: some View {
        MTCard {
            HStack(spacing: 0) {
                statColumn(value: "\(thisWeek?.sessions ?? 0)", label: "This week")
                divider
                statColumn(
                    value: volumeText(thisWeek?.volumeKg ?? 0),
                    label: "Volume · \(weightUnit)")
                divider
                statColumn(value: "\(workouts.count)", label: "All time")
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(MTTheme.stroke).frame(width: 1, height: 40)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(MTTheme.numberFont(size: 22))
                .foregroundStyle(MTTheme.textPrimary)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(MTTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func volumeText(_ kg: Double) -> String {
        let value = displayWeight(kg)
        return value >= 10_000 ? String(format: "%.1fk", value / 1000) : "\(Int(value.rounded()))"
    }

    /// Σ reps × load per week — the hypertrophy trendline.
    @ViewBuilder
    private var volumeCard: some View {
        let points = weekPoints.filter { $0.volumeKg > 0 }
        if !points.isEmpty {
            chartCard("TRAINING VOLUME · \(weightUnit.uppercased()) / WEEK") {
                Chart(points) { point in
                    BarMark(
                        x: .value("Week", point.weekStart, unit: .weekOfYear),
                        y: .value("Volume", displayWeight(point.volumeKg))
                    )
                    .foregroundStyle(MTTheme.accentText)
                    .cornerRadius(4)
                }
            }
        }
    }

    @ViewBuilder
    private var sessionsCard: some View {
        if !weekPoints.isEmpty {
            chartCard("SESSIONS / WEEK") {
                Chart(weekPoints) { point in
                    BarMark(
                        x: .value("Week", point.weekStart, unit: .weekOfYear),
                        y: .value("Sessions", point.sessions)
                    )
                    .foregroundStyle(MTTheme.water)
                    .cornerRadius(4)
                }
            }
        }
    }

    @ViewBuilder
    private var weightCard: some View {
        if weights.count >= 2 {
            chartCard("BODY WEIGHT · \(weightUnit.uppercased())") {
                Chart(weights, id: \.date) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", displayWeight(entry.weightKg))
                    )
                    .foregroundStyle(MTTheme.accentText)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", displayWeight(entry.weightKg))
                    )
                    .foregroundStyle(MTTheme.accentText)
                    .symbolSize(20)
                }
                .chartYScale(domain: .automatic(includesZero: false))
            }
        }
    }

    private func chartCard(_ title: String, @ViewBuilder chart: () -> some View) -> some View {
        MTCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                chart()
                    .frame(height: 160)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var personalBestsCard: some View {
        let records = personalBests
            .filter(\.hasAnyRecord)
            .sorted { $0.updatedAt > $1.updatedAt }
        if !records.isEmpty {
            MTCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("PERSONAL BESTS")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(MTTheme.textTertiary)
                    VStack(spacing: 0) {
                        ForEach(records, id: \.exerciseID) { record in
                            pbRow(record)
                            if record.exerciseID != records.last?.exerciseID {
                                Divider().overlay(MTTheme.stroke)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func pbRow(_ record: PersonalBest) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MTTheme.accentText)
                .frame(width: 32, height: 32)
                .background(MTTheme.voltDim, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(ExerciseLibrary.exercise(id: record.exerciseID)?.name ?? record.exerciseID)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MTTheme.textPrimary)
                Text(pbSummary(record))
                    .font(.system(size: 12))
                    .foregroundStyle(MTTheme.textSecondary)
            }
            Spacer(minLength: 0)
            Text(record.updatedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 11))
                .foregroundStyle(MTTheme.textTertiary)
        }
        .padding(.vertical, 8)
    }

    private func pbSummary(_ record: PersonalBest) -> String {
        var parts: [String] = []
        if record.bestReps > 0 { parts.append("\(record.bestReps) reps") }
        if record.bestLoadKg > 0 {
            parts.append("\(Int(displayWeight(record.bestLoadKg).rounded())) \(weightUnit)")
        }
        if record.bestHoldSeconds > 0 { parts.append("\(record.bestHoldSeconds)s hold") }
        return parts.joined(separator: " · ")
    }
}

#Preview {
    NavigationStack {
        ProgressDashboardView()
            .environment(AppState())
            .modelContainer(
                for: [FoodEntry.self, WaterEntry.self, WorkoutLog.self, WeightEntry.self,
                      ScanRecord.self, CustomWorkout.self, PersonalBest.self],
                inMemory: true
            )
    }
}
