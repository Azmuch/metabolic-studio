import Foundation

/// Internal keyframe data for `ExerciseLibrary`. Kept separate from the metadata table so the
/// (fairly dense) pose authoring doesn't drown out `ExerciseLibrary.all`.
///
/// Convention: side view facing right unless noted. Every keyframe specifies all 13 joints via
/// the `pose(...)` helper below, so no keyframe can accidentally omit a joint. Coordinates are
/// normalized (x, y ∈ [0,1]), y grows downward, figure centered around x≈0.5. left/right pairs
/// are drawn with a small offset from each other purely for visual clarity (near/far limb), not
/// true 3D perspective.
enum ExercisePoses {

    private static func pose(head: PosePoint, neck: PosePoint, lSh: PosePoint, rSh: PosePoint,
                              lEl: PosePoint, rEl: PosePoint, lWr: PosePoint, rWr: PosePoint,
                              hip: PosePoint, lKn: PosePoint, rKn: PosePoint,
                              lAn: PosePoint, rAn: PosePoint) -> Pose {
        Pose([
            .head: head, .neck: neck, .leftShoulder: lSh, .rightShoulder: rSh,
            .leftElbow: lEl, .rightElbow: rEl, .leftWrist: lWr, .rightWrist: rWr,
            .hip: hip, .leftKnee: lKn, .rightKnee: rKn, .leftAnkle: lAn, .rightAnkle: rAn,
        ])
    }

    // MARK: - Bodyweight, standing/floor

    /// Verbatim worked example from SPEC: side view, standing → bottom of squat.
    static func squat() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.47, 0.40), rEl: PosePoint(0.53, 0.40),
                 lWr: PosePoint(0.46, 0.50), rWr: PosePoint(0.54, 0.50),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.56, 0.31), neck: PosePoint(0.53, 0.40),
                 lSh: PosePoint(0.51, 0.41), rSh: PosePoint(0.55, 0.41),
                 lEl: PosePoint(0.63, 0.42), rEl: PosePoint(0.65, 0.43),
                 lWr: PosePoint(0.74, 0.41), rWr: PosePoint(0.76, 0.42),
                 hip: PosePoint(0.45, 0.63),
                 lKn: PosePoint(0.55, 0.70), rKn: PosePoint(0.57, 0.71),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
        ]
    }

    static func pushUp() -> [Pose] {
        [
            pose(head: PosePoint(0.22, 0.59), neck: PosePoint(0.32, 0.595),
                 lSh: PosePoint(0.33, 0.61), rSh: PosePoint(0.33, 0.58),
                 lEl: PosePoint(0.33, 0.71), rEl: PosePoint(0.33, 0.69),
                 lWr: PosePoint(0.33, 0.82), rWr: PosePoint(0.33, 0.80),
                 hip: PosePoint(0.55, 0.61),
                 lKn: PosePoint(0.70, 0.625), rKn: PosePoint(0.70, 0.615),
                 lAn: PosePoint(0.85, 0.64), rAn: PosePoint(0.85, 0.63)),
            pose(head: PosePoint(0.20, 0.65), neck: PosePoint(0.30, 0.655),
                 lSh: PosePoint(0.31, 0.67), rSh: PosePoint(0.31, 0.64),
                 lEl: PosePoint(0.38, 0.69), rEl: PosePoint(0.38, 0.67),
                 lWr: PosePoint(0.33, 0.82), rWr: PosePoint(0.33, 0.80),
                 hip: PosePoint(0.53, 0.65),
                 lKn: PosePoint(0.69, 0.645), rKn: PosePoint(0.69, 0.635),
                 lAn: PosePoint(0.85, 0.64), rAn: PosePoint(0.85, 0.63)),
        ]
    }

    static func kneePushUp() -> [Pose] {
        [
            pose(head: PosePoint(0.24, 0.60), neck: PosePoint(0.33, 0.605),
                 lSh: PosePoint(0.34, 0.62), rSh: PosePoint(0.34, 0.59),
                 lEl: PosePoint(0.34, 0.72), rEl: PosePoint(0.34, 0.70),
                 lWr: PosePoint(0.34, 0.83), rWr: PosePoint(0.34, 0.81),
                 hip: PosePoint(0.52, 0.62),
                 lKn: PosePoint(0.62, 0.83), rKn: PosePoint(0.62, 0.82),
                 lAn: PosePoint(0.58, 0.78), rAn: PosePoint(0.58, 0.77)),
            pose(head: PosePoint(0.22, 0.66), neck: PosePoint(0.31, 0.665),
                 lSh: PosePoint(0.32, 0.68), rSh: PosePoint(0.32, 0.65),
                 lEl: PosePoint(0.39, 0.70), rEl: PosePoint(0.39, 0.68),
                 lWr: PosePoint(0.34, 0.83), rWr: PosePoint(0.34, 0.81),
                 hip: PosePoint(0.50, 0.68),
                 lKn: PosePoint(0.62, 0.83), rKn: PosePoint(0.62, 0.82),
                 lAn: PosePoint(0.58, 0.78), rAn: PosePoint(0.58, 0.77)),
        ]
    }

    static func lunge() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.16), neck: PosePoint(0.50, 0.26),
                 lSh: PosePoint(0.48, 0.27), rSh: PosePoint(0.52, 0.27),
                 lEl: PosePoint(0.47, 0.36), rEl: PosePoint(0.53, 0.36),
                 lWr: PosePoint(0.46, 0.46), rWr: PosePoint(0.54, 0.46),
                 hip: PosePoint(0.50, 0.50),
                 lKn: PosePoint(0.44, 0.65), rKn: PosePoint(0.56, 0.66),
                 lAn: PosePoint(0.40, 0.82), rAn: PosePoint(0.60, 0.84)),
            pose(head: PosePoint(0.50, 0.24), neck: PosePoint(0.50, 0.34),
                 lSh: PosePoint(0.48, 0.35), rSh: PosePoint(0.52, 0.35),
                 lEl: PosePoint(0.47, 0.45), rEl: PosePoint(0.53, 0.45),
                 lWr: PosePoint(0.46, 0.55), rWr: PosePoint(0.54, 0.55),
                 hip: PosePoint(0.50, 0.58),
                 lKn: PosePoint(0.40, 0.72), rKn: PosePoint(0.58, 0.76),
                 lAn: PosePoint(0.40, 0.85), rAn: PosePoint(0.62, 0.88)),
        ]
    }

    static func gluteBridge() -> [Pose] {
        [
            pose(head: PosePoint(0.22, 0.60), neck: PosePoint(0.30, 0.60),
                 lSh: PosePoint(0.31, 0.585), rSh: PosePoint(0.31, 0.615),
                 lEl: PosePoint(0.31, 0.60), rEl: PosePoint(0.31, 0.62),
                 lWr: PosePoint(0.31, 0.60), rWr: PosePoint(0.31, 0.62),
                 hip: PosePoint(0.50, 0.65),
                 lKn: PosePoint(0.62, 0.53), rKn: PosePoint(0.62, 0.55),
                 lAn: PosePoint(0.68, 0.65), rAn: PosePoint(0.68, 0.67)),
            pose(head: PosePoint(0.22, 0.60), neck: PosePoint(0.30, 0.60),
                 lSh: PosePoint(0.31, 0.585), rSh: PosePoint(0.31, 0.615),
                 lEl: PosePoint(0.31, 0.60), rEl: PosePoint(0.31, 0.62),
                 lWr: PosePoint(0.31, 0.60), rWr: PosePoint(0.31, 0.62),
                 hip: PosePoint(0.50, 0.57),
                 lKn: PosePoint(0.62, 0.53), rKn: PosePoint(0.62, 0.55),
                 lAn: PosePoint(0.68, 0.65), rAn: PosePoint(0.68, 0.67)),
        ]
    }

    static func plank() -> [Pose] {
        [
            pose(head: PosePoint(0.22, 0.59), neck: PosePoint(0.32, 0.595),
                 lSh: PosePoint(0.33, 0.61), rSh: PosePoint(0.33, 0.58),
                 lEl: PosePoint(0.33, 0.71), rEl: PosePoint(0.33, 0.69),
                 lWr: PosePoint(0.33, 0.82), rWr: PosePoint(0.33, 0.80),
                 hip: PosePoint(0.55, 0.61),
                 lKn: PosePoint(0.70, 0.625), rKn: PosePoint(0.70, 0.615),
                 lAn: PosePoint(0.85, 0.64), rAn: PosePoint(0.85, 0.63)),
            pose(head: PosePoint(0.22, 0.595), neck: PosePoint(0.32, 0.60),
                 lSh: PosePoint(0.33, 0.615), rSh: PosePoint(0.33, 0.585),
                 lEl: PosePoint(0.33, 0.715), rEl: PosePoint(0.33, 0.695),
                 lWr: PosePoint(0.33, 0.82), rWr: PosePoint(0.33, 0.80),
                 hip: PosePoint(0.55, 0.615),
                 lKn: PosePoint(0.70, 0.63), rKn: PosePoint(0.70, 0.62),
                 lAn: PosePoint(0.85, 0.64), rAn: PosePoint(0.85, 0.63)),
        ]
    }

    static func sidePlank() -> [Pose] {
        [
            pose(head: PosePoint(0.30, 0.35), neck: PosePoint(0.36, 0.42),
                 lSh: PosePoint(0.37, 0.44), rSh: PosePoint(0.38, 0.42),
                 lEl: PosePoint(0.40, 0.55), rEl: PosePoint(0.34, 0.30),
                 lWr: PosePoint(0.42, 0.65), rWr: PosePoint(0.32, 0.18),
                 hip: PosePoint(0.50, 0.55),
                 lKn: PosePoint(0.62, 0.68), rKn: PosePoint(0.63, 0.67),
                 lAn: PosePoint(0.74, 0.80), rAn: PosePoint(0.75, 0.79)),
            pose(head: PosePoint(0.30, 0.36), neck: PosePoint(0.36, 0.43),
                 lSh: PosePoint(0.37, 0.45), rSh: PosePoint(0.38, 0.43),
                 lEl: PosePoint(0.40, 0.56), rEl: PosePoint(0.34, 0.31),
                 lWr: PosePoint(0.42, 0.66), rWr: PosePoint(0.32, 0.19),
                 hip: PosePoint(0.50, 0.56),
                 lKn: PosePoint(0.62, 0.69), rKn: PosePoint(0.63, 0.68),
                 lAn: PosePoint(0.74, 0.80), rAn: PosePoint(0.75, 0.79)),
        ]
    }

    static func mountainClimber() -> [Pose] {
        [
            pose(head: PosePoint(0.22, 0.59), neck: PosePoint(0.32, 0.595),
                 lSh: PosePoint(0.33, 0.61), rSh: PosePoint(0.33, 0.58),
                 lEl: PosePoint(0.33, 0.71), rEl: PosePoint(0.33, 0.69),
                 lWr: PosePoint(0.33, 0.82), rWr: PosePoint(0.33, 0.80),
                 hip: PosePoint(0.55, 0.61),
                 lKn: PosePoint(0.70, 0.625), rKn: PosePoint(0.70, 0.615),
                 lAn: PosePoint(0.85, 0.64), rAn: PosePoint(0.85, 0.63)),
            pose(head: PosePoint(0.22, 0.59), neck: PosePoint(0.32, 0.595),
                 lSh: PosePoint(0.33, 0.61), rSh: PosePoint(0.33, 0.58),
                 lEl: PosePoint(0.33, 0.71), rEl: PosePoint(0.33, 0.69),
                 lWr: PosePoint(0.33, 0.82), rWr: PosePoint(0.33, 0.80),
                 hip: PosePoint(0.53, 0.60),
                 lKn: PosePoint(0.40, 0.62), rKn: PosePoint(0.70, 0.615),
                 lAn: PosePoint(0.35, 0.72), rAn: PosePoint(0.85, 0.63)),
        ]
    }

    static func jumpingJack() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.42, 0.30), rSh: PosePoint(0.58, 0.30),
                 lEl: PosePoint(0.40, 0.42), rEl: PosePoint(0.60, 0.42),
                 lWr: PosePoint(0.39, 0.53), rWr: PosePoint(0.61, 0.53),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.47, 0.68), rKn: PosePoint(0.53, 0.68),
                 lAn: PosePoint(0.47, 0.84), rAn: PosePoint(0.53, 0.84)),
            pose(head: PosePoint(0.50, 0.16), neck: PosePoint(0.50, 0.26),
                 lSh: PosePoint(0.42, 0.28), rSh: PosePoint(0.58, 0.28),
                 lEl: PosePoint(0.30, 0.16), rEl: PosePoint(0.70, 0.16),
                 lWr: PosePoint(0.24, 0.06), rWr: PosePoint(0.76, 0.06),
                 hip: PosePoint(0.50, 0.50),
                 lKn: PosePoint(0.38, 0.67), rKn: PosePoint(0.62, 0.67),
                 lAn: PosePoint(0.32, 0.84), rAn: PosePoint(0.68, 0.84)),
        ]
    }

    static func highKnees() -> [Pose] {
        [
            pose(head: PosePoint(0.51, 0.17), neck: PosePoint(0.51, 0.27),
                 lSh: PosePoint(0.49, 0.28), rSh: PosePoint(0.53, 0.28),
                 lEl: PosePoint(0.48, 0.38), rEl: PosePoint(0.58, 0.32),
                 lWr: PosePoint(0.47, 0.47), rWr: PosePoint(0.62, 0.24),
                 hip: PosePoint(0.51, 0.51),
                 lKn: PosePoint(0.50, 0.67), rKn: PosePoint(0.58, 0.40),
                 lAn: PosePoint(0.49, 0.84), rAn: PosePoint(0.60, 0.55)),
            pose(head: PosePoint(0.51, 0.17), neck: PosePoint(0.51, 0.27),
                 lSh: PosePoint(0.49, 0.28), rSh: PosePoint(0.53, 0.28),
                 lEl: PosePoint(0.44, 0.32), rEl: PosePoint(0.54, 0.38),
                 lWr: PosePoint(0.40, 0.24), rWr: PosePoint(0.55, 0.47),
                 hip: PosePoint(0.51, 0.51),
                 lKn: PosePoint(0.44, 0.40), rKn: PosePoint(0.52, 0.67),
                 lAn: PosePoint(0.42, 0.55), rAn: PosePoint(0.53, 0.84)),
        ]
    }

    static func burpee() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.47, 0.40), rEl: PosePoint(0.53, 0.40),
                 lWr: PosePoint(0.46, 0.50), rWr: PosePoint(0.54, 0.50),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.54, 0.35), neck: PosePoint(0.52, 0.42),
                 lSh: PosePoint(0.50, 0.43), rSh: PosePoint(0.54, 0.43),
                 lEl: PosePoint(0.55, 0.55), rEl: PosePoint(0.58, 0.56),
                 lWr: PosePoint(0.58, 0.68), rWr: PosePoint(0.60, 0.69),
                 hip: PosePoint(0.47, 0.60),
                 lKn: PosePoint(0.53, 0.68), rKn: PosePoint(0.55, 0.69),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.24, 0.58), neck: PosePoint(0.33, 0.585),
                 lSh: PosePoint(0.34, 0.60), rSh: PosePoint(0.34, 0.57),
                 lEl: PosePoint(0.34, 0.70), rEl: PosePoint(0.34, 0.68),
                 lWr: PosePoint(0.34, 0.81), rWr: PosePoint(0.34, 0.79),
                 hip: PosePoint(0.56, 0.60),
                 lKn: PosePoint(0.72, 0.615), rKn: PosePoint(0.72, 0.605),
                 lAn: PosePoint(0.87, 0.63), rAn: PosePoint(0.87, 0.62)),
            pose(head: PosePoint(0.50, 0.10), neck: PosePoint(0.50, 0.20),
                 lSh: PosePoint(0.47, 0.21), rSh: PosePoint(0.53, 0.21),
                 lEl: PosePoint(0.42, 0.10), rEl: PosePoint(0.58, 0.10),
                 lWr: PosePoint(0.38, 0.02), rWr: PosePoint(0.62, 0.02),
                 hip: PosePoint(0.50, 0.44),
                 lKn: PosePoint(0.49, 0.60), rKn: PosePoint(0.51, 0.60),
                 lAn: PosePoint(0.48, 0.76), rAn: PosePoint(0.52, 0.76)),
        ]
    }

    static func birdDog() -> [Pose] {
        [
            pose(head: PosePoint(0.30, 0.45), neck: PosePoint(0.40, 0.48),
                 lSh: PosePoint(0.41, 0.495), rSh: PosePoint(0.41, 0.465),
                 lEl: PosePoint(0.41, 0.60), rEl: PosePoint(0.41, 0.57),
                 lWr: PosePoint(0.41, 0.71), rWr: PosePoint(0.41, 0.68),
                 hip: PosePoint(0.58, 0.55),
                 lKn: PosePoint(0.58, 0.68), rKn: PosePoint(0.58, 0.65),
                 lAn: PosePoint(0.63, 0.70), rAn: PosePoint(0.63, 0.67)),
            pose(head: PosePoint(0.28, 0.42), neck: PosePoint(0.38, 0.45),
                 lSh: PosePoint(0.39, 0.465), rSh: PosePoint(0.39, 0.435),
                 lEl: PosePoint(0.39, 0.57), rEl: PosePoint(0.30, 0.40),
                 lWr: PosePoint(0.39, 0.68), rWr: PosePoint(0.20, 0.38),
                 hip: PosePoint(0.58, 0.55),
                 lKn: PosePoint(0.72, 0.62), rKn: PosePoint(0.58, 0.65),
                 lAn: PosePoint(0.85, 0.60), rAn: PosePoint(0.63, 0.67)),
        ]
    }

    static func deadBug() -> [Pose] {
        [
            pose(head: PosePoint(0.22, 0.60), neck: PosePoint(0.30, 0.60),
                 lSh: PosePoint(0.31, 0.585), rSh: PosePoint(0.31, 0.615),
                 lEl: PosePoint(0.31, 0.475), rEl: PosePoint(0.31, 0.505),
                 lWr: PosePoint(0.31, 0.37), rWr: PosePoint(0.31, 0.40),
                 hip: PosePoint(0.50, 0.60),
                 lKn: PosePoint(0.50, 0.47), rKn: PosePoint(0.50, 0.49),
                 lAn: PosePoint(0.63, 0.47), rAn: PosePoint(0.63, 0.49)),
            pose(head: PosePoint(0.22, 0.60), neck: PosePoint(0.30, 0.60),
                 lSh: PosePoint(0.31, 0.585), rSh: PosePoint(0.31, 0.615),
                 lEl: PosePoint(0.31, 0.475), rEl: PosePoint(0.18, 0.55),
                 lWr: PosePoint(0.31, 0.37), rWr: PosePoint(0.10, 0.58),
                 hip: PosePoint(0.50, 0.60),
                 lKn: PosePoint(0.50, 0.47), rKn: PosePoint(0.68, 0.58),
                 lAn: PosePoint(0.63, 0.47), rAn: PosePoint(0.85, 0.60)),
        ]
    }

    static func calfRaise() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.47, 0.40), rEl: PosePoint(0.53, 0.40),
                 lWr: PosePoint(0.46, 0.50), rWr: PosePoint(0.54, 0.50),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.50, 0.17), neck: PosePoint(0.50, 0.27),
                 lSh: PosePoint(0.48, 0.28), rSh: PosePoint(0.52, 0.28),
                 lEl: PosePoint(0.47, 0.39), rEl: PosePoint(0.53, 0.39),
                 lWr: PosePoint(0.46, 0.49), rWr: PosePoint(0.54, 0.49),
                 hip: PosePoint(0.50, 0.51),
                 lKn: PosePoint(0.49, 0.665), rKn: PosePoint(0.51, 0.665),
                 lAn: PosePoint(0.48, 0.815), rAn: PosePoint(0.52, 0.815)),
        ]
    }

    static func wallSit() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.28), neck: PosePoint(0.50, 0.38),
                 lSh: PosePoint(0.48, 0.39), rSh: PosePoint(0.52, 0.39),
                 lEl: PosePoint(0.47, 0.49), rEl: PosePoint(0.53, 0.49),
                 lWr: PosePoint(0.46, 0.58), rWr: PosePoint(0.54, 0.58),
                 hip: PosePoint(0.50, 0.60),
                 lKn: PosePoint(0.64, 0.60), rKn: PosePoint(0.66, 0.61),
                 lAn: PosePoint(0.64, 0.75), rAn: PosePoint(0.66, 0.76)),
            pose(head: PosePoint(0.50, 0.285), neck: PosePoint(0.50, 0.385),
                 lSh: PosePoint(0.48, 0.395), rSh: PosePoint(0.52, 0.395),
                 lEl: PosePoint(0.47, 0.495), rEl: PosePoint(0.53, 0.495),
                 lWr: PosePoint(0.46, 0.585), rWr: PosePoint(0.54, 0.585),
                 hip: PosePoint(0.50, 0.605),
                 lKn: PosePoint(0.64, 0.605), rKn: PosePoint(0.66, 0.615),
                 lAn: PosePoint(0.64, 0.75), rAn: PosePoint(0.66, 0.76)),
        ]
    }

    static func superman() -> [Pose] {
        [
            pose(head: PosePoint(0.20, 0.60), neck: PosePoint(0.30, 0.605),
                 lSh: PosePoint(0.31, 0.62), rSh: PosePoint(0.31, 0.59),
                 lEl: PosePoint(0.16, 0.60), rEl: PosePoint(0.16, 0.57),
                 lWr: PosePoint(0.04, 0.60), rWr: PosePoint(0.04, 0.57),
                 hip: PosePoint(0.55, 0.62),
                 lKn: PosePoint(0.70, 0.635), rKn: PosePoint(0.70, 0.625),
                 lAn: PosePoint(0.85, 0.65), rAn: PosePoint(0.85, 0.64)),
            pose(head: PosePoint(0.18, 0.53), neck: PosePoint(0.29, 0.565),
                 lSh: PosePoint(0.30, 0.58), rSh: PosePoint(0.30, 0.55),
                 lEl: PosePoint(0.14, 0.50), rEl: PosePoint(0.14, 0.47),
                 lWr: PosePoint(0.02, 0.44), rWr: PosePoint(0.02, 0.41),
                 hip: PosePoint(0.55, 0.60),
                 lKn: PosePoint(0.71, 0.585), rKn: PosePoint(0.71, 0.575),
                 lAn: PosePoint(0.87, 0.56), rAn: PosePoint(0.87, 0.55)),
        ]
    }

    // MARK: - Equipment

    static func dbRow() -> [Pose] {
        [
            pose(head: PosePoint(0.24, 0.38), neck: PosePoint(0.32, 0.42),
                 lSh: PosePoint(0.34, 0.44), rSh: PosePoint(0.34, 0.41),
                 lEl: PosePoint(0.35, 0.55), rEl: PosePoint(0.35, 0.52),
                 lWr: PosePoint(0.36, 0.66), rWr: PosePoint(0.36, 0.63),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.52, 0.68), rKn: PosePoint(0.54, 0.68),
                 lAn: PosePoint(0.50, 0.84), rAn: PosePoint(0.54, 0.84)),
            pose(head: PosePoint(0.24, 0.38), neck: PosePoint(0.32, 0.42),
                 lSh: PosePoint(0.34, 0.44), rSh: PosePoint(0.34, 0.41),
                 lEl: PosePoint(0.44, 0.46), rEl: PosePoint(0.44, 0.43),
                 lWr: PosePoint(0.40, 0.50), rWr: PosePoint(0.40, 0.47),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.52, 0.68), rKn: PosePoint(0.54, 0.68),
                 lAn: PosePoint(0.50, 0.84), rAn: PosePoint(0.54, 0.84)),
        ]
    }

    static func dbShoulderPress() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.44, 0.34), rEl: PosePoint(0.56, 0.34),
                 lWr: PosePoint(0.44, 0.24), rWr: PosePoint(0.56, 0.24),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.42, 0.20), rEl: PosePoint(0.58, 0.20),
                 lWr: PosePoint(0.40, 0.08), rWr: PosePoint(0.60, 0.08),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
        ]
    }

    static func dbCurl() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.47, 0.40), rEl: PosePoint(0.53, 0.40),
                 lWr: PosePoint(0.46, 0.50), rWr: PosePoint(0.54, 0.50),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.47, 0.40), rEl: PosePoint(0.53, 0.40),
                 lWr: PosePoint(0.44, 0.30), rWr: PosePoint(0.56, 0.30),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
        ]
    }

    static func gobletSquat() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.46, 0.38), rEl: PosePoint(0.54, 0.38),
                 lWr: PosePoint(0.48, 0.44), rWr: PosePoint(0.52, 0.44),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.51, 0.33), neck: PosePoint(0.51, 0.42),
                 lSh: PosePoint(0.49, 0.43), rSh: PosePoint(0.53, 0.43),
                 lEl: PosePoint(0.48, 0.52), rEl: PosePoint(0.54, 0.52),
                 lWr: PosePoint(0.49, 0.58), rWr: PosePoint(0.53, 0.58),
                 hip: PosePoint(0.48, 0.64),
                 lKn: PosePoint(0.53, 0.70), rKn: PosePoint(0.56, 0.71),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
        ]
    }

    static func dbRomanianDeadlift() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.47, 0.40), rEl: PosePoint(0.53, 0.40),
                 lWr: PosePoint(0.46, 0.50), rWr: PosePoint(0.54, 0.50),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.62, 0.34), neck: PosePoint(0.56, 0.40),
                 lSh: PosePoint(0.54, 0.41), rSh: PosePoint(0.58, 0.41),
                 lEl: PosePoint(0.56, 0.54), rEl: PosePoint(0.60, 0.54),
                 lWr: PosePoint(0.57, 0.66), rWr: PosePoint(0.61, 0.66),
                 hip: PosePoint(0.42, 0.54),
                 lKn: PosePoint(0.47, 0.69), rKn: PosePoint(0.49, 0.69),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
        ]
    }

    static func lateralRaise() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.47, 0.40), rEl: PosePoint(0.53, 0.40),
                 lWr: PosePoint(0.46, 0.50), rWr: PosePoint(0.54, 0.50),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.34, 0.28), rEl: PosePoint(0.66, 0.28),
                 lWr: PosePoint(0.24, 0.29), rWr: PosePoint(0.76, 0.29),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
        ]
    }

    static func kbSwing() -> [Pose] {
        [
            pose(head: PosePoint(0.62, 0.36), neck: PosePoint(0.56, 0.42),
                 lSh: PosePoint(0.54, 0.43), rSh: PosePoint(0.58, 0.43),
                 lEl: PosePoint(0.56, 0.54), rEl: PosePoint(0.60, 0.54),
                 lWr: PosePoint(0.55, 0.66), rWr: PosePoint(0.59, 0.66),
                 hip: PosePoint(0.42, 0.56),
                 lKn: PosePoint(0.48, 0.69), rKn: PosePoint(0.50, 0.69),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.46, 0.38), rEl: PosePoint(0.54, 0.38),
                 lWr: PosePoint(0.47, 0.42), rWr: PosePoint(0.53, 0.42),
                 hip: PosePoint(0.50, 0.50),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
        ]
    }

    static func bandRow() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.44, 0.36), rEl: PosePoint(0.56, 0.36),
                 lWr: PosePoint(0.36, 0.38), rWr: PosePoint(0.64, 0.38),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.40, 0.34), rEl: PosePoint(0.60, 0.34),
                 lWr: PosePoint(0.42, 0.38), rWr: PosePoint(0.58, 0.38),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
        ]
    }

    static func bandPullApart() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.44, 0.29), rEl: PosePoint(0.56, 0.29),
                 lWr: PosePoint(0.42, 0.29), rWr: PosePoint(0.58, 0.29),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.32, 0.29), rEl: PosePoint(0.68, 0.29),
                 lWr: PosePoint(0.22, 0.29), rWr: PosePoint(0.78, 0.29),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
        ]
    }

    static func pullUp() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.30), neck: PosePoint(0.50, 0.38),
                 lSh: PosePoint(0.46, 0.39), rSh: PosePoint(0.54, 0.39),
                 lEl: PosePoint(0.42, 0.28), rEl: PosePoint(0.58, 0.28),
                 lWr: PosePoint(0.40, 0.16), rWr: PosePoint(0.60, 0.16),
                 hip: PosePoint(0.50, 0.58),
                 lKn: PosePoint(0.49, 0.74), rKn: PosePoint(0.51, 0.74),
                 lAn: PosePoint(0.48, 0.90), rAn: PosePoint(0.52, 0.90)),
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.24),
                 lSh: PosePoint(0.46, 0.25), rSh: PosePoint(0.54, 0.25),
                 lEl: PosePoint(0.40, 0.24), rEl: PosePoint(0.60, 0.24),
                 lWr: PosePoint(0.40, 0.16), rWr: PosePoint(0.60, 0.16),
                 hip: PosePoint(0.50, 0.44),
                 lKn: PosePoint(0.49, 0.60), rKn: PosePoint(0.51, 0.60),
                 lAn: PosePoint(0.48, 0.76), rAn: PosePoint(0.52, 0.76)),
        ]
    }
}
