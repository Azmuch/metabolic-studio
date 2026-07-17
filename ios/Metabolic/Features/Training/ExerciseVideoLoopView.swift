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

/// `AVPlayerLayer`-backed view rendering the loop with no controls. Default is aspect-*fit* so
/// the full head-to-feet figure is always visible in card-shaped containers. The full-screen
/// session backdrop passes `.resizeAspectFill` instead: the screen is taller than the 9:16 clip,
/// so fill matches the height exactly (head/feet stay intact, only studio background is cropped
/// from the sides) and removes the letterbox band above the video.
struct ExerciseVideoLoopView: UIViewRepresentable {
    let player: AVQueuePlayer
    var gravity: AVLayerVideoGravity = .resizeAspect

    func makeUIView(context: Context) -> PlayerContainer { PlayerContainer(player: player, gravity: gravity) }

    func updateUIView(_ view: PlayerContainer, context: Context) {
        view.setPlayer(player)
        view.setGravity(gravity)
    }

    final class PlayerContainer: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        init(player: AVQueuePlayer, gravity: AVLayerVideoGravity) {
            super.init(frame: .zero)
            playerLayer.player = player
            playerLayer.videoGravity = gravity
            backgroundColor = .clear
        }

        func setPlayer(_ player: AVQueuePlayer) {
            if playerLayer.player !== player { playerLayer.player = player }
        }

        func setGravity(_ gravity: AVLayerVideoGravity) {
            if playerLayer.videoGravity != gravity { playerLayer.videoGravity = gravity }
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
    /// Fill the container (crop the clip's studio sides) instead of letterboxing — used by the
    /// full-screen session backdrop, whose aspect is taller than the clip's 9:16.
    var fillsContainer: Bool = false
    /// Inset between the video and the card edge. 0 = edge-to-edge fill (used by the detail hero).
    var contentInset: CGFloat = 10
    /// Card corner radius. 0 = square (full-screen player background).
    var cornerRadius: CGFloat = MTTheme.cardRadius

    @StateObject private var player = LoopPlayer()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 0.965, green: 0.965, blue: 0.957))

            ExerciseVideoLoopView(player: player.queue,
                                  gravity: fillsContainer ? .resizeAspectFill : .resizeAspect)
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
