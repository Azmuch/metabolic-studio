import SwiftUI
import MetabolicCore

// MARK: - MTCard

/// Surface card: radius 24, 1px stroke, 20pt internal padding.
/// Background adapts to `ThemeStore.shared.backgroundStyle`: classic/tinted keep the
/// opaque themed surface; glass/photo go translucent so the backdrop shows through,
/// preferring the system Liquid Glass treatment on iOS 26+.
struct MTCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private var translucent: Bool {
        switch ThemeStore.shared.backgroundStyle {
        case .classic, .tinted: return false
        case .glass, .photo: return true
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous)
        Group {
            if translucent {
                if #available(iOS 26.0, *) {
                    content
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .glassEffect(.regular, in: shape)
                        .overlay(shape.stroke(MTTheme.stroke, lineWidth: 1))
                } else {
                    content
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial, in: shape)
                        .overlay(shape.stroke(MTTheme.stroke, lineWidth: 1))
                }
            } else {
                content
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(MTTheme.surface, in: shape)
                    .overlay(shape.stroke(MTTheme.stroke, lineWidth: 1))
            }
        }
    }
}

// MARK: - MTRing

/// Animated circular progress ring — rounded caps, 12pt default line width, track at 12% tint.
/// Animates from 0 on first appearance.
struct MTRing: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var tint: Color = MTTheme.volt

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.05)) {
                animatedProgress = clamp(progress)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                animatedProgress = clamp(newValue)
            }
        }
    }

    private func clamp(_ value: Double) -> Double { min(max(value, 0), 1) }
}

// MARK: - MTHeroScrim

/// Light accent-tinted wash laid behind content at the bottom of a hero canvas — shared by the
/// exercise detail card and the session player so both screens read as the same surface. Apply
/// as the `.background` of the bottom content block (with generous top padding so the wash fades
/// in above the text); fixed dark-ink foreground stays legible in both appearances.
struct MTHeroScrim: View {
    var body: some View {
        LinearGradient(
            colors: [.clear, MTTheme.heroScrimLight.opacity(0.66), MTTheme.heroScrimLight.opacity(0.96)],
            startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - MTChip

struct MTChip: View {
    var text: String
    var systemImage: String? = nil
    var isActive: Bool = false

    /// Inactive chips go translucent under glass/photo so they read as glass, not flat gray blocks.
    private var translucent: Bool {
        switch ThemeStore.shared.backgroundStyle {
        case .classic, .tinted: return false
        case .glass, .photo: return true
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(isActive ? Color.black : MTTheme.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(chipBackground)
    }

    @ViewBuilder
    private var chipBackground: some View {
        let shape = Capsule()
        if isActive {
            shape.fill(MTTheme.volt)
        } else if translucent {
            shape.fill(.ultraThinMaterial)
                .overlay(shape.stroke(MTTheme.stroke, lineWidth: 0.5))
        } else {
            shape.fill(MTTheme.surface2)
        }
    }
}

// MARK: - MTPrimaryButton

struct MTPrimaryButton: View {
    var title: String
    var systemImage: String? = nil
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button {
            guard isEnabled else { return }
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(isEnabled ? Color.black : MTTheme.textTertiary)
            .background(isEnabled ? MTTheme.volt : MTTheme.surface2)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - MTSecondaryButton

struct MTSecondaryButton: View {
    var title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(MTTheme.textPrimary)
            .background(MTTheme.surface2)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MTProgressBar

/// 6pt capsule track + fill, animates from 0 on first appearance.
struct MTProgressBar: View {
    var progress: Double
    var tint: Color = MTTheme.volt

    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(tint.opacity(0.12))
                Capsule()
                    .fill(tint)
                    .frame(width: geo.size.width * clamp(animatedProgress))
            }
        }
        .frame(height: 6)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.05)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }

    private func clamp(_ value: Double) -> Double { min(max(value, 0), 1) }
}

// MARK: - MTEmptyState

struct MTEmptyState: View {
    var symbol: String
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(MTTheme.voltDim).frame(width: 64, height: 64)
                Image(systemName: symbol)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(MTTheme.volt)
            }
            Text(title)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(MTTheme.textPrimary)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(MTTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - MTSheetHeader

/// Grabber-style sheet title row.
struct MTSheetHeader: View {
    var title: String

    var body: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(MTTheme.stroke)
                .frame(width: 36, height: 5)
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(MTTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

// MARK: - ScoreBadge

/// Colored pill showing a 0-100 score alongside its rating label.
/// excellent = success, good = 0xA3D65C, poor = warning, bad = danger.
struct ScoreBadge: View {
    var score: Int
    var rating: ScoreRating

    private var color: Color {
        switch rating {
        case .excellent: return MTTheme.success
        case .good: return Color(hex: 0xA3D65C)
        case .poor: return MTTheme.warning
        case .bad: return MTTheme.danger
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("\(score)")
                .font(MTTheme.numberFont(size: 15))
            Text(rating.displayName)
                .font(.system(size: 12, weight: .semibold))
                .textCase(.uppercase)
        }
        .foregroundStyle(Color.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color)
        .clipShape(Capsule())
    }
}

fileprivate extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

#Preview("Components") {
    VStack(spacing: 16) {
        MTCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("MTCard").foregroundStyle(MTTheme.textPrimary)
                HStack(spacing: 12) {
                    MTChip(text: "Chip", systemImage: "star.fill")
                    MTChip(text: "Active", isActive: true)
                }
                MTProgressBar(progress: 0.62, tint: MTTheme.protein)
                HStack {
                    MTRing(progress: 0.72).frame(width: 64, height: 64)
                    ScoreBadge(score: 71, rating: .good)
                }
            }
        }
        MTPrimaryButton(title: "Primary", systemImage: "bolt.fill") {}
        MTSecondaryButton(title: "Secondary") {}
        MTEmptyState(symbol: "lock.fill", title: "Locked", message: "Unlock with Plus.")
    }
    .padding(20)
    .background(MTTheme.bg)
}
