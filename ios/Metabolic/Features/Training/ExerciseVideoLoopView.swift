import SwiftUI
import AVFoundation
import Combine

/// Owns an `AVQueuePlayer` for a single clip in one of two modes:
///   - `.loop`: paired with an `AVPlayerLooper` for a genuinely gapless loop. (Seeking to zero on
///     `AVPlayerItemDidPlayToEndTime` visibly stutters at the seam; the looper double-buffers the
///     item instead.)
///   - `.hold`: no looper, `actionAtItemEnd = .pause` — the clip plays its entry once and freezes
///     on the final frame (the held position), which is exactly the isometric-hold behavior.
/// Muted, no transport controls.
@MainActor
final class LoopPlayer: ObservableObject {
    let queue = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    private var loadedURL: URL?
    private var loadedMode: ClipPlayback = .loop

    func load(url: URL, mode: ClipPlayback) {
        guard url != loadedURL || mode != loadedMode else { return }
        loadedURL = url
        loadedMode = mode
        looper = nil
        queue.removeAllItems()
        queue.isMuted = true
        let item = AVPlayerItem(url: url)
        switch mode {
        case .loop:
            looper = AVPlayerLooper(player: queue, templateItem: item)
            queue.actionAtItemEnd = .advance
        case .hold:
            queue.insert(item, after: nil)
            queue.actionAtItemEnd = .pause   // freeze on the held frame after the entry
        }
    }

    func play() { queue.play() }
    func pause() { queue.pause() }
}

/// `AVPlayerLayer`-backed view rendering the loop with no controls. Always aspect-*fit* so the
/// full head-to-feet figure is visible — fill crops the figure on horizontal poses (plank toes).
/// Containers that must avoid letterboxing should instead frame themselves to the clip's 9:16
/// (the session player pins a 9:16 card to the top of the screen).
struct ExerciseVideoLoopView: UIViewRepresentable {
    let player: AVQueuePlayer

    func makeUIView(context: Context) -> PlayerContainer { PlayerContainer(player: player) }

    func updateUIView(_ view: PlayerContainer, context: Context) {
        view.setPlayer(player)
    }

    final class PlayerContainer: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        init(player: AVQueuePlayer) {
            super.init(frame: .zero)
            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspect
            backgroundColor = .clear
        }

        func setPlayer(_ player: AVQueuePlayer) {
            if playerLayer.player !== player { playerLayer.player = player }
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}

/// SwiftUI hero wrapper: loads `url`, plays/pauses from `isPlaying`, on the same fixed light
/// card as the still hero. The green prime-mover highlight is baked into the clip pixels — no
/// runtime tinting (unlike the still hero's accent hue-shift).
struct ExerciseClipHero: View {
    let url: URL
    var isPlaying: Bool = true
    /// Loop (rep) vs hold (play entry, freeze on the held frame). Drives the `LoopPlayer` mode.
    var playback: ClipPlayback = .loop
    /// Inset between the video and the card edge. 0 = edge-to-edge fill (used by the detail hero).
    var contentInset: CGFloat = 10
    /// Card corner radius. 0 = square (full-screen player background).
    var cornerRadius: CGFloat = MTTheme.cardRadius

    @StateObject private var player = LoopPlayer()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 0.965, green: 0.965, blue: 0.957))

            ExerciseVideoLoopView(player: player.queue)
                .padding(contentInset)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(MTTheme.stroke, lineWidth: contentInset > 0 ? 1 : 0))
        .onAppear {
            player.load(url: url, mode: playback)
            if isPlaying { player.play() }
        }
        .onChange(of: url) { _, newURL in
            player.load(url: newURL, mode: playback)
            if isPlaying { player.play() } else { player.pause() }
        }
        .onChange(of: isPlaying) { _, playing in
            if playing { player.play() } else { player.pause() }
        }
        .onDisappear { player.pause() }
    }
}
