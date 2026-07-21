import Foundation

public struct PosePoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

public enum Joint: String, Codable, CaseIterable, Sendable {
    case head, neck, leftShoulder, rightShoulder, leftElbow, rightElbow,
         leftWrist, rightWrist, hip, leftKnee, rightKnee, leftAnkle, rightAnkle
}

/// One keyframe: every joint MUST be present. Normalized space: x,y ∈ [0,1], y grows downward,
/// figure roughly centered at x=0.5. Bones: head–neck, neck–hip,
/// neck–{left,right}Shoulder, shoulder–elbow–wrist ×2, hip–knee–ankle ×2.
public struct Pose: Codable, Equatable, Sendable {
    public var joints: [Joint: PosePoint]

    public init(_ joints: [Joint: PosePoint]) {
        self.joints = joints
    }

    /// smoothstep t: t² (3 − 2t), then linear joint lerp.
    /// A joint missing from either pose falls back to whichever pose has it.
    public static func interpolate(from: Pose, to: Pose, t: Double) -> Pose {
        let clampedT = min(max(t, 0), 1)
        let smoothT = clampedT * clampedT * (3 - 2 * clampedT)

        var result: [Joint: PosePoint] = [:]
        for joint in Joint.allCases {
            let a = from.joints[joint]
            let b = to.joints[joint]
            switch (a, b) {
            case let (a?, b?):
                let x = a.x + (b.x - a.x) * smoothT
                let y = a.y + (b.y - a.y) * smoothT
                result[joint] = PosePoint(x, y)
            case let (a?, nil):
                result[joint] = a
            case let (nil, b?):
                result[joint] = b
            case (nil, nil):
                continue
            }
        }
        return Pose(result)
    }
}
