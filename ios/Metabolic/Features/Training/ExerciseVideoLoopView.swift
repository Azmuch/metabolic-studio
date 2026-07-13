import SwiftUI
import AVFoundation
import Combine

/// Owns an `AVQueuePlayer` + `AVPlayerLooper` for a single clip, giving a genuinely gapless
/// loop. (Seeking to zero on `AVPlayerItemDidPlayToEndTime` visibly stutters at the seam; the
/// looper double-buffers the item instead.) Muted, no transport controls.
@MainActor
final class LoopPlayer: ObservableObject {
    let queue = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    private var loadedURL: URL?

    func load(url: URL) {
        guard url != loadedURL else { return }
        loadedURL = url
        queue.removeAllItems()
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: queue, templateItem: item)
        queue.isMuted = true
        queue.actionAtItemEnd = .advance
    }

    func play() { queue.play() }
    func pause() { queue.pause() }
}

/// `AVPlayerLayer`-backed view rendering the loop with no controls. Aspect-*fit* so the full
/// head-to-feet figure is always visible: the hero containers are square/landscape, not 9:16,
/// and a fill would crop the head and feet. The clip's white studio background merges with the
/// card, so the fit shows no visible letterbox.
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

    @StateObject private var player = LoopPlayer()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous)
                .fill(Color(red: 0.965, green: 0.965, blue: 0.957))

            ExerciseVideoLoopView(player: player.queue)
                .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MTTheme.cardRadius, style: .continuous)
                .stroke(MTTheme.stroke, lineWidth: 1))
        .onAppear {
            player.load(url: url)
            if isPlaying { player.play() }
        }
        .onChange(of: url) { _, newURL in
            player.load(url: newURL)
            if isPlaying { player.play() } else { player.pause() }
        }
        .onChange(of: isPlaying) { _, playing in
            if playing { player.play() } else { player.pause() }
        }
        .onDisappear { player.pause() }
    }
}
