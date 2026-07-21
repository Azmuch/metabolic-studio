import SwiftUI
import MetabolicCore

/// Compact front + back body silhouette pair. Regions light up in volt when the corresponding
/// `MuscleGroup` is present in `highlighted`; everything else stays a dim `surface2` outline.
/// Meant to sit inside a card under an exercise's hero animation.
struct MuscleMapView: View {
    let highlighted: [MuscleGroup]

    init(highlighted: [MuscleGroup]) {
        self.highlighted = highlighted
    }

    private var activeGroups: Set<MuscleGroup> { Set(highlighted) }

    var body: some View {
        HStack(spacing: 20) {
            figure(regions: Self.frontRegions, label: "FRONT")
            figure(regions: Self.backRegions, label: "BACK")
        }
        .frame(height: 120)
    }

    // MARK: - Figure

    private func figure(regions: [MuscleRegion], label: String) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(MTTheme.surface2)
                        .overlay(Circle().stroke(MTTheme.stroke, lineWidth: 1))
                        .frame(width: geo.size.width * 0.34, height: geo.size.width * 0.34)
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.08)

                    ForEach(regions) { region in
                        regionShape(region, in: geo.size)
                    }
                }
            }
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(MTTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func regionShape(_ region: MuscleRegion, in size: CGSize) -> some View {
        let isOn = activeGroups.contains(region.group)
        let fill = isOn ? MTTheme.volt.opacity(0.55) : MTTheme.surface2
        let stroke = isOn ? MTTheme.volt : MTTheme.stroke
        let width = size.width * region.wFrac
        let height = size.height * region.hFrac

        return Group {
            switch region.shape {
            case .capsule:
                Capsule()
                    .fill(fill)
                    .overlay(Capsule().stroke(stroke, lineWidth: 1))
            case .roundedRect:
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fill)
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(stroke, lineWidth: 1))
            }
        }
        .frame(width: width, height: height)
        .position(x: size.width * region.xFrac, y: size.height * region.yFrac)
    }

    // MARK: - Region layout (fractions of each figure's own drawing area)

    private struct MuscleRegion: Identifiable {
        let id = UUID()
        let group: MuscleGroup
        let shape: RegionShape
        let xFrac: CGFloat
        let yFrac: CGFloat
        let wFrac: CGFloat
        let hFrac: CGFloat

        enum RegionShape { case capsule, roundedRect }
    }

    private static let frontRegions: [MuscleRegion] = [
        MuscleRegion(group: .shoulders, shape: .capsule, xFrac: 0.20, yFrac: 0.20, wFrac: 0.30, hFrac: 0.08),
        MuscleRegion(group: .shoulders, shape: .capsule, xFrac: 0.80, yFrac: 0.20, wFrac: 0.30, hFrac: 0.08),
        MuscleRegion(group: .chest, shape: .roundedRect, xFrac: 0.50, yFrac: 0.32, wFrac: 0.52, hFrac: 0.14),
        MuscleRegion(group: .arms, shape: .capsule, xFrac: 0.12, yFrac: 0.40, wFrac: 0.16, hFrac: 0.24),
        MuscleRegion(group: .arms, shape: .capsule, xFrac: 0.88, yFrac: 0.40, wFrac: 0.16, hFrac: 0.24),
        MuscleRegion(group: .core, shape: .roundedRect, xFrac: 0.50, yFrac: 0.47, wFrac: 0.40, hFrac: 0.12),
        MuscleRegion(group: .quads, shape: .capsule, xFrac: 0.34, yFrac: 0.68, wFrac: 0.22, hFrac: 0.20),
        MuscleRegion(group: .quads, shape: .capsule, xFrac: 0.66, yFrac: 0.68, wFrac: 0.22, hFrac: 0.20),
        MuscleRegion(group: .calves, shape: .capsule, xFrac: 0.34, yFrac: 0.88, wFrac: 0.17, hFrac: 0.16),
        MuscleRegion(group: .calves, shape: .capsule, xFrac: 0.66, yFrac: 0.88, wFrac: 0.17, hFrac: 0.16),
    ]

    private static let backRegions: [MuscleRegion] = [
        MuscleRegion(group: .back, shape: .roundedRect, xFrac: 0.50, yFrac: 0.28, wFrac: 0.54, hFrac: 0.28),
        MuscleRegion(group: .glutes, shape: .roundedRect, xFrac: 0.50, yFrac: 0.47, wFrac: 0.38, hFrac: 0.12),
        MuscleRegion(group: .hamstrings, shape: .capsule, xFrac: 0.34, yFrac: 0.68, wFrac: 0.22, hFrac: 0.20),
        MuscleRegion(group: .hamstrings, shape: .capsule, xFrac: 0.66, yFrac: 0.68, wFrac: 0.22, hFrac: 0.20),
        MuscleRegion(group: .calves, shape: .capsule, xFrac: 0.34, yFrac: 0.88, wFrac: 0.17, hFrac: 0.16),
        MuscleRegion(group: .calves, shape: .capsule, xFrac: 0.66, yFrac: 0.88, wFrac: 0.17, hFrac: 0.16),
    ]
}

#Preview {
    VStack(spacing: 20) {
        MTCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("MUSCLES ACTIVATED")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(MTTheme.textTertiary)
                MuscleMapView(highlighted: [.chest, .arms, .core])
            }
        }
        MTCard {
            MuscleMapView(highlighted: [.glutes, .hamstrings, .calves])
        }
    }
    .padding(20)
    .background(MTTheme.bg)
}
