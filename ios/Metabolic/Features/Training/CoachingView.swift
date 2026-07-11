import SwiftUI
import AVKit
import MetabolicCore

/// On-demand / Live coaching hub, pushed from `TrainingView`'s "Coaching" card.
/// On-demand streams a shared sample HLS asset in a full-screen `VideoPlayer`; Live is gated at
/// the Pro tier and otherwise shows an empty state ("no sessions scheduled yet").
struct CoachingView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var segment: Segment = .onDemand
    @State private var playingSession: CoachingSession?
    @State private var showPaywall = false
    @State private var notifyRequested = false

    fileprivate enum Segment: String, CaseIterable {
        case onDemand = "On-demand"
        case live = "Live"
    }

    fileprivate struct CoachingSession: Identifiable {
        let id = UUID()
        let title: String
        let focus: String
        let minutes: Int
        let difficulty: String
    }

    fileprivate static let sampleStreamURL = URL(
        string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
    )!

    private static let sessions: [CoachingSession] = [
        CoachingSession(title: "Full-Body Foundations", focus: "Full Body", minutes: 28, difficulty: "Beginner"),
        CoachingSession(title: "Mobility Reset", focus: "Mobility", minutes: 15, difficulty: "All Levels"),
        CoachingSession(title: "Upper Push Power", focus: "Push", minutes: 32, difficulty: "Intermediate"),
        CoachingSession(title: "Core Control", focus: "Core", minutes: 18, difficulty: "Beginner"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Sessions with real trainers")
                    .font(.system(size: 14))
                    .foregroundStyle(MTTheme.textSecondary)

                Picker("", selection: $segment) {
                    ForEach(Segment.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)

                if segment == .onDemand {
                    onDemandSection
                } else {
                    liveSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(MTTheme.bg)
        .navigationTitle("Coaching")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $playingSession) { session in
            CoachingPlayerView(session: session)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - On-demand

    private var onDemandSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PRERECORDED SESSIONS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(MTTheme.textTertiary)

            VStack(spacing: 12) {
                ForEach(Self.sessions) { session in
                    Button {
                        Haptics.tap()
                        playingSession = session
                    } label: {
                        sessionCard(session)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sessionCard(_ session: CoachingSession) -> some View {
        MTCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: MTTheme.controlRadius, style: .continuous)
                        .fill(MTTheme.voltDim)
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(MTTheme.volt)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 6) {
                    Text(session.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MTTheme.textPrimary)
                    Text("\(session.focus) · \(session.minutes) min")
                        .font(.system(size: 13))
                        .foregroundStyle(MTTheme.textSecondary)
                    MTChip(text: session.difficulty)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MTTheme.textTertiary)
            }
        }
    }

    // MARK: - Live

    private var liveSection: some View {
        Group {
            if subscriptionManager.tier >= .pro {
                liveScheduledEmptyState
            } else {
                lockedLiveState
            }
        }
    }

    private var lockedLiveState: some View {
        VStack(spacing: 16) {
            MTEmptyState(
                symbol: "lock.fill",
                title: "Live sessions are Pro",
                message: "Upgrade to Pro to join live, trainer-led sessions from your gym."
            )
            Button {
                Haptics.tap()
                showPaywall = true
            } label: {
                MTChip(text: "Pro", systemImage: "lock.fill")
            }
            .buttonStyle(.plain)
            MTPrimaryButton(title: "Unlock Live Sessions", systemImage: "lock.open.fill") {
                showPaywall = true
            }
        }
    }

    private var liveScheduledEmptyState: some View {
        VStack(spacing: 16) {
            MTEmptyState(
                symbol: "dot.radiowaves.left.and.right",
                title: "No live sessions scheduled",
                message: "Your gym's live trainer schedule will appear here."
            )
            MTSecondaryButton(
                title: notifyRequested ? "You're on the list ✓" : "Notify me",
                systemImage: notifyRequested ? "checkmark" : "bell.fill"
            ) {
                guard !notifyRequested else { return }
                Haptics.success()
                notifyRequested = true
            }
        }
    }
}

/// Full-screen sample playback for an on-demand session. All four sessions currently share
/// Apple's public HLS test stream — swap in real per-session URLs when the studio's content lands.
private struct CoachingPlayerView: View {
    let session: CoachingView.CoachingSession

    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            VideoPlayer(player: player)
                .ignoresSafeArea()
                .onAppear {
                    let p = AVPlayer(url: CoachingView.sampleStreamURL)
                    player = p
                    p.play()
                }
                .onDisappear {
                    player?.pause()
                }

            VStack {
                HStack {
                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text(session.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                }
                Spacer()
                Text("Sample stream — replace with your studio's content")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.bottom, 24)
            }
            .padding(20)
        }
    }
}

#Preview {
    NavigationStack {
        CoachingView()
            .environment(SubscriptionManager())
    }
}
