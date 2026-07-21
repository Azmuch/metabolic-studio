import Foundation

/// Keyframes for the physical-therapy / mobility block (v2). Same conventions as
/// `ExercisePoses`: 13 joints per frame, normalized coords, y down.
enum MobilityPoses {

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

    static func catCow() -> [Pose] {
        [
            pose(head: PosePoint(0.28, 0.40), neck: PosePoint(0.39, 0.47),
                 lSh: PosePoint(0.40, 0.485), rSh: PosePoint(0.40, 0.455),
                 lEl: PosePoint(0.40, 0.59), rEl: PosePoint(0.40, 0.57),
                 lWr: PosePoint(0.40, 0.71), rWr: PosePoint(0.40, 0.69),
                 hip: PosePoint(0.58, 0.53),
                 lKn: PosePoint(0.58, 0.67), rKn: PosePoint(0.58, 0.65),
                 lAn: PosePoint(0.64, 0.70), rAn: PosePoint(0.64, 0.68)),
            pose(head: PosePoint(0.33, 0.53), neck: PosePoint(0.41, 0.44),
                 lSh: PosePoint(0.42, 0.455), rSh: PosePoint(0.42, 0.425),
                 lEl: PosePoint(0.41, 0.58), rEl: PosePoint(0.41, 0.56),
                 lWr: PosePoint(0.40, 0.71), rWr: PosePoint(0.40, 0.69),
                 hip: PosePoint(0.58, 0.51),
                 lKn: PosePoint(0.58, 0.67), rKn: PosePoint(0.58, 0.65),
                 lAn: PosePoint(0.64, 0.70), rAn: PosePoint(0.64, 0.68)),
        ]
    }

    static func childsPose() -> [Pose] {
        [
            pose(head: PosePoint(0.30, 0.62), neck: PosePoint(0.38, 0.58),
                 lSh: PosePoint(0.39, 0.595), rSh: PosePoint(0.39, 0.565),
                 lEl: PosePoint(0.28, 0.64), rEl: PosePoint(0.28, 0.62),
                 lWr: PosePoint(0.18, 0.68), rWr: PosePoint(0.18, 0.66),
                 hip: PosePoint(0.58, 0.62),
                 lKn: PosePoint(0.61, 0.78), rKn: PosePoint(0.61, 0.76),
                 lAn: PosePoint(0.72, 0.80), rAn: PosePoint(0.72, 0.78)),
            pose(head: PosePoint(0.30, 0.63), neck: PosePoint(0.38, 0.59),
                 lSh: PosePoint(0.39, 0.605), rSh: PosePoint(0.39, 0.575),
                 lEl: PosePoint(0.28, 0.65), rEl: PosePoint(0.28, 0.63),
                 lWr: PosePoint(0.18, 0.68), rWr: PosePoint(0.18, 0.66),
                 hip: PosePoint(0.58, 0.62),
                 lKn: PosePoint(0.61, 0.78), rKn: PosePoint(0.61, 0.76),
                 lAn: PosePoint(0.72, 0.80), rAn: PosePoint(0.72, 0.78)),
        ]
    }

    static func hipFlexorStretch() -> [Pose] {
        [
            pose(head: PosePoint(0.48, 0.24), neck: PosePoint(0.48, 0.34),
                 lSh: PosePoint(0.46, 0.35), rSh: PosePoint(0.50, 0.35),
                 lEl: PosePoint(0.45, 0.46), rEl: PosePoint(0.51, 0.46),
                 lWr: PosePoint(0.44, 0.55), rWr: PosePoint(0.52, 0.55),
                 hip: PosePoint(0.47, 0.58),
                 lKn: PosePoint(0.38, 0.84), rKn: PosePoint(0.60, 0.70),
                 lAn: PosePoint(0.26, 0.86), rAn: PosePoint(0.60, 0.86)),
            pose(head: PosePoint(0.52, 0.24), neck: PosePoint(0.52, 0.34),
                 lSh: PosePoint(0.50, 0.35), rSh: PosePoint(0.54, 0.35),
                 lEl: PosePoint(0.49, 0.46), rEl: PosePoint(0.55, 0.46),
                 lWr: PosePoint(0.48, 0.55), rWr: PosePoint(0.56, 0.55),
                 hip: PosePoint(0.51, 0.58),
                 lKn: PosePoint(0.38, 0.84), rKn: PosePoint(0.62, 0.70),
                 lAn: PosePoint(0.26, 0.86), rAn: PosePoint(0.60, 0.86)),
        ]
    }

    static func standingHamstringStretch() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.47, 0.40), rEl: PosePoint(0.53, 0.40),
                 lWr: PosePoint(0.46, 0.50), rWr: PosePoint(0.54, 0.50),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.63, 0.36), neck: PosePoint(0.57, 0.42),
                 lSh: PosePoint(0.55, 0.43), rSh: PosePoint(0.59, 0.43),
                 lEl: PosePoint(0.57, 0.54), rEl: PosePoint(0.60, 0.54),
                 lWr: PosePoint(0.57, 0.66), rWr: PosePoint(0.59, 0.66),
                 hip: PosePoint(0.42, 0.54),
                 lKn: PosePoint(0.46, 0.69), rKn: PosePoint(0.48, 0.69),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
        ]
    }

    static func shoulderCircles() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.45, 0.40), rEl: PosePoint(0.55, 0.40),
                 lWr: PosePoint(0.43, 0.49), rWr: PosePoint(0.57, 0.49),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.28), rSh: PosePoint(0.52, 0.28),
                 lEl: PosePoint(0.42, 0.36), rEl: PosePoint(0.58, 0.36),
                 lWr: PosePoint(0.38, 0.40), rWr: PosePoint(0.62, 0.40),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.285), rSh: PosePoint(0.52, 0.285),
                 lEl: PosePoint(0.45, 0.32), rEl: PosePoint(0.55, 0.32),
                 lWr: PosePoint(0.44, 0.24), rWr: PosePoint(0.56, 0.24),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
        ]
    }

    static func ankleCircles() -> [Pose] {
        [
            pose(head: PosePoint(0.49, 0.18), neck: PosePoint(0.49, 0.28),
                 lSh: PosePoint(0.47, 0.29), rSh: PosePoint(0.51, 0.29),
                 lEl: PosePoint(0.46, 0.40), rEl: PosePoint(0.52, 0.40),
                 lWr: PosePoint(0.45, 0.50), rWr: PosePoint(0.53, 0.50),
                 hip: PosePoint(0.49, 0.52),
                 lKn: PosePoint(0.48, 0.68), rKn: PosePoint(0.56, 0.55),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.60, 0.68)),
            pose(head: PosePoint(0.49, 0.18), neck: PosePoint(0.49, 0.28),
                 lSh: PosePoint(0.47, 0.29), rSh: PosePoint(0.51, 0.29),
                 lEl: PosePoint(0.46, 0.40), rEl: PosePoint(0.52, 0.40),
                 lWr: PosePoint(0.45, 0.50), rWr: PosePoint(0.53, 0.50),
                 hip: PosePoint(0.49, 0.52),
                 lKn: PosePoint(0.48, 0.68), rKn: PosePoint(0.56, 0.55),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.64, 0.72)),
            pose(head: PosePoint(0.49, 0.18), neck: PosePoint(0.49, 0.28),
                 lSh: PosePoint(0.47, 0.29), rSh: PosePoint(0.51, 0.29),
                 lEl: PosePoint(0.46, 0.40), rEl: PosePoint(0.52, 0.40),
                 lWr: PosePoint(0.45, 0.50), rWr: PosePoint(0.53, 0.50),
                 hip: PosePoint(0.49, 0.52),
                 lKn: PosePoint(0.48, 0.68), rKn: PosePoint(0.56, 0.55),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.58, 0.74)),
        ]
    }

    static func thoracicRotation() -> [Pose] {
        [
            pose(head: PosePoint(0.30, 0.46), neck: PosePoint(0.40, 0.48),
                 lSh: PosePoint(0.41, 0.495), rSh: PosePoint(0.41, 0.465),
                 lEl: PosePoint(0.41, 0.60), rEl: PosePoint(0.45, 0.55),
                 lWr: PosePoint(0.41, 0.71), rWr: PosePoint(0.48, 0.62),
                 hip: PosePoint(0.58, 0.55),
                 lKn: PosePoint(0.58, 0.68), rKn: PosePoint(0.58, 0.65),
                 lAn: PosePoint(0.63, 0.70), rAn: PosePoint(0.63, 0.67)),
            pose(head: PosePoint(0.31, 0.42), neck: PosePoint(0.40, 0.46),
                 lSh: PosePoint(0.41, 0.475), rSh: PosePoint(0.41, 0.445),
                 lEl: PosePoint(0.41, 0.59), rEl: PosePoint(0.38, 0.38),
                 lWr: PosePoint(0.41, 0.71), rWr: PosePoint(0.36, 0.27),
                 hip: PosePoint(0.58, 0.55),
                 lKn: PosePoint(0.58, 0.68), rKn: PosePoint(0.58, 0.65),
                 lAn: PosePoint(0.63, 0.70), rAn: PosePoint(0.63, 0.67)),
        ]
    }

    static func figureFourStretch() -> [Pose] {
        [
            pose(head: PosePoint(0.22, 0.62), neck: PosePoint(0.30, 0.62),
                 lSh: PosePoint(0.31, 0.605), rSh: PosePoint(0.31, 0.635),
                 lEl: PosePoint(0.42, 0.54), rEl: PosePoint(0.42, 0.57),
                 lWr: PosePoint(0.52, 0.48), rWr: PosePoint(0.52, 0.51),
                 hip: PosePoint(0.50, 0.62),
                 lKn: PosePoint(0.60, 0.48), rKn: PosePoint(0.54, 0.44),
                 lAn: PosePoint(0.60, 0.60), rAn: PosePoint(0.64, 0.48)),
            pose(head: PosePoint(0.22, 0.62), neck: PosePoint(0.30, 0.62),
                 lSh: PosePoint(0.31, 0.605), rSh: PosePoint(0.31, 0.635),
                 lEl: PosePoint(0.41, 0.53), rEl: PosePoint(0.41, 0.56),
                 lWr: PosePoint(0.50, 0.46), rWr: PosePoint(0.50, 0.49),
                 hip: PosePoint(0.50, 0.62),
                 lKn: PosePoint(0.58, 0.47), rKn: PosePoint(0.52, 0.43),
                 lAn: PosePoint(0.58, 0.59), rAn: PosePoint(0.62, 0.47)),
        ]
    }

    static func standingCalfStretch() -> [Pose] {
        [
            pose(head: PosePoint(0.42, 0.22), neck: PosePoint(0.44, 0.32),
                 lSh: PosePoint(0.43, 0.33), rSh: PosePoint(0.45, 0.33),
                 lEl: PosePoint(0.53, 0.36), rEl: PosePoint(0.55, 0.36),
                 lWr: PosePoint(0.62, 0.38), rWr: PosePoint(0.64, 0.38),
                 hip: PosePoint(0.40, 0.55),
                 lKn: PosePoint(0.34, 0.70), rKn: PosePoint(0.50, 0.70),
                 lAn: PosePoint(0.26, 0.85), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.44, 0.23), neck: PosePoint(0.46, 0.33),
                 lSh: PosePoint(0.45, 0.34), rSh: PosePoint(0.47, 0.34),
                 lEl: PosePoint(0.55, 0.37), rEl: PosePoint(0.57, 0.37),
                 lWr: PosePoint(0.64, 0.39), rWr: PosePoint(0.66, 0.39),
                 hip: PosePoint(0.42, 0.56),
                 lKn: PosePoint(0.35, 0.70), rKn: PosePoint(0.51, 0.70),
                 lAn: PosePoint(0.26, 0.85), rAn: PosePoint(0.52, 0.84)),
        ]
    }

    static func worldsGreatestStretch() -> [Pose] {
        [
            pose(head: PosePoint(0.50, 0.38), neck: PosePoint(0.50, 0.46),
                 lSh: PosePoint(0.48, 0.47), rSh: PosePoint(0.52, 0.47),
                 lEl: PosePoint(0.44, 0.58), rEl: PosePoint(0.56, 0.36),
                 lWr: PosePoint(0.42, 0.70), rWr: PosePoint(0.58, 0.24),
                 hip: PosePoint(0.42, 0.60),
                 lKn: PosePoint(0.28, 0.76), rKn: PosePoint(0.58, 0.68),
                 lAn: PosePoint(0.16, 0.82), rAn: PosePoint(0.58, 0.84)),
            pose(head: PosePoint(0.51, 0.36), neck: PosePoint(0.51, 0.44),
                 lSh: PosePoint(0.49, 0.45), rSh: PosePoint(0.53, 0.45),
                 lEl: PosePoint(0.45, 0.56), rEl: PosePoint(0.58, 0.32),
                 lWr: PosePoint(0.43, 0.68), rWr: PosePoint(0.60, 0.18),
                 hip: PosePoint(0.42, 0.60),
                 lKn: PosePoint(0.28, 0.76), rKn: PosePoint(0.58, 0.68),
                 lAn: PosePoint(0.16, 0.82), rAn: PosePoint(0.58, 0.84)),
        ]
    }

    static func neckRelease() -> [Pose] {
        [
            pose(head: PosePoint(0.47, 0.19), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.47, 0.40), rEl: PosePoint(0.53, 0.40),
                 lWr: PosePoint(0.46, 0.50), rWr: PosePoint(0.54, 0.50),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.50, 0.18), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.47, 0.40), rEl: PosePoint(0.53, 0.40),
                 lWr: PosePoint(0.46, 0.50), rWr: PosePoint(0.54, 0.50),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
            pose(head: PosePoint(0.53, 0.19), neck: PosePoint(0.50, 0.28),
                 lSh: PosePoint(0.48, 0.29), rSh: PosePoint(0.52, 0.29),
                 lEl: PosePoint(0.47, 0.40), rEl: PosePoint(0.53, 0.40),
                 lWr: PosePoint(0.46, 0.50), rWr: PosePoint(0.54, 0.50),
                 hip: PosePoint(0.50, 0.52),
                 lKn: PosePoint(0.49, 0.68), rKn: PosePoint(0.51, 0.68),
                 lAn: PosePoint(0.48, 0.84), rAn: PosePoint(0.52, 0.84)),
        ]
    }
}
