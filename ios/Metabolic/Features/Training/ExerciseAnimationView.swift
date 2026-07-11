import SwiftUI
import MetabolicCore

/// The app's visual showpiece: renders an exercise's authored pose keyframes as a looping
/// animated stick-figure skeleton in a plain SwiftUI `Canvas`, driven by `TimelineView(.animation)`.
/// No image assets — every frame is computed from `Pose` data via `Pose.interpolate`.
struct ExerciseAnimationView: View {
    let exercise: Exercise
    let tint: Color

    init(exercise: Exercise, tint: Color = MTTheme.volt) {
        self.exercise = exercise
        self.tint = tint
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                draw(in: &context, size: size, date: timeline.date)
            }
        }
    }

    // MARK: - Drawing

    private func draw(in context: inout GraphicsContext, size: CGSize, date: Date) {
        let keyframes = exercise.keyframes
        guard !keyframes.isEmpty else { return }

        let side = min(size.width, size.height) * 0.84
        guard side > 0 else { return }

        let pose = currentPose(keyframes: keyframes, date: date)
        let originX = (size.width - side) / 2
        let originY = (size.height - side) / 2

        func point(for joint: Joint) -> CGPoint? {
            guard let p = pose.joints[joint] else { return nil }
            return CGPoint(x: originX + p.x * side, y: originY + p.y * side)
        }

        let boneWidth = side * 0.055
        // Under-100pt renders (library thumbnails, row icons) skip the glow so the figure
        // stays legible; full detail kicks in once there's room for it (hero, session player).
        let showGlow = min(size.width, size.height) > 100
        let activated = Self.activatedRegions(for: exercise.muscleGroups)

        func strokeBone(_ a: Joint, _ b: Joint, region: BoneRegion?) {
            guard let pa = point(for: a), let pb = point(for: b) else { return }
            var path = Path()
            path.move(to: pa)
            path.addLine(to: pb)

            let isInvolved = region.map { activated.contains($0) } ?? false
            let width = isInvolved ? boneWidth * 1.2 : boneWidth
            let opacity = isInvolved ? 1.0 : 0.4

            if isInvolved && showGlow {
                let glowStyle = StrokeStyle(lineWidth: width * 2.2, lineCap: .round, lineJoin: .round)
                context.stroke(path, with: .color(tint.opacity(0.18)), style: glowStyle)
            }
            let style = StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            context.stroke(path, with: .color(tint.opacity(opacity)), style: style)
        }

        // Ground shadow beneath whichever ankle sits lowest on screen (largest y).
        let ankles = [point(for: .leftAnkle), point(for: .rightAnkle)].compactMap { $0 }
        if let lowest = ankles.max(by: { $0.y < $1.y }) {
            let shadowRect = CGRect(
                x: lowest.x - side * 0.16, y: lowest.y - side * 0.03,
                width: side * 0.32, height: side * 0.06
            )
            context.fill(Path(ellipseIn: shadowRect), with: .color(tint.opacity(0.10)))
        }

        // Back limbs first (far side, depth cue). Neck–shoulder links are pure connective
        // tissue in this rig (no dedicated muscle maps to them) so they stay at rest opacity.
        strokeBone(.hip, .leftKnee, region: .hipKnee)
        strokeBone(.leftKnee, .leftAnkle, region: .kneeAnkle)
        strokeBone(.neck, .leftShoulder, region: nil)
        strokeBone(.leftShoulder, .leftElbow, region: .shoulderElbow)
        strokeBone(.leftElbow, .leftWrist, region: .elbowWrist)

        // Torso.
        strokeBone(.neck, .hip, region: .torso)

        // Front limbs (near side).
        strokeBone(.hip, .rightKnee, region: .hipKnee)
        strokeBone(.rightKnee, .rightAnkle, region: .kneeAnkle)
        strokeBone(.neck, .rightShoulder, region: nil)
        strokeBone(.rightShoulder, .rightElbow, region: .shoulderElbow)
        strokeBone(.rightElbow, .rightWrist, region: .elbowWrist)

        // Glute activation reads as a highlighted hip joint, layered on top of the hip–knee bones.
        if Set(exercise.muscleGroups).contains(.glutes), let hipPoint = point(for: .hip) {
            let radius = boneWidth * 0.85
            if showGlow {
                let glowRadius = radius * 1.9
                let glowRect = CGRect(
                    x: hipPoint.x - glowRadius, y: hipPoint.y - glowRadius,
                    width: glowRadius * 2, height: glowRadius * 2
                )
                context.fill(Path(ellipseIn: glowRect), with: .color(tint.opacity(0.18)))
            }
            let rect = CGRect(x: hipPoint.x - radius, y: hipPoint.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(tint))
        }

        // Head, drawn last so it sits on top.
        if let headPoint = point(for: .head), let neckPoint = point(for: .neck) {
            let radius = distance(headPoint, neckPoint) * 0.52
            let headRect = CGRect(
                x: headPoint.x - radius, y: headPoint.y - radius,
                width: radius * 2, height: radius * 2
            )
            context.fill(Path(ellipseIn: headRect), with: .color(tint))
        }
    }

    // MARK: - Muscle-group → bone mapping

    /// Skeleton segments that can be "activated" by an exercise's muscle groups.
    private enum BoneRegion {
        case hipKnee, kneeAnkle, shoulderElbow, elbowWrist, torso
    }

    /// quads/hamstrings/glutes → hip–knee, calves → knee–ankle, chest/shoulders → shoulder–elbow,
    /// arms → elbow–wrist, back/core → the neck–hip torso line, fullBody/cardio → everything.
    private static func activatedRegions(for muscleGroups: [MuscleGroup]) -> Set<BoneRegion> {
        let groups = Set(muscleGroups)
        if !groups.isDisjoint(with: [.fullBody, .cardio]) {
            return [.hipKnee, .kneeAnkle, .shoulderElbow, .elbowWrist, .torso]
        }
        var result: Set<BoneRegion> = []
        if !groups.isDisjoint(with: [.quads, .hamstrings, .glutes]) { result.insert(.hipKnee) }
        if groups.contains(.calves) { result.insert(.kneeAnkle) }
        if !groups.isDisjoint(with: [.chest, .shoulders]) { result.insert(.shoulderElbow) }
        if groups.contains(.arms) { result.insert(.elbowWrist) }
        if !groups.isDisjoint(with: [.back, .core]) { result.insert(.torso) }
        return result
    }

    /// N keyframes split the loop into N equal segments (k0→k1 … k(N-1)→k0 wrap). `date` maps to
    /// a phase in [0,1) via `secondsPerCycle`, then to a segment index + segment-local linear t.
    private func currentPose(keyframes: [Pose], date: Date) -> Pose {
        guard keyframes.count > 1 else { return keyframes[0] }

        let cycle = max(exercise.secondsPerCycle, 0.5)
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle) / cycle
        let segmentCount = keyframes.count
        let scaled = phase * Double(segmentCount)
        let segmentIndex = min(max(Int(scaled), 0), segmentCount - 1)
        let segmentT = scaled - Double(segmentIndex)

        let from = keyframes[segmentIndex]
        let to = keyframes[(segmentIndex + 1) % segmentCount]
        return Pose.interpolate(from: from, to: to, t: segmentT)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

#Preview {
    Group {
        if let exercise = ExerciseLibrary.all.first {
            ExerciseAnimationView(exercise: exercise)
                .frame(width: 240, height: 240)
        } else {
            Text("No exercises")
                .foregroundStyle(MTTheme.textSecondary)
        }
    }
    .padding(20)
    .background(MTTheme.bg)
}
