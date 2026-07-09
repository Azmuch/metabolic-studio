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
        let boneStyle = StrokeStyle(lineWidth: boneWidth, lineCap: .round, lineJoin: .round)

        func strokeBone(_ a: Joint, _ b: Joint, opacity: Double) {
            guard let pa = point(for: a), let pb = point(for: b) else { return }
            var path = Path()
            path.move(to: pa)
            path.addLine(to: pb)
            context.stroke(path, with: .color(tint.opacity(opacity)), style: boneStyle)
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

        // Back limbs first (far side, depth cue) at reduced opacity.
        strokeBone(.hip, .leftKnee, opacity: 0.55)
        strokeBone(.leftKnee, .leftAnkle, opacity: 0.55)
        strokeBone(.neck, .leftShoulder, opacity: 0.55)
        strokeBone(.leftShoulder, .leftElbow, opacity: 0.55)
        strokeBone(.leftElbow, .leftWrist, opacity: 0.55)

        // Torso at full opacity.
        strokeBone(.neck, .hip, opacity: 1)

        // Front limbs (near side) at full opacity.
        strokeBone(.hip, .rightKnee, opacity: 1)
        strokeBone(.rightKnee, .rightAnkle, opacity: 1)
        strokeBone(.neck, .rightShoulder, opacity: 1)
        strokeBone(.rightShoulder, .rightElbow, opacity: 1)
        strokeBone(.rightElbow, .rightWrist, opacity: 1)

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
